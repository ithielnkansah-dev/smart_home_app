import 'package:flutter/material.dart';
import '../../services/app_state.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, child) {
        final state = AppState();
        final rawLogs = state.activities;

        final filteredLogs = rawLogs.where((log) {
          if (_selectedFilter == 'All') return true;
          if (_selectedFilter == 'Security') return log.toLowerCase().contains('security') || log.toLowerCase().contains('emergency') || log.toLowerCase().contains('passkey');
          if (_selectedFilter == 'Devices') return log.toLowerCase().contains('light') || log.toLowerCase().contains('ac') || log.toLowerCase().contains('door') || log.toLowerCase().contains('camera');
          if (_selectedFilter == 'Scenes') return log.toLowerCase().contains('scene') || log.toLowerCase().contains('mode');
          if (_selectedFilter == 'Relay Sync') return log.toLowerCase().contains('relay') || log.toLowerCase().contains('cloud');
          return true;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Activity Records',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              if (rawLogs.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded),
                  tooltip: 'Clear Log History',
                  onPressed: () {
                    state.activities.clear();
                    state.activities.add('System log history cleared.');
                    setState(() {});
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              // Category Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['All', 'Security', 'Devices', 'Scenes', 'Relay Sync'].map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : null)),
                          selected: isSelected,
                          selectedColor: state.activeThemeColor,
                          onSelected: (val) {
                            if (val) setState(() => _selectedFilter = filter);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const Divider(height: 1),

              // Activity Log List
              Expanded(
                child: filteredLogs.isEmpty
                    ? const Center(child: Text('No activity records for this filter.', style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: filteredLogs.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final logText = filteredLogs[index];
                          IconData logIcon = Icons.history_toggle_off_rounded;
                          Color iconColor = state.activeThemeColor;

                          if (logText.toLowerCase().contains('emergency') || logText.toLowerCase().contains('leak')) {
                            logIcon = Icons.warning_rounded;
                            iconColor = Colors.red;
                          } else if (logText.toLowerCase().contains('passkey') || logText.toLowerCase().contains('security')) {
                            logIcon = Icons.security_rounded;
                            iconColor = Colors.teal;
                          } else if (logText.toLowerCase().contains('relay') || logText.toLowerCase().contains('cloud')) {
                            logIcon = Icons.cloud_done_rounded;
                            iconColor = Colors.blue;
                          }

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: iconColor.withValues(alpha: 0.12),
                              child: Icon(logIcon, color: iconColor, size: 18),
                            ),
                            title: Text(
                              logText,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            trailing: Text(
                              'Recent',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
}
