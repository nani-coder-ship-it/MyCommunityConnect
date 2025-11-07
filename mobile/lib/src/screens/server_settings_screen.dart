import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../services/config_service.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class ServerSettingsScreen extends StatefulWidget {
  final ApiService api;
  final SocketService? socket;
  const ServerSettingsScreen({super.key, required this.api, this.socket});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _saving = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final current = await ConfigService.I.getApiBaseUrl();
    if (mounted) _controller.text = current;
  }

  Future<void> _validateEndpoint() async {
    setState(() {
      _status = 'Checking health...';
    });
    try {
      final url = _controller.text.trim();
      if (!url.startsWith('http')) {
        throw 'URL must start with http:// or https://';
      }
      final dio = Dio(BaseOptions(
          baseUrl: url, connectTimeout: const Duration(seconds: 6)));
      final res = await dio.get('/health');
      if (!mounted) return;
      setState(() {
        _status = 'Healthy (${res.statusCode})';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Health check failed: $e';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final url = _controller.text.trim();
    setState(() => _saving = true);
    try {
      await ConfigService.I.setApiBaseUrl(url);
      widget.api.updateBaseUrl(url);
      // Reconnect socket to new base
      await widget.socket?.socket?.disconnect();
      await widget.socket?.connect();

      // Re-register FCM token against the new base URL so push works immediately
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          final api2 = ApiService();
          await api2.dio.put('/api/users/fcm-token', data: {'token': token});
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('FCM token re-registered.')),
          );
        }
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Warning: Failed to re-register FCM token: $e')),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server URL saved.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to save: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Server Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('API Base URL',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'http://<your-ip>:4000',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final val = (v ?? '').trim();
                  if (val.isEmpty) return 'Enter server URL';
                  if (!val.startsWith('http://') &&
                      !val.startsWith('https://')) {
                    return 'URL must start with http:// or https://';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (_status != null)
                Text(_status!, style: const TextStyle(color: Colors.black54)),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _validateEndpoint,
                      icon: const Icon(Icons.health_and_safety),
                      label: const Text('Check Health'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
