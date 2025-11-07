import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthService auth;
  final SocketService? socket;
  const LoginScreen({super.key, required this.auth, this.socket});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ConnectApp Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.apartment,
                    size: 80, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 32),
                Text('Welcome Back!',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v != null && v.contains('@') ? null : 'Enter valid email',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (v) => (v ?? '').length >= 6
                      ? null
                      : 'Password must be at least 6 characters',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: loading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => loading = true);
                              final nav = Navigator.of(context);
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await widget.auth.login(
                                    _emailController.text.trim(),
                                    _passwordController.text);
                                await widget.socket?.connect();

                                if (!mounted) return;
                                nav.pushReplacement(
                                  MaterialPageRoute(
                                      builder: (_) => HomeScreen(
                                          auth: widget.auth,
                                          socket: widget.socket)),
                                );
                              } catch (e) {
                                if (!mounted) return;

                                // Show user-friendly error messages
                                String errorMsg =
                                    'Login failed. Please try again.';

                                if (e.toString().contains('401')) {
                                  errorMsg = 'Invalid email or password';
                                } else if (e.toString().contains('network') ||
                                    e.toString().contains('connection')) {
                                  errorMsg =
                                      'Network error. Please check your internet connection.';
                                } else if (e.toString().contains('timeout')) {
                                  errorMsg =
                                      'Server timeout. Please try again.';
                                } else if (e.toString().contains('404')) {
                                  errorMsg =
                                      'Server not found. Please check server settings.';
                                }

                                messenger.showSnackBar(SnackBar(
                                    content: Text(errorMsg),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 4)));
                              } finally {
                                if (mounted) setState(() => loading = false);
                              }
                            }
                          },
                    child: loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Login', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: loading
                      ? null
                      : () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen()));
                        },
                  child: const Text('Forgot Password?'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: loading
                      ? null
                      : () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) =>
                                  RegisterScreen(auth: widget.auth)));
                        },
                  child: const Text('Create New Account'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
