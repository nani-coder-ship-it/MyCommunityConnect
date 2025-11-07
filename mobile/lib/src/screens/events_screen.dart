import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/skeleton_loader.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final api = ApiService();
  List<dynamic> events = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final res = await api.dio.get('/api/events');
      if (mounted) {
        setState(() {
          events = res.data is List ? res.data : [];
          loading = false;
        });
      }
    } catch (e) {
      print('❌ Events Error: $e');
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Failed to load events. Please try logging in again.'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleRSVP(Map<String, dynamic> event, int index) async {
    final eventId = event['_id'];
    final isAttending = event['userAttending'] == true;

    // Optimistic update
    setState(() {
      events[index] = {
        ...event,
        'userAttending': !isAttending,
        'attendeesCount': isAttending
            ? (event['attendeesCount'] ?? 0) - 1
            : (event['attendeesCount'] ?? 0) + 1,
      };
    });

    try {
      if (isAttending) {
        await api.dio.delete('/api/events/$eventId/rsvp');
      } else {
        await api.dio.post('/api/events/$eventId/rsvp');
      }
      // Reload to get accurate data
      _loadEvents();
    } catch (e) {
      // Revert on error
      setState(() {
        events[index] = event;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update RSVP: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _createEvent() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Event Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Event Date'),
                  subtitle: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                try {
                  await api.dio.post('/api/events', data: {
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'eventDate': selectedDate.toIso8601String(),
                  });
                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadEvents();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Event created!'),
                        backgroundColor: Colors.green),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
          ),
        ],
      ),
      body: loading
          ? ListView.builder(
              itemCount: 6,
              itemBuilder: (context, index) => const EventSkeleton(),
            )
          : events.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No events yet',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      const Text('Create your first community event!'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  itemBuilder: (context, i) {
                    final event = events[i];
                    final date = DateTime.parse(event['eventDate']);
                    final attendeesCount = event['attendeesCount'] ?? 0;
                    final userAttending = event['userAttending'] == true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${date.day}',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    _getMonthName(date.month),
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),
                            title: Text(event['title'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(event['description'] ?? ''),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.people,
                                        size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$attendeesCount attending',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Event'),
                                    content: const Text(
                                        'Are you sure you want to delete this event?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: FilledButton.styleFrom(
                                            backgroundColor: Colors.red),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && mounted) {
                                  try {
                                    await api.dio
                                        .delete('/api/events/${event['_id']}');
                                    _loadEvents();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('Event deleted'),
                                            backgroundColor: Colors.green),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => _toggleRSVP(event, i),
                                icon: Icon(
                                  userAttending
                                      ? Icons.check_circle
                                      : Icons.event_available,
                                ),
                                label:
                                    Text(userAttending ? 'Attending' : 'RSVP'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: userAttending
                                      ? Colors.green
                                      : Colors.blue,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createEvent,
        icon: const Icon(Icons.add),
        label: const Text('Create Event'),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      '',
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
    return months[month];
  }
}
