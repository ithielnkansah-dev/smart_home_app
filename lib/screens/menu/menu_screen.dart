import 'package:flutter/material.dart';
import '../security/security_screen.dart';
import '../activities/activities_screen.dart';
import '../security/alarm_settings_screen.dart';
import 'settings_screen.dart';
import 'notifications_center_screen.dart';
import '../people/people_screen.dart';
import '../../widgets/smart_home_card.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      {
        'title': 'System Settings',
        'subtitle': 'Add devices & cloud filters',
        'icon': Icons.settings_applications_rounded,
        'color': Colors.purple.shade700,
        'screen': const SettingsScreen(),
      },
      {
        'title': 'Notifications',
        'subtitle': 'Recent activity center',
        'icon': Icons.notifications_active_rounded,
        'color': Colors.orange.shade700,
        'screen': const NotificationsCenterScreen(),
      },
      {
        'title': 'Security Panel',
        'subtitle': 'Armed modes & sensors',
        'icon': Icons.shield_outlined,
        'color': const Color(0xFF2E7D32),
        'screen': const SecurityScreen(),
      },
      {
        'title': 'Activity Records',
        'subtitle': 'Historical system log',
        'icon': Icons.assignment_outlined,
        'color': Colors.blue.shade700,
        'screen': const ActivitiesScreen(),
      },
      {
        'title': 'Alarm Settings',
        'subtitle': 'Speaker & RGB alerts',
        'icon': Icons.tune_outlined,
        'color': Colors.deepOrange.shade700,
        'screen': const AlarmSettingsScreen(),
      },
      {
        'title': 'People',
        'subtitle': 'Manage household access',
        'icon': Icons.people_outline_rounded,
        'color': Colors.teal.shade700,
        'screen': const PeopleScreen(),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Menu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: menuItems.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = menuItems[index];

          return SmartHomeCard(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => item['screen'] as Widget),
              );
            },
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: (item['color'] as Color).withValues(alpha: 0.1),
                child: Icon(item['icon'] as IconData, color: item['color'] as Color),
              ),
              title: Text(
                item['title'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(
                item['subtitle'] as String,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}
