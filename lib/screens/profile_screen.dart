import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/app_scaffold.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showImagePickerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  context.read<ProfileProvider>().takePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  context.read<ProfileProvider>().pickImage();
                },
              ),
              if (context.read<ProfileProvider>().profileImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    context.read<ProfileProvider>().removeProfileImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();

    if (authProvider.isLoading) {
      return AppScaffold(
        title: 'Profile',
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (authProvider.error != null) {
      return AppScaffold(
        title: 'Profile',
        child: Center(child: Text('Error: ${authProvider.error}')),
      );
    }

    final user = authProvider.user;

    return AppScaffold(
      title: 'Profile',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _showImagePickerModal(context),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: profileProvider.profileImage != null
                              ? FileImage(profileProvider.profileImage!)
                              : null,
                          child: profileProvider.profileImage == null
                              ? const Icon(Icons.person_outline, size: 50)
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().scale(),
                  const SizedBox(height: 16),
                  Text(
                    user != null ? (user['name'] ?? '') : '',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ).animate().fadeIn().slideY(),
                  const SizedBox(height: 4),
                  Text(
                    user != null ? (user['email'] ?? '') : '',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ).animate().fadeIn().slideY(),
                ],
              ),
            ),
          ).animate().fadeIn().slideY(),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Use System Theme'),
                  subtitle: const Text('Automatically match device theme'),
                  trailing: Switch(
                    value: themeProvider.useSystemTheme,
                    onChanged: (value) => themeProvider.toggleSystemTheme(),
                  ),
                ),
                if (!themeProvider.useSystemTheme) ...[
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      themeProvider.isDarkMode
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                    ),
                    title: Text('${themeProvider.isDarkMode ? 'Dark' : 'Light'} Mode'),
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (_) => themeProvider.toggleTheme(),
                    ),
                  ),
                ],
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    // TODO: Navigate to settings screen
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.device_hub),
                  title: const Text('Device Information'),
                  onTap: () {
                    context.push('/device-info');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () async {
                    try {
                      await Provider.of<AuthProvider>(context, listen: false).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error logging out: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ).animate().fadeIn().slideY(),
        ],
      ),
    );
  }
}
