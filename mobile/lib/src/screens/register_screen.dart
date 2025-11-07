import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  final AuthService auth;
  const RegisterScreen({super.key, required this.auth});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _flatNo = TextEditingController();
  final _ownerName = TextEditingController();
  final _phoneNo = TextEditingController();
  final _adminCode = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                  labelText: 'Full Name', border: OutlineInputBorder()),
              validator: (v) =>
                  v != null && v.isNotEmpty ? null : 'Name is required',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  hintText: 'your.email@example.com'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                // Real email validation regex
                final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                if (!emailRegex.hasMatch(v)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              decoration: const InputDecoration(
                  labelText: 'Password', border: OutlineInputBorder()),
              obscureText: true,
              validator: (v) => (v ?? '').length >= 6
                  ? null
                  : 'Password must be at least 6 characters',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _flatNo,
              decoration: const InputDecoration(
                  labelText: 'Flat/Room Number', border: OutlineInputBorder()),
              validator: (v) =>
                  v != null && v.isNotEmpty ? null : 'Flat number is required',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ownerName,
              decoration: const InputDecoration(
                  labelText: 'Owner Name', border: OutlineInputBorder()),
              validator: (v) =>
                  v != null && v.isNotEmpty ? null : 'Owner name is required',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneNo,
              decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  hintText: '9876543210',
                  prefixText: '+91 '),
              keyboardType: TextInputType.phone,
              maxLength: 10,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Phone number is required';
                // Indian phone number validation (10 digits starting with 6-9)
                final phoneRegex = RegExp(r'^[6-9]\d{9}$');
                if (!phoneRegex.hasMatch(v)) {
                  return 'Enter a valid 10-digit phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _adminCode,
              decoration: const InputDecoration(
                labelText: 'Admin Code (Optional - for managers only)',
                border: OutlineInputBorder(),
                helperText: 'Leave blank if you are a resident',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _loading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _loading = true);
                          final nav = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await widget.auth.register({
                              'name': _name.text.trim(),
                              'email': _email.text.trim(),
                              'password': _password.text,
                              'roomNo': _flatNo.text.trim(),
                              'ownerName': _ownerName.text.trim(),
                              'phoneNo': _phoneNo.text.trim(),
                              if (_adminCode.text.trim().isNotEmpty)
                                'adminCode': _adminCode.text.trim(),
                            });
                            if (!mounted) return;
                            messenger.showSnackBar(const SnackBar(
                                content: Text('Account created! Please login.'),
                                backgroundColor: Colors.green));
                            nav.pop();
                          } catch (e) {
                            if (!mounted) return;

                            // Extract user-friendly error message
                            String errorMessage =
                                'Registration failed. Please try again.';

                            if (e.toString().contains('409')) {
                              errorMessage =
                                  'This email or phone number is already registered.';
                            } else if (e.toString().contains('400') ||
                                e.toString().contains('bad')) {
                              errorMessage =
                                  'Please check all fields and try again.';
                            } else if (e.toString().contains('network') ||
                                e.toString().contains('connection')) {
                              errorMessage =
                                  'Network error. Please check your internet connection.';
                            } else if (e.toString().contains('timeout')) {
                              errorMessage =
                                  'Server timeout. Please try again.';
                            } else if (e
                                .toString()
                                .contains('Invalid admin code')) {
                              errorMessage =
                                  'Invalid admin code. Please check and try again.';
                            }

                            messenger.showSnackBar(SnackBar(
                                content: Text(errorMessage),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 4)));
                          } finally {
                            if (mounted) setState(() => _loading = false);
                          }
                        }
                      },
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Create Account'),
              ),
            )
          ]),
        ),
      ),
    );
  }
}
