import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;
import '../services/socket_service.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final SocketService? socket;
  const ChatScreen({super.key, this.socket});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final Set<String> _pendingReadIds = {}; // batched ids to send
  Timer? _readDebounceTimer;
  final api = ApiService();
  bool _loading = true;
  String? _myUserId;
  String? _myRole;
  bool _canSend = false;
  bool _nearBottom = true;
  bool _someoneTyping = false;
  Timer? _typingDebounce;
  Timer? _typingHideTimer;
  final Map<String, Map<String, dynamic>> _userCache = {};

  @override
  void initState() {
    super.initState();
    _loadMe();
    _loadHistory();
    _controller.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);
    widget.socket?.socket?.on('chat:new_message', (data) {
      if (mounted) {
        final parsed = Map<String, dynamic>.from(data);
        // ensure readBy comes as list of strings
        parsed['readBy'] =
            (parsed['readBy'] ?? []).map((r) => r.toString()).toList();
        setState(() => _messages.add(parsed));
        _scrollToBottom();
        // Queue new message for marking as read (batched/debounced)
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _markMessagesRead([parsed['_id']]));
      }
    });
    // Optional typing indicator support if backend emits this event
    widget.socket?.socket?.on('chat:typing', (_) {
      if (!mounted) return;
      setState(() => _someoneTyping = true);
      _typingHideTimer?.cancel();
      _typingHideTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _someoneTyping = false);
      });
    });
    widget.socket?.socket?.on('chat:stop_typing', (_) {
      if (!mounted) return;
      _typingHideTimer?.cancel();
      setState(() => _someoneTyping = false);
    });

    widget.socket?.socket?.on('chat:message_read', (data) {
      if (!mounted) return;
      final messageId = data['messageId']?.toString();
      final userId = data['userId']?.toString();
      if (messageId == null || userId == null) return;
      final idx = _messages.indexWhere((m) => m['_id'] == messageId);
      if (idx >= 0) {
        final m = Map<String, dynamic>.from(_messages[idx]);
        final readBy =
            ((m['readBy'] ?? []) as Iterable).map((r) => r.toString()).toList();
        if (!readBy.contains(userId)) readBy.add(userId);
        m['readBy'] = readBy;
        setState(() => _messages[idx] = m);
      }
    });

    // Listen for reaction updates
    widget.socket?.socket?.on('chat:reaction_updated', (data) {
      if (!mounted) return;
      final messageId = data['messageId']?.toString();
      if (messageId == null) return;
      final idx = _messages.indexWhere((m) => m['_id'] == messageId);
      if (idx >= 0) {
        final m = Map<String, dynamic>.from(_messages[idx]);
        m['reactions'] = data['reactions'];
        setState(() => _messages[idx] = m);
      }
    });

    widget.socket?.socket?.on('alert:new', (data) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
                child: Text('🚨 Emergency Alert Received!',
                    style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ));
    });
  }

  Future<void> _markMessagesRead(List<String> messageIds) async {
    if (messageIds.isEmpty) return;
    // Add to pending set and debounce the network emit so multiple visible
    // messages are sent together instead of one-by-one.
    for (final id in messageIds) {
      _pendingReadIds.add(id);
    }

    // debounce / coalesce
    _readDebounceTimer?.cancel();
    _readDebounceTimer = Timer(const Duration(milliseconds: 800), () async {
      await _flushPendingReadIds();
    });
  }

  Future<void> _flushPendingReadIds() async {
    if (_pendingReadIds.isEmpty) return;
    final ids = _pendingReadIds.toList();
    _pendingReadIds.clear();
    try {
      widget.socket?.socket?.emit('chat:read', {
        'roomId': 'community',
        'messageIds': ids,
      });
      print('📣 Flushed read receipts: ${ids.length} messages');
    } catch (e) {
      print('❌ Failed to flush read receipts: $e');
      // on failure, re-queue the ids for retry
      _pendingReadIds.addAll(ids);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _scrollController.removeListener(_onScroll);
    _controller.dispose();
    _scrollController.dispose();
    _typingDebounce?.cancel();
    _typingHideTimer?.cancel();
    _readDebounceTimer?.cancel();
    // try to flush any pending read receipts before dispose
    _flushPendingReadIds();
    super.dispose();
  }

  Future<void> _loadMe() async {
    try {
      final res = await api.dio.get('/api/auth/me');
      setState(() {
        _myUserId = res.data['user']?['_id']?.toString();
        _myRole = res.data['user']?['role']?.toString();
      });
      print('👤 My User ID: $_myUserId, Role: $_myRole');
    } catch (e) {
      print('❌ Failed to load user ID: $e');
    }
  }

  Future<Map<String, dynamic>?> _fetchUser(String userId) async {
    // First check cache
    if (_userCache.containsKey(userId)) return _userCache[userId];

    // Try to find user info from existing messages
    for (final msg in _messages) {
      final senderId = msg['senderId']?.toString();
      if (senderId == userId) {
        final userData = {
          '_id': userId,
          'name': msg['senderName'],
          'userName': msg['senderName'],
          'email': msg['senderEmail'],
          'profilePicture': msg['senderProfilePicture'],
        };
        _userCache[userId] = userData;
        print('✅ Got user from message: ${userData['name']}');
        return userData;
      }
    }

    // If not found in messages, try API (will likely fail with 403)
    try {
      // Try single user endpoint
      try {
        final r = await api.dio.get('/api/users/$userId');
        if (r.data is Map) {
          final map = Map<String, dynamic>.from(r.data);
          print(
              '✅ Fetched user from API: ${map['name'] ?? map['userName'] ?? map['email']}');
          _userCache[userId] = map;
          return map;
        } else if (r.data != null && r.data['user'] is Map) {
          final map = Map<String, dynamic>.from(r.data['user']);
          print(
              '✅ Fetched user from API (wrapped): ${map['name'] ?? map['userName'] ?? map['email']}');
          _userCache[userId] = map;
          return map;
        }
      } catch (e) {
        // 403 or other error - expected
        print('⚠️ API fetch failed (expected): ${e.toString().split('\n')[0]}');
      }
    } catch (e) {
      print('⚠️ User fetch error: $e');
    }

    // Last resort: return minimal user data
    return {
      '_id': userId,
      'name': 'Community Member',
      'userName': 'User',
    };
  }

  Future<void> _loadHistory() async {
    try {
      print('📱 Loading chat history...');
      final res = await api.dio.get('/api/chat/history/community');
      print('📱 Chat history response: ${res.data}');
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(
              (res.data as List).map((e) => Map<String, dynamic>.from(e)));
          _loading = false;
        });
        print('📱 Loaded ${_messages.length} messages');
        _scrollToBottom();
      }
    } catch (e) {
      print('📱 Chat history error: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        setState(() => _nearBottom = true);
        // After scrolling to bottom we should queue recent visible messages
        // to be marked as read (batched). This keeps read receipts accurate
        // while avoiding per-message network chatter.
        _queueVisibleMessagesForRead();
      }
    });
  }

  // Queue a sensible window of recent messages for marking as read.
  // We pick the last N messages that are not authored by me and that
  // don't yet include my id in their readBy arrays.
  void _queueVisibleMessagesForRead({int window = 20}) {
    if (_myUserId == null) return;
    final ids = <String>[];
    for (int i = _messages.length - 1; i >= 0 && ids.length < window; i--) {
      final m = _messages[i];
      final senderId = m['senderId']?.toString();
      if (senderId == _myUserId) continue; // ignore messages I sent
      final readBy =
          ((m['readBy'] ?? []) as Iterable).map((r) => r.toString()).toList();
      if (readBy.contains(_myUserId)) continue; // already read
      final id = m['_id']?.toString();
      if (id != null) ids.add(id);
    }
    if (ids.isNotEmpty) _markMessagesRead(ids);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    final atBottom = (max - offset) < 80; // within 80px of bottom
    if (atBottom != _nearBottom && mounted) {
      setState(() => _nearBottom = atBottom);
    }
  }

  void _onTextChanged() {
    final text = _controller.text.trim();
    final canSend = text.isNotEmpty;
    if (canSend != _canSend && mounted) {
      setState(() => _canSend = canSend);
    }
    // Emit typing event (debounced)
    _typingDebounce?.cancel();
    if (text.isNotEmpty) {
      // notify typing started
      widget.socket?.socket?.emit('chat:typing', {'roomId': 'community'});
      _typingDebounce = Timer(const Duration(seconds: 2), () {
        widget.socket?.socket
            ?.emit('chat:stop_typing', {'roomId': 'community'});
      });
    } else {
      // if cleared, stop typing immediately
      widget.socket?.socket?.emit('chat:stop_typing', {'roomId': 'community'});
    }
  }

  DateTime? _parseDate(dynamic value) {
    try {
      if (value == null) return null;
      if (value is int) {
        // assume ms-since-epoch if large, else seconds
        return DateTime.fromMillisecondsSinceEpoch(
                value > 2000000000 ? value : value * 1000,
                isUtc: true)
            .toLocal();
      }
      if (value is String) {
        return DateTime.tryParse(value)?.toLocal();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  bool _isDifferentDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year != b.year || a.month != b.month || a.day != b.day;
  }

  String _formatHeader(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    if (that == today) return 'Today';
    if (that == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${_monthName(d.month)} ${d.day}, ${d.year}';
  }

  String _formatTime(DateTime d) {
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final min = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $ampm';
  }

  String _monthName(int m) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return names[(m - 1).clamp(0, 11)];
  }

  String _resolveUrl(String maybeRelative) {
    final base = api.dio.options.baseUrl;
    if (maybeRelative.startsWith('http')) return maybeRelative;
    if (base.endsWith('/') && maybeRelative.startsWith('/')) {
      return base.substring(0, base.length - 1) + maybeRelative;
    }
    if (!base.endsWith('/') && !maybeRelative.startsWith('/')) {
      return '$base/$maybeRelative';
    }
    return '$base$maybeRelative';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No messages yet',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text('Start the conversation!',
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: _loadHistory,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) {
                            final m = _messages[i];
                            final msgSenderId = m['senderId']?.toString();
                            final isMe =
                                _myUserId != null && (msgSenderId == _myUserId);

                            // Debug log for first few messages
                            if (i < 3) {
                              print(
                                  '💬 Message $i: senderId=$msgSenderId, myId=$_myUserId, isMe=$isMe');
                            }

                            final bubbleColor = isMe
                                ? Theme.of(context).primaryColor
                                : Colors.grey[200];
                            final textColor =
                                isMe ? Colors.white : Colors.black87;
                            final imageUrl = m['imageUrl']?.toString();
                            final radius = BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            );

                            final createdAt =
                                _parseDate(m['createdAt'] ?? m['timestamp']);
                            final prevCreatedAt = i > 0
                                ? _parseDate(_messages[i - 1]['createdAt'] ??
                                    _messages[i - 1]['timestamp'])
                                : null;
                            final showHeader = i == 0 ||
                                _isDifferentDay(prevCreatedAt, createdAt);

                            return Column(
                              children: [
                                if (showHeader && createdAt != null)
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        _formatHeader(createdAt),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87),
                                      ),
                                    ),
                                  ),
                                Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: isMe
                                        ? MainAxisAlignment.end
                                        : MainAxisAlignment.start,
                                    children: [
                                      if (!isMe) ...[
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.blue,
                                          backgroundImage:
                                              m['senderProfilePicture'] != null
                                                  ? MemoryImage(base64Decode(
                                                      m['senderProfilePicture']
                                                          .split(',')[1]))
                                                  : null,
                                          child: m['senderProfilePicture'] ==
                                                  null
                                              ? Text(
                                                  (m['senderName'] ?? 'U')[0]
                                                      .toString()
                                                      .toUpperCase(),
                                                  style: const TextStyle(
                                                      color: Colors.white))
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Flexible(
                                        child: Column(
                                          crossAxisAlignment: isMe
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 2),
                                              child: Text(
                                                m['senderName'] ?? 'User',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                    color: Colors.grey[600]),
                                              ),
                                            ),
                                            GestureDetector(
                                              onLongPress: () async {
                                                // Show reaction/action menu
                                                await _showMessageActions(
                                                    m, isMe);
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 10),
                                                constraints:
                                                    const BoxConstraints(
                                                        maxWidth: 300),
                                                decoration: BoxDecoration(
                                                  color: bubbleColor,
                                                  borderRadius: radius,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: isMe
                                                      ? CrossAxisAlignment.end
                                                      : CrossAxisAlignment
                                                          .start,
                                                  children: [
                                                    if (imageUrl != null &&
                                                        imageUrl.isNotEmpty)
                                                      ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        child: Image.network(
                                                          imageUrl.startsWith(
                                                                  'http')
                                                              ? imageUrl
                                                              : _resolveUrl(
                                                                  imageUrl),
                                                          fit: BoxFit.cover,
                                                          loadingBuilder:
                                                              (context, child,
                                                                  progress) {
                                                            if (progress ==
                                                                null)
                                                              return child;
                                                            return SizedBox(
                                                              width: 220,
                                                              height: 160,
                                                              child: Center(
                                                                child:
                                                                    CircularProgressIndicator(
                                                                  value: progress
                                                                              .expectedTotalBytes !=
                                                                          null
                                                                      ? progress
                                                                              .cumulativeBytesLoaded /
                                                                          (progress.expectedTotalBytes ??
                                                                              1)
                                                                      : null,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          errorBuilder:
                                                              (_, __, ___) =>
                                                                  Container(
                                                            width: 220,
                                                            height: 160,
                                                            color:
                                                                Colors.black12,
                                                            alignment: Alignment
                                                                .center,
                                                            child: const Icon(Icons
                                                                .broken_image),
                                                          ),
                                                        ),
                                                      ),
                                                    if ((m['text'] ?? '')
                                                        .toString()
                                                        .isNotEmpty)
                                                      Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                top: imageUrl !=
                                                                        null
                                                                    ? 8
                                                                    : 0),
                                                        child: Text(
                                                          m['text'] ?? '',
                                                          style: TextStyle(
                                                              fontSize: 15,
                                                              color: textColor),
                                                        ),
                                                      ),
                                                    if (createdAt != null)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 4),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              _formatTime(
                                                                  createdAt),
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                color: isMe
                                                                    ? Colors
                                                                        .white70
                                                                    : Colors
                                                                        .black54,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 6),
                                                            // If this message is mine, show read ticks / avatars
                                                            if (isMe)
                                                              _buildReadIndicator(
                                                                  m),
                                                          ],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            // long-press to show 'Seen by' list for messages I've sent
                                            if (isMe)
                                              // long-press is handled on the bubble GestureDetector above
                                              if (isMe || _myRole == 'admin')
                                                Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: IconButton(
                                                    icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                        size: 16),
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(),
                                                    onPressed: () async {
                                                      final confirm =
                                                          await showDialog<
                                                              bool>(
                                                        context: context,
                                                        builder: (context) =>
                                                            AlertDialog(
                                                          title: const Text(
                                                              'Delete Message'),
                                                          content: const Text(
                                                              'Are you sure you want to delete this message?'),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context,
                                                                      false),
                                                              child: const Text(
                                                                  'Cancel'),
                                                            ),
                                                            FilledButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context,
                                                                      true),
                                                              style: FilledButton
                                                                  .styleFrom(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .red),
                                                              child: const Text(
                                                                  'Delete'),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                      if (confirm == true &&
                                                          mounted) {
                                                        try {
                                                          await api.dio.delete(
                                                              '/api/chat/message/${m['_id']}');
                                                          setState(() {
                                                            _messages
                                                                .removeAt(i);
                                                          });
                                                          if (mounted) {
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                    'Message deleted'),
                                                                backgroundColor:
                                                                    Colors
                                                                        .green,
                                                              ),
                                                            );
                                                          }
                                                        } catch (e) {
                                                          if (mounted) {
                                                            final errorMsg = e
                                                                    .toString()
                                                                    .contains(
                                                                        '403')
                                                                ? 'You can only delete your own messages'
                                                                : 'Failed to delete message';
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                    errorMsg),
                                                                backgroundColor:
                                                                    Colors
                                                                        .orange,
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      }
                                                    },
                                                  ),
                                                ),
                                          ],
                                        ),
                                      ),
                                      // Display reactions if any
                                      if (m['reactions'] != null &&
                                          (m['reactions'] as Map).isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Wrap(
                                            spacing: 4,
                                            children: (m['reactions'] as Map)
                                                .entries
                                                .map((entry) {
                                              final emoji = entry.key;
                                              final users = entry.value as List;
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: users
                                                            .contains(_myUserId)
                                                        ? Colors.blue
                                                        : Colors.transparent,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(emoji,
                                                        style: const TextStyle(
                                                            fontSize: 14)),
                                                    const SizedBox(width: 2),
                                                    Text('${users.length}',
                                                        style: const TextStyle(
                                                            fontSize: 11)),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      // Scroll-to-bottom button
                      if (!_nearBottom)
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: FloatingActionButton.small(
                            heroTag: 'scroll_bottom',
                            onPressed: _scrollToBottom,
                            child: const Icon(Icons.arrow_downward),
                          ),
                        ),
                    ],
                  ),
          ),
          if (_someoneTyping)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 8),
                  const Text('Someone is typing...',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, -2))
              ],
            ),
            child: Row(
              children: [
                // Attach image
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.grey),
                  onPressed: _pickAndSendImage,
                  tooltip: 'Send image',
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.send, size: 20),
                    onPressed: !_canSend
                        ? null
                        : () {
                            final text = _controller.text.trim();
                            if (text.isEmpty) return;
                            print('📱 Sending message: $text');
                            print(
                                '📱 Socket connected: ${widget.socket?.socket?.connected}');
                            widget.socket?.socket?.emit('chat:message', {
                              'roomId': 'community',
                              'text': text,
                            });
                            _controller.clear();
                            widget.socket?.socket?.emit(
                                'chat:stop_typing', {'roomId': 'community'});
                            print('📱 Message sent via socket');
                          },
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _pickAndSendImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85);
      if (picked == null) return;

      final fileName = picked.name;
      final form = dio.FormData.fromMap({
        'image':
            await dio.MultipartFile.fromFile(picked.path, filename: fileName),
      });
      final resp = await api.dio.post('/api/chat/upload',
          data: form, options: dio.Options(contentType: 'multipart/form-data'));
      final url = (resp.data['url'] ?? resp.data['path'])?.toString();
      if (url == null) throw Exception('Invalid upload response');

      widget.socket?.socket?.emit('chat:message', {
        'roomId': 'community',
        'imageUrl': url,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send image: $e')),
      );
    }
  }

  Future<void> _showMessageActions(
      Map<String, dynamic> message, bool isMe) async {
    final messageId = message['_id']?.toString();
    if (messageId == null) return;

    await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji reactions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildEmojiButton('👍', messageId),
                  _buildEmojiButton('❤️', messageId),
                  _buildEmojiButton('😂', messageId),
                  _buildEmojiButton('😮', messageId),
                  _buildEmojiButton('😢', messageId),
                  _buildEmojiButton('🔥', messageId),
                ],
              ),
            ),
            const Divider(),
            // Action buttons
            if (isMe)
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('Seen by'),
                onTap: () {
                  Navigator.pop(context);
                  _showSeenByDialog(message);
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy text'),
              onTap: () async {
                final text = (message['text'] ?? '').toString();
                if (text.isNotEmpty) {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message copied'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiButton(String emoji, String messageId) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _toggleReaction(messageId, emoji);
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
        ),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }

  Future<void> _toggleReaction(String messageId, String emoji) async {
    // For now, reactions are frontend-only since backend endpoint doesn't exist yet
    // Find the message and update reactions locally
    final idx = _messages.indexWhere((m) => m['_id'] == messageId);
    if (idx < 0) return;

    final message = Map<String, dynamic>.from(_messages[idx]);
    final reactions = Map<String, dynamic>.from(message['reactions'] ?? {});

    // Get list of users who reacted with this emoji
    List<dynamic> users = List<dynamic>.from(reactions[emoji] ?? []);

    if (users.contains(_myUserId)) {
      // Remove my reaction
      users.remove(_myUserId);
      if (users.isEmpty) {
        reactions.remove(emoji);
      } else {
        reactions[emoji] = users;
      }
    } else {
      // Add my reaction
      users.add(_myUserId);
      reactions[emoji] = users;
    }

    message['reactions'] = reactions;
    setState(() => _messages[idx] = message);

    // Try to send to backend (will fail gracefully if endpoint doesn't exist)
    try {
      await api.dio.post('/api/chat/message/$messageId/react', data: {
        'emoji': emoji,
      });
    } catch (e) {
      // Silently ignore if backend doesn't support reactions yet
      print('⚠️ Backend reaction endpoint not available (expected)');
    }
  }

  Future<void> _showSeenByDialog(Map<String, dynamic> message) async {
    final readBy = ((message['readBy'] ?? []) as Iterable)
        .map((r) => r.toString())
        .toList();
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seen by'),
        content: SizedBox(
          width: 300,
          child: readBy.isEmpty
              ? const Text('No one has seen this yet')
              : FutureBuilder<List<Map<String, dynamic>?>>(
                  future: Future.wait(readBy.map((id) => _fetchUser(id))),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting)
                      return const SizedBox(
                          height: 80,
                          child: Center(child: CircularProgressIndicator()));
                    final users = snap.data ?? [];
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: users.length,
                      itemBuilder: (c, idx) {
                        final u = users[idx];
                        // Try multiple field names for the user's name
                        final name = u?['name'] ??
                            u?['userName'] ??
                            u?['email']?.toString().split('@')[0] ??
                            'User ${idx + 1}';
                        final email = u?['email'] ?? '';
                        final pic = u?['profilePicture'];
                        return ListTile(
                          leading: pic != null && pic.toString().isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage: MemoryImage(base64Decode(
                                      pic.toString().split(',').last)),
                                )
                              : CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  child: Text(name[0].toUpperCase(),
                                      style: const TextStyle(
                                          color: Colors.white))),
                          title: Text(name),
                          subtitle: email.isNotEmpty
                              ? Text(email,
                                  style: const TextStyle(fontSize: 12))
                              : null,
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          )
        ],
      ),
    );
  }

  Widget _buildReadIndicator(Map<String, dynamic> message) {
    final readBy = ((message['readBy'] ?? []) as Iterable)
        .map((r) => r.toString())
        .toList();
    final count = readBy.length;

    // Simple ticks: 0 = single grey dash, 1 = single check, >1 = double checks
    if (count == 0) {
      return Icon(Icons.check, size: 12, color: Colors.white54);
    }

    if (count == 1) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.done, size: 12, color: Colors.white70),
        ],
      );
    }

    // For multiple readers show double tick + up to 3 small avatars
    final avatars = <Widget>[];
    for (int i = 0; i < (count > 3 ? 3 : count); i++) {
      final uid = readBy[i];
      final cached = _userCache[uid];
      Widget avatar;
      if (cached != null && cached['profilePicture'] != null) {
        try {
          avatar = CircleAvatar(
            radius: 6,
            backgroundImage: MemoryImage(
                base64Decode(cached['profilePicture'].split(',')[1])),
          );
        } catch (_) {
          avatar =
              CircleAvatar(radius: 6, child: const Icon(Icons.person, size: 8));
        }
      } else {
        avatar =
            CircleAvatar(radius: 6, child: const Icon(Icons.person, size: 8));
      }
      avatars.add(Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: avatar,
      ));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.done_all, size: 14, color: Colors.lightGreenAccent),
        ...avatars,
      ],
    );
  }
}
