import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class SendAlertScreen extends StatefulWidget {
  final SocketService? socket;
  const SendAlertScreen({super.key, this.socket});

  @override
  State<SendAlertScreen> createState() => _SendAlertScreenState();
}

class _SendAlertScreenState extends State<SendAlertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _detailsController = TextEditingController();
  final _locationController = TextEditingController();
  final api = ApiService();

  String _alertType = 'Emergency';
  bool _isAdmin = false;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminRole() async {
    try {
      final res = await api.dio.get('/api/auth/me');
      final role = res.data['user']?['role']?.toString();
      setState(() {
        _isAdmin = role == 'admin';
        _loading = false;
      });
      if (!_isAdmin && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only admins can send alerts'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to verify admin: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _sendAlert() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _sending = true);
    try {
      final details = _detailsController.text.trim();
      final location = _locationController.text.trim();

      // Emit socket event
      widget.socket?.socket?.emit('alert:raise', {
        'alertType': _alertType,
        'details': details,
        'location': location.isNotEmpty ? location : null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Alert sent to all residents'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send alert: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Send Alert')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Community Alert'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This alert will be sent to all community residents via push notification.',
                        style: TextStyle(fontSize: 13, color: Colors.red[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Alert Type
            const Text('Alert Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _alertType,
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.warning_amber),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'Emergency', child: Text('🚨 Emergency')),
                DropdownMenuItem(value: 'Fire', child: Text('🔥 Fire')),
                DropdownMenuItem(
                    value: 'Medical', child: Text('🏥 Medical Emergency')),
                DropdownMenuItem(
                    value: 'Security', child: Text('🛡️ Security Alert')),
                DropdownMenuItem(
                    value: 'Maintenance', child: Text('🔧 Maintenance')),
                DropdownMenuItem(
                    value: 'Weather', child: Text('🌧️ Weather Warning')),
                DropdownMenuItem(
                    value: 'Other', child: Text('📢 General Announcement')),
              ],
              onChanged: (val) => setState(() => _alertType = val!),
            ),
            const SizedBox(height: 20),

            // Details (Required)
            const Text('Alert Details *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _detailsController,
              decoration: InputDecoration(
                hintText: 'Describe the situation clearly...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 4,
              maxLength: 500,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please provide alert details';
                }
                if (val.trim().length < 10) {
                  return 'Details must be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Location (Optional)
            const Text('Location (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'e.g., Building A, Floor 3',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.location_on),
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 32),

            // Send Button
            FilledButton.icon(
              onPressed: _sending ? null : _sendAlert,
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label:
                  Text(_sending ? 'Sending...' : 'Send Alert to All Residents'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
