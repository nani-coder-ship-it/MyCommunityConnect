import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/services/auth_service.dart';
import 'src/services/socket_service.dart';
import 'src/services/simple_notification_service.dart';
import 'src/services/theme_service.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const ConnectApp(),
    ),
  );
}

class ConnectApp extends StatefulWidget {
  const ConnectApp({super.key});

  @override
  State<ConnectApp> createState() => _ConnectAppState();
}

class _ConnectAppState extends State<ConnectApp> {
  final auth = AuthService();
  late final SocketService socket;
  late final SimpleNotificationService notifications;
  bool initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await auth.init();
    socket = SocketService(auth: auth);
    notifications = SimpleNotificationService();
    
    // Initialize notifications (local only, no Firebase)
    await notifications.initialize();

    if (await auth.hasToken()) {
      await socket.connect();
      
      // Listen for various socket events and show notifications
      socket.socket?.on('notification', (data) {
        notifications.showNotification(
          title: data['title'] ?? 'ConnectApp',
          body: data['body'] ?? 'You have a new notification',
          data: data,
        );
      });
      
      // Show notification for new alerts
      socket.socket?.on('alert:new', (data) {
        notifications.showNotification(
          title: '🚨 Alert: ${data['alertType'] ?? 'Alert'}',
          body: data['reason'] ?? 'New alert from admin',
          data: data,
        );
      });
      
      // Show notification for new chat messages (when not in chat screen)
      socket.socket?.on('chat:new_message', (data) {
        notifications.showNotification(
          title: '💬 ${data['user']?['name'] ?? 'Someone'}',
          body: data['message'] ?? 'New message',
          data: data,
        );
      });
    }
    setState(() => initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      return const MaterialApp(
          home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }

    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'ConnectApp',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          home: FutureBuilder<bool>(
            future: auth.hasToken(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }
              final loggedIn = snapshot.data == true;
              if (loggedIn) {
                return HomeScreen(auth: auth, socket: socket);
              }
              return LoginScreen(auth: auth, socket: socket);
            },
          ),
        );
      },
    );
  }
}
