import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
      ),
      body: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_auto),
                title: const Text('System Theme'),
                subtitle: const Text('Follow system settings'),
                trailing: Radio<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: themeService.themeMode,
                  onChanged: (mode) {
                    if (mode != null) {
                      themeService.setThemeMode(mode);
                    }
                  },
                ),
                onTap: () => themeService.setThemeMode(ThemeMode.system),
              ),
              ListTile(
                leading: const Icon(Icons.light_mode),
                title: const Text('Light Theme'),
                subtitle: const Text('Always use light mode'),
                trailing: Radio<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: themeService.themeMode,
                  onChanged: (mode) {
                    if (mode != null) {
                      themeService.setThemeMode(mode);
                    }
                  },
                ),
                onTap: () => themeService.setThemeMode(ThemeMode.light),
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Dark Theme'),
                subtitle: const Text('Always use dark mode'),
                trailing: Radio<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: themeService.themeMode,
                  onChanged: (mode) {
                    if (mode != null) {
                      themeService.setThemeMode(mode);
                    }
                  },
                ),
                onTap: () => themeService.setThemeMode(ThemeMode.dark),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme Preview',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sample Card',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This is how cards will look in the selected theme.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {},
                              child: const Text('Sample Button'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
