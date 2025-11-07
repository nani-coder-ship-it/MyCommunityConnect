import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../services/api_service.dart';
import '../widgets/full_screen_image_viewer.dart';
import '../widgets/skeleton_loader.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final api = ApiService();
  List<dynamic> posts = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _toggleLike(Map<String, dynamic> post, int index) async {
    final bool currentlyLiked = post['userHasLiked'] == true;
    final String id = post['_id'];
    final int currentCount = (post['likesCount'] ?? 0) as int;

    // Optimistic update
    setState(() {
      posts[index] = {
        ...post,
        'userHasLiked': !currentlyLiked,
        'likesCount': currentlyLiked ? (currentCount - 1) : (currentCount + 1),
      };
    });

    try {
      if (currentlyLiked) {
        final res = await api.dio.delete('/api/posts/$id/like');
        if (mounted) {
          setState(() {
            posts[index] = {
              ...posts[index],
              'userHasLiked': res.data['userHasLiked'] ?? false,
              'likesCount':
                  res.data['likesCount'] ?? posts[index]['likesCount'],
            };
          });
        }
      } else {
        final res = await api.dio.post('/api/posts/$id/like');
        if (mounted) {
          setState(() {
            posts[index] = {
              ...posts[index],
              'userHasLiked': res.data['userHasLiked'] ?? true,
              'likesCount':
                  res.data['likesCount'] ?? posts[index]['likesCount'],
            };
          });
        }
      }
    } catch (e) {
      // Revert on failure
      if (mounted) {
        setState(() {
          posts[index] = post;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update like: $e'),
              backgroundColor: Colors.orange),
        );
      }
    }
  }

  Future<void> _load() async {
    if (mounted)
      setState(() {
        loading = true;
        error = null;
      });
    try {
      final res = await api.dio.get('/api/posts?limit=50&page=1');
      if (mounted) {
        setState(() {
          posts = res.data['items'] ?? [];
          loading = false;
        });
      }
    } catch (e) {
      print('❌ Posts Error: $e');
      if (mounted) {
        setState(() {
          error = 'Failed to load posts. Please try logging in again.';
          loading = false;
        });
      }
    }
  }

  void _showCreatePostDialog() {
    final controller = TextEditingController();
    List<File> imageFiles = [];
    List<String> imageBase64List = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Post'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Share something with the community...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                if (imageFiles.isNotEmpty) ...[
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: imageFiles.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                imageFiles[index],
                                height: 120,
                                width: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white, size: 20),
                                onPressed: () {
                                  setDialogState(() {
                                    imageFiles.removeAt(index);
                                    imageBase64List.removeAt(index);
                                  });
                                },
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(28, 28),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                OutlinedButton.icon(
                  onPressed: imageFiles.length >= 5
                      ? null
                      : () async {
                          final picker = ImagePicker();
                          final images = await picker.pickMultiImage(
                            maxWidth: 800,
                            imageQuality: 85,
                          );
                          if (images.isNotEmpty) {
                            for (var image in images) {
                              if (imageFiles.length >= 5) break;
                              final bytes =
                                  await File(image.path).readAsBytes();
                              setDialogState(() {
                                imageFiles.add(File(image.path));
                                imageBase64List.add(
                                    'data:image/jpeg;base64,${base64Encode(bytes)}');
                              });
                            }
                          }
                        },
                  icon: const Icon(Icons.image),
                  label: Text(imageFiles.isEmpty
                      ? 'Add Photos (max 5)'
                      : 'Add More (${imageFiles.length}/5)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;
                try {
                  await api.dio.post('/api/posts', data: {
                    'message': controller.text.trim(),
                    if (imageBase64List.isNotEmpty) 'images': imageBase64List,
                  });
                  if (!mounted) return;
                  Navigator.pop(context);
                  _load();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Post created!'),
                      backgroundColor: Colors.green));
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Failed: $e'),
                      backgroundColor: Colors.red));
                }
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading posts',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Posts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreatePostDialog,
            tooltip: 'Create Post',
          ),
        ],
      ),
      body: loading
          ? ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) => const PostSkeleton(),
            )
          : posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article_outlined,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No posts yet',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text('Be the first to share something!',
                          style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _showCreatePostDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Post'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: posts.length,
                    itemBuilder: (context, i) {
                      final p = posts[i];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.blue,
                                    backgroundImage:
                                        p['userProfilePicture'] != null
                                            ? MemoryImage(base64Decode(
                                                p['userProfilePicture']
                                                    .split(',')[1]))
                                            : null,
                                    child: p['userProfilePicture'] == null
                                        ? Text(
                                            (p['userName'] ?? 'R')[0]
                                                .toUpperCase(),
                                            style: const TextStyle(
                                                color: Colors.white))
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['userName'] ?? 'Resident',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          _formatDate(p['createdAt']),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red, size: 20),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Post'),
                                          content: const Text(
                                              'Are you sure you want to delete this post?'),
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
                                              .delete('/api/posts/${p['_id']}');
                                          _load();
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text('Post deleted'),
                                                  backgroundColor:
                                                      Colors.green),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            // Check if it's a 403 (permission denied) error
                                            final errorMsg = e
                                                    .toString()
                                                    .contains('403')
                                                ? 'You can only delete your own posts'
                                                : 'Failed to delete post';
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(errorMsg),
                                                  backgroundColor:
                                                      Colors.orange),
                                            );
                                          }
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(p['message'] ?? '',
                                  style: const TextStyle(fontSize: 15)),
                              // Display multiple images
                              if (p['images'] != null &&
                                  (p['images'] as List).isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _buildImageGrid(p['images'] as List),
                              ]
                              // Fallback to single image for legacy posts
                              else if (p['imageUrl'] != null &&
                                  p['imageUrl'].toString().isNotEmpty) ...[
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            FullScreenImageViewer(
                                          imageData: p['imageUrl'],
                                        ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _buildImage(p['imageUrl']),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      (p['userHasLiked'] == true)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: (p['userHasLiked'] == true)
                                          ? Colors.red
                                          : Colors.grey[700],
                                    ),
                                    onPressed: () => _toggleLike(
                                        p as Map<String, dynamic>, i),
                                  ),
                                  const SizedBox(width: 4),
                                  Text('${p['likesCount'] ?? 0}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date.toString());
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (e) {
      return '';
    }
  }

  Widget _buildImage(String imageData) {
    try {
      // Check if it's a base64 image
      if (imageData.startsWith('data:image')) {
        final base64String = imageData.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => Container(
            height: 200,
            color: Colors.grey[300],
            child: const Center(child: Icon(Icons.broken_image, size: 50)),
          ),
        );
      } else {
        // It's a URL
        return Image.network(
          imageData,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => Container(
            height: 200,
            color: Colors.grey[300],
            child: const Center(child: Icon(Icons.broken_image, size: 50)),
          ),
        );
      }
    } catch (e) {
      return Container(
        height: 200,
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.broken_image, size: 50)),
      );
    }
  }

  Widget _buildImageGrid(List images) {
    if (images.isEmpty) return const SizedBox.shrink();

    final imageCount = images.length;

    // Single image - full width
    if (imageCount == 1) {
      return GestureDetector(
        onTap: () => _openImageViewer(images[0]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildImage(images[0]),
        ),
      );
    }

    // Multiple images - grid layout
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: imageCount == 2 ? 2 : 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: imageCount > 5 ? 5 : imageCount,
      itemBuilder: (context, index) {
        final isLast = index == 4 && imageCount > 5;
        return GestureDetector(
          onTap: () => _openImageViewer(images[index]),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImage(images[index]),
              ),
              if (isLast)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '+${imageCount - 5}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _openImageViewer(String imageData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(imageData: imageData),
      ),
    );
  }
}
