import 'package:flutter/material.dart';
import '../../services/app_state.dart';
import '../../models/smart_notification.dart';
import '../../widgets/smart_home_card.dart';

class NotificationsCenterScreen extends StatefulWidget {
  const NotificationsCenterScreen({super.key});

  @override
  State<NotificationsCenterScreen> createState() => _NotificationsCenterScreenState();
}

class _NotificationsCenterScreenState extends State<NotificationsCenterScreen> {
  NotificationCategory? _selectedCategory; // null = All

  IconData _getCategoryIcon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.security:
        return Icons.security_rounded;
      case NotificationCategory.device:
        return Icons.devices_rounded;
      case NotificationCategory.people:
        return Icons.people_rounded;
      case NotificationCategory.system:
        return Icons.settings_suggest_rounded;
    }
  }

  Color _getCategoryColor(NotificationCategory category, Color activeColor) {
    switch (category) {
      case NotificationCategory.security:
        return Colors.red.shade700;
      case NotificationCategory.device:
        return activeColor;
      case NotificationCategory.people:
        return Colors.blue.shade700;
      case NotificationCategory.system:
        return Colors.orange.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, child) {
        final state = AppState();
        final allNotifications = state.notifications;
        final activeColor = state.activeThemeColor;

        final filteredNotifications = allNotifications.where((n) {
          if (_selectedCategory == null) return true;
          return n.category == _selectedCategory;
        }).toList();

        final filterChips = [
          {'label': 'ALL', 'category': null},
          {'label': 'SECURITY', 'category': NotificationCategory.security},
          {'label': 'DEVICES', 'category': NotificationCategory.device},
          {'label': 'PEOPLE', 'category': NotificationCategory.people},
          {'label': 'SYSTEM', 'category': NotificationCategory.system},
        ];

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Notification Center',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              if (allNotifications.any((n) => !n.isRead))
                TextButton(
                  onPressed: () {
                    state.markAllNotificationsAsRead();
                  },
                  child: Text(
                    'Mark all as read',
                    style: TextStyle(color: activeColor, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              // CATEGORY FILTER CHIPS ROW
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filterChips.length,
                  itemBuilder: (context, index) {
                    final chip = filterChips[index];
                    final cat = chip['category'] as NotificationCategory?;
                    final isSelected = _selectedCategory == cat;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(chip['label'] as String),
                        selected: isSelected,
                        selectedColor: activeColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),

              // NOTIFICATIONS LISTING
              Expanded(
                child: filteredNotifications.isEmpty
                    ? const Center(
                        child: Text('No notifications match filter.'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredNotifications.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final notification = filteredNotifications[index];
                          final house = state.houses.firstWhere(
                            (h) => h.id == notification.propertyId,
                            orElse: () => state.houses.first,
                          );

                          final categoryColor = _getCategoryColor(notification.category, activeColor);

                          return SmartHomeCard(
                            padding: EdgeInsets.zero,
                            color: notification.isRead ? null : activeColor.withValues(alpha: 0.05),
                            child: ListTile(
                              onTap: () {
                                state.markSingleNotificationAsRead(notification.id);
                              },
                              leading: CircleAvatar(
                                backgroundColor: categoryColor.withValues(alpha: 0.1),
                                child: Icon(
                                  _getCategoryIcon(notification.category),
                                  color: categoryColor,
                                  size: 20,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notification.title,
                                      style: TextStyle(
                                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (!notification.isRead)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: activeColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'NEW',
                                        style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(notification.body),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${house.name} • ${_formatTimestamp(notification.timestamp)}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime ts) {
    final now = DateTime.now();
    final difference = now.difference(ts);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${ts.day}/${ts.month}';
    }
  }
}
