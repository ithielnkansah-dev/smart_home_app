import 'dart:io';
import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../screens/energy/energy_screen.dart';
import '../screens/menu/integration_center_screen.dart';
import '../screens/menu/settings_screen.dart';
import '../screens/menu/notifications_center_screen.dart';
import '../screens/security/security_screen.dart';
import '../screens/activities/activities_screen.dart';
import '../screens/security/alarm_settings_screen.dart';
import '../screens/people/people_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/devices/provisioning_screen.dart';
import '../screens/automation/automation_engine_screen.dart';

class AppMenuDrawer extends StatelessWidget {
  const AppMenuDrawer({super.key});

  void _showLogoutConfirmationDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of your Smart Home account?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Close drawer
              state.logout();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully.')),
              );
            },
            child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    final menuItems = [
      {
        'title': 'Automation Engine',
        'icon': Icons.auto_awesome_rounded,
        'screen': const AutomationEngineScreen(),
      },
      {
        'title': 'Pair Hardware (QR/NFC)',
        'icon': Icons.qr_code_scanner_rounded,
        'screen': const ProvisioningScreen(),
      },
      {
        'title': 'Energy & Renewables',
        'icon': Icons.bolt_rounded,
        'screen': const EnergyScreen(),
      },
      {
        'title': 'Integration Center',
        'icon': Icons.hub_rounded,
        'screen': const IntegrationCenterScreen(),
      },
      {
        'title': 'Settings',
        'icon': Icons.settings_rounded,
        'screen': const SettingsScreen(),
      },
      {
        'title': 'Notifications',
        'icon': Icons.notifications_rounded,
        'screen': const NotificationsCenterScreen(),
      },
      {
        'title': 'Security',
        'icon': Icons.shield_rounded,
        'screen': const SecurityScreen(),
      },
      {
        'title': 'Activity Log',
        'icon': Icons.assignment_rounded,
        'screen': const ActivitiesScreen(),
      },
      {
        'title': 'Alarm Settings',
        'icon': Icons.tune_rounded,
        'screen': const AlarmSettingsScreen(),
      },
      {
        'title': 'People Access',
        'icon': Icons.people_rounded,
        'screen': const PeopleScreen(),
      },
    ];

    return Drawer(
      width: screenWidth * 0.55,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Top Bar: Close (X) on left, Title in middle, Logout Icon on right
            AnimatedBuilder(
              animation: state,
              builder: (context, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : Colors.black),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Close Menu',
                      ),
                      Text(
                        'Menu',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          state.isLoggedIn ? Icons.logout_rounded : Icons.login_rounded,
                          color: state.isLoggedIn ? Colors.red.shade400 : (isDark ? Colors.white : Colors.black),
                        ),
                        tooltip: state.isLoggedIn ? 'Log Out' : 'Log In',
                        onPressed: () {
                          if (state.isLoggedIn) {
                            _showLogoutConfirmationDialog(context, state);
                          } else {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (c) => const LoginScreen()),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            Divider(height: 1, color: isDark ? Colors.white24 : Colors.black12),

            // User Profile Header inside Drawer
            AnimatedBuilder(
              animation: state,
              builder: (context, child) {
                return InkWell(
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => const ProfileScreen()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isDark ? Colors.white24 : Colors.black12,
                          backgroundImage: state.profileImagePath != null && File(state.profileImagePath!).existsSync()
                              ? FileImage(File(state.profileImagePath!))
                              : null,
                          child: state.profileImagePath == null || !File(state.profileImagePath!).existsSync()
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 20,
                                  color: isDark ? Colors.white : Colors.black87,
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.isLoggedIn
                                    ? (state.currentUser?.name ?? 'Home Owner')
                                    : 'Guest User',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              Text(
                                state.isLoggedIn ? 'Online • Tap for Profile' : 'Logged Out',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: state.isLoggedIn ? Colors.green.shade400 : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),

            Divider(height: 1, color: isDark ? Colors.white24 : Colors.black12),

            // Menu Items List - Adaptive to Dark/Light Mode
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];

                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: Icon(
                      item['icon'] as IconData,
                      color: isDark ? Colors.white : Colors.black,
                      size: 20,
                    ),
                    title: Text(
                      item['title'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (c) => item['screen'] as Widget),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
