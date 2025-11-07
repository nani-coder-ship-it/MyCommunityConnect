import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/skeleton_loader.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final api = ApiService();
  List<dynamic> requests = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final res = await api.dio.get('/api/maintenance');
      setState(() {
        requests = res.data['items'] ?? [];
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  void _createRequest() {
    final issueCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String priority = 'medium';
    List<File> imageFiles = [];
    List<String> imageBase64List = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Maintenance Request'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: issueCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Issue Type',
                    hintText: 'e.g., Plumbing, Electrical, etc.',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.build),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe the issue...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.priority_high),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => priority = value!);
                  },
                ),
                const SizedBox(height: 12),
                // Photo upload section
                if (imageFiles.isNotEmpty) ...[
                  SizedBox(
                    height: 100,
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
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    imageFiles.removeAt(index);
                                    imageBase64List.removeAt(index);
                                  });
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                OutlinedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final pickedFiles = await picker.pickMultiImage();
                    if (pickedFiles.isNotEmpty) {
                      for (var pickedFile in pickedFiles) {
                        final file = File(pickedFile.path);
                        final bytes = await file.readAsBytes();
                        final base64 =
                            'data:image/jpeg;base64,${base64Encode(bytes)}';
                        setDialogState(() {
                          imageFiles.add(file);
                          imageBase64List.add(base64);
                        });
                      }
                    }
                  },
                  icon: const Icon(Icons.add_photo_alternate),
                  label: Text(imageFiles.isEmpty
                      ? 'Add Photos (Optional)'
                      : 'Add More Photos'),
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
                if (issueCtrl.text.trim().isEmpty ||
                    descCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('All fields are required'),
                        backgroundColor: Colors.red),
                  );
                  return;
                }
                try {
                  await api.dio.post('/api/maintenance', data: {
                    'issueType': issueCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'priority': priority,
                    'photos': imageBase64List, // Send photos
                  });
                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadRequests();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Request submitted!'),
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
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'resolved':
        return Colors.green;
      case 'in-progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: loading
          ? ListView.builder(
              itemCount: 8,
              itemBuilder: (context, index) => const ListTileSkeleton(),
            )
          : requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.build_circle_outlined,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No maintenance requests',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      const Text('Submit your first request!'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, i) {
                    final request = requests[i];
                    final photos =
                        (request['photos'] as List<dynamic>?)?.toList();
                    final hasPhotos = photos != null && photos.isNotEmpty;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  _getPriorityColor(request['priority'])
                                      .withOpacity(0.2),
                              child: Icon(Icons.build,
                                  color:
                                      _getPriorityColor(request['priority'])),
                            ),
                            title: Text(request['issueType'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(request['description'] ?? ''),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getPriorityColor(
                                                request['priority'])
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        (request['priority'] ?? 'medium')
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: _getPriorityColor(
                                              request['priority']),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            _getStatusColor(request['status'])
                                                .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        (request['status'] ?? 'pending')
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(
                                              request['status']),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Request'),
                                    content: const Text(
                                        'Are you sure you want to delete this maintenance request?'),
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
                                    await api.dio.delete(
                                        '/api/maintenance/${request['_id']}');
                                    _loadRequests();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('Request deleted'),
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
                          // Show photos if available
                          if (hasPhotos)
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: SizedBox(
                                height: 80,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: photos.length,
                                  itemBuilder: (context, photoIndex) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                            base64Decode(photos[photoIndex]
                                                .split(',')[1]),
                                            height: 80,
                                            width: 80,
                                            fit: BoxFit.cover),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createRequest,
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
    );
  }
}
