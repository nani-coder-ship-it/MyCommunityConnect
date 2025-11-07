import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/skeleton_loader.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final api = ApiService();
  List<dynamic> contacts = [];
  bool loading = true;
  String userRole = 'resident'; // Track current user's role

  @override
  void initState() {
    super.initState();
    _load();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final res = await api.dio.get('/api/auth/me');
      if (mounted) {
        setState(() {
          userRole = res.data['user']?['role'] ?? 'resident';
        });
        print('Contacts: User role loaded: $userRole');
      }
    } catch (e) {
      print('Error loading user role: $e');
      // Default to resident if error
    }
  }

  Future<void> _load() async {
    try {
      final res = await api.dio.get('/api/contacts');
      if (mounted) {
        setState(() {
          contacts = res.data ?? [];
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  bool _isEditable(String? category) {
    // Only admins can edit contacts
    return userRole == 'admin';
  }

  void _editContact(Map<String, dynamic> contact) {
    final nameCtrl = TextEditingController(text: contact['name']);
    final phoneCtrl = TextEditingController(text: contact['phone']);
    final descCtrl = TextEditingController(text: contact['description'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Contact'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
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
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
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
                  phoneCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Name and phone are required'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              try {
                await api.dio.put('/api/contacts/${contact['_id']}', data: {
                  'name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                });
                if (!mounted) return;
                Navigator.pop(context);
                _load();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contact updated!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                // Check if it's a 403 (permission denied) error
                final errorMsg = e.toString().contains('403')
                    ? 'Only admins can edit contacts'
                    : 'Failed to update contact';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMsg),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: loading
          ? ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) => const ListTileSkeleton(),
            )
          : contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.contacts_outlined,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No contacts available',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: contacts.length,
                  itemBuilder: (context, i) {
                    final c = contacts[i];
                    final isEditable = _isEditable(c['category']);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: c['category'] == 'Emergency'
                              ? Colors.red
                              : Colors.blue,
                          child: Icon(
                            _getIcon(c['category'], c['name']),
                            color: Colors.white,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(c['name'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                            if (c['available24x7'] == true)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '24x7',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (c['description'] != null)
                              Text(c['description'],
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 12)),
                            const SizedBox(height: 4),
                            if (c['phone'] != null)
                              Text(c['phone'],
                                  style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500)),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isEditable)
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.orange, size: 20),
                                onPressed: () => _editContact(c),
                              ),
                            if (c['phone'] != null)
                              IconButton(
                                icon:
                                    const Icon(Icons.call, color: Colors.green),
                                onPressed: () => _makeCall(c['phone']),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  IconData _getIcon(String? category, String? name) {
    if (category == 'Emergency') {
      final n = (name ?? '').toLowerCase();
      if (n.contains('ambulance')) return Icons.local_hospital;
      if (n.contains('police')) return Icons.local_police;
      if (n.contains('fire')) return Icons.local_fire_department;
    }
    if (category == 'Community') {
      final n = (name ?? '').toLowerCase();
      if (n.contains('guard') || n.contains('security')) return Icons.security;
      if (n.contains('manage')) return Icons.admin_panel_settings;
    }
    if (category == 'Maintenance') return Icons.build;
    return Icons.person;
  }
}
