import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'login_screen.dart';
import 'theme_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AuthService? auth;
  final SocketService? socket;
  const ProfileScreen({super.key, this.auth, this.socket});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final api = ApiService();
  final _imagePicker = ImagePicker();
  Map<String, dynamic>? user;
  bool loading = true;
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await api.dio.get('/api/auth/me');
      if (mounted) {
        setState(() {
          user = res.data['user'];
          loading = false;
        });
        print('Profile loaded: ${user?['email']}, role: ${user?['role']}');
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => uploading = true);

      // Read image file and convert to base64
      final bytes = await File(pickedFile.path).readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // Upload to server
      await api.dio.put('/api/users/profile-picture', data: {
        'profilePicture': base64Image,
      });

      // Reload profile to show new image
      await _loadProfile();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.auth?.logout();
      widget.socket?.socket?.disconnect();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) => LoginScreen(
                auth: widget.auth ?? AuthService(), socket: widget.socket)),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfile,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.blue,
                  backgroundImage: user?['profilePicture'] != null
                      ? MemoryImage(
                          base64Decode(user!['profilePicture'].split(',')[1]))
                      : null,
                  child: user?['profilePicture'] == null
                      ? Text(
                          (user?['name'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 48,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                if (uploading)
                  Positioned.fill(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.black54,
                      child:
                          const CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt,
                          size: 20, color: Colors.white),
                      onPressed: uploading ? null : _showImageSourceDialog,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              user?['name'] ?? 'User',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(user?['role'] == 'admin' ? 'Admin' : 'Resident'),
              backgroundColor:
                  user?['role'] == 'admin' ? Colors.orange : Colors.blue,
              labelStyle: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 32),
            _buildInfoCard('Email', user?['email'] ?? '', Icons.email),
            _buildInfoCard('Flat/Room', user?['roomNo'] ?? 'N/A', Icons.home),
            _buildInfoCard(
                'Owner Name', user?['ownerName'] ?? 'N/A', Icons.person),
            _buildInfoCard('Phone', user?['phoneNo'] ?? 'N/A', Icons.phone),
            // Theme Settings entry
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.palette, color: Colors.blue),
                title: const Text('Theme Settings'),
                subtitle: const Text('Choose light, dark, or system theme'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ThemeSettingsScreen(),
                  ));
                },
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label:
                    const Text('Logout', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        subtitle: Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
