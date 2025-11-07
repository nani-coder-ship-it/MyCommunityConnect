import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/skeleton_loader.dart';

class VisitorsScreen extends StatefulWidget {
  const VisitorsScreen({super.key});

  @override
  State<VisitorsScreen> createState() => _VisitorsScreenState();
}

class _VisitorsScreenState extends State<VisitorsScreen> {
  final api = ApiService();
  List<dynamic> visitors = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadVisitors();
  }

  Future<void> _loadVisitors() async {
    try {
      final res = await api.dio.get('/api/visitors/me');
      if (mounted) {
        setState(() {
          visitors = res.data ?? [];
          loading = false;
        });
      }
    } catch (e) {
      print('❌ Visitors Error: $e');
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Failed to load visitors. Please try logging in again.'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _registerVisitor() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final flatCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Register Visitor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Visitor Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: flatCtrl,
                decoration: const InputDecoration(
                  labelText: 'Visiting Flat/Room',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: purposeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Purpose of Visit',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
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
              if (nameCtrl.text.trim().isEmpty ||
                  flatCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Name and Flat are required'),
                      backgroundColor: Colors.red),
                );
                return;
              }
              try {
                await api.dio.post('/api/visitors', data: {
                  'visitorName': nameCtrl.text.trim(),
                  'contact': phoneCtrl.text.trim(),
                  'flatVisiting': flatCtrl.text.trim(),
                  'purpose': purposeCtrl.text.trim(),
                  'visitStart': DateTime.now().toIso8601String(),
                });
                if (!mounted) return;
                Navigator.pop(context);
                _loadVisitors();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Visitor registered!'),
                      backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitors Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVisitors,
          ),
        ],
      ),
      body: loading
          ? ListView.builder(
              itemCount: 8,
              itemBuilder: (context, index) => const ListTileSkeleton(),
            )
          : visitors.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No visitors registered',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      const Text('Register your first visitor!'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: visitors.length,
                  itemBuilder: (context, i) {
                    final visitor = visitors[i];
                    final timestamp = DateTime.parse(visitor['createdAt']);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple[100],
                          child: Icon(Icons.person, color: Colors.purple[700]),
                        ),
                        title: Text(visitor['visitorName'] ?? '',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Visiting: ${visitor['flatVisiting'] ?? ''}'),
                            Text('Purpose: ${visitor['purpose'] ?? 'N/A'}'),
                            Text('Phone: ${visitor['contact'] ?? 'N/A'}'),
                            Text(
                              '${timestamp.day}/${timestamp.month}/${timestamp.year} at ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
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
                                title: const Text('Delete Visitor'),
                                content: const Text(
                                    'Are you sure you want to delete this visitor record?'),
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
                                    .delete('/api/visitors/${visitor['_id']}');
                                _loadVisitors();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Visitor deleted'),
                                        backgroundColor: Colors.green),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
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
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _registerVisitor,
        icon: const Icon(Icons.person_add),
        label: const Text('Register Visitor'),
      ),
    );
  }
}
