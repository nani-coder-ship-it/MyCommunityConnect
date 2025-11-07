import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../services/theme_service.dart';
import 'dashboard_screen.dart';
import 'chat_screen.dart';
import 'contacts_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final AuthService? auth;
  final SocketService? socket;
  const HomeScreen({super.key, this.auth, this.socket});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  int _previousIndex = 0; // Track previous tab

  @override
  void initState() {
    super.initState();
    // Connect socket when home screen loads
    widget.socket?.connect();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      DashboardScreen(socket: widget.socket),
      ChatScreen(socket: widget.socket),
      const ContactsScreen(),
      ProfileScreen(auth: widget.auth, socket: widget.socket),
    ];

    return PopScope(
      canPop: false, // Always intercept back button
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // Check if there are pages in the navigation stack
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          // If there are pushed pages, pop them normally
          navigator.pop();
        } else if (_index != 0) {
          // If no pushed pages and not on first tab, go to previous tab
          setState(() {
            final temp = _index;
            _index = _previousIndex;
            _previousIndex = temp;
          });
        } else {
          // If on first tab with no pushed pages, close app
          // This will trigger the system back button behavior
          return;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ConnectApp'),
          centerTitle: true,
          actions: [
            Consumer<ThemeService>(
              builder: (context, themeService, child) {
                return IconButton(
                  icon: Icon(
                    themeService.themeMode == ThemeMode.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  onPressed: () => themeService.toggleTheme(),
                  tooltip: 'Toggle theme',
                );
              },
            ),
          ],
        ),
        body: tabs[_index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) {
            setState(() {
              _previousIndex = _index; // Save current as previous
              _index = i; // Update to new tab
            });
          },
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: 'Chat'),
            NavigationDestination(
                icon: Icon(Icons.contacts_outlined),
                selectedIcon: Icon(Icons.contacts),
                label: 'Contacts'),
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
