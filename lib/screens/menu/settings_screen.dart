import 'package:flutter/material.dart';
import '../../services/app_state.dart';
import '../../widgets/smart_home_card.dart';
import '../onboarding/guided_setup_screen.dart';
import 'permissions_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, child) {
        final state = AppState();

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'System Settings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // --- .NET 9 CLOUD RELAY ---
              const Text('.NET 9 Cloud Relay Infrastructure', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SmartHomeCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('.NET 9 Cloud Relay', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        state.isCloudConnected
                            ? 'Status: ONLINE (${state.cloudBaseUrl})'
                            : 'Status: OFFLINE (Local Only)',
                      ),
                      value: state.isCloudConnected,
                      activeColor: Colors.green,
                      secondary: Icon(Icons.cloud_queue_rounded, color: state.isCloudConnected ? Colors.blue : Colors.grey),
                      onChanged: (val) => state.toggleCloudConnection(val),
                    ),
                    if (!state.isCloudConnected)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Warning: Device toggles will fail while offline.',
                          style: TextStyle(color: Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    const Divider(),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          state.runCloudDiagnostic();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Running .NET 9 Cloud Relay diagnostic...')),
                          );
                        },
                        icon: const Icon(Icons.analytics_outlined, size: 18),
                        label: const Text('Run Connectivity Diagnostic', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- DEVICES ---
              const Text('Hardware & Connectivity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SmartHomeCard(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const GuidedSetupScreen())),
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.add_rounded, color: Colors.white),
                  ),
                  title: Text('Provision New Hardware', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('BLE Discovery & WiFi Handshake'),
                  trailing: Icon(Icons.chevron_right_rounded),
                ),
              ),
              const SizedBox(height: 12),
              SmartHomeCard(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const PermissionsScreen())),
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.orangeAccent,
                    child: Icon(Icons.security_rounded, color: Colors.white),
                  ),
                  title: Text('System Permissions', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Manage location, bluetooth, and network access'),
                  trailing: Icon(Icons.chevron_right_rounded),
                ),
              ),
              
              const SizedBox(height: 30),

              // --- PERSONALIZATION ---
              const Text('Appearance & Theme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SmartHomeCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('High contrast visual environment'),
                      value: state.isDarkMode,
                      activeColor: state.activeThemeColor,
                      onChanged: (val) => state.toggleDarkMode(),
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.palette_rounded, color: Colors.grey, size: 20),
                          SizedBox(width: 12),
                          Text('System Accent Color', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _colorOption(state, const Color(0xFF2E7D32)), // Green
                        _colorOption(state, const Color(0xFF1E88E5)), // Blue
                        _colorOption(state, const Color(0xFF7B1FA2)), // Purple
                        _colorOption(state, const Color(0xFFE53935)), // Red
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- NOTIFICATIONS ---
              const Text('Notification Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SmartHomeCard(
                child: Column(
                  children: [
                    _prefSwitch(state, 'Security Alerts', state.notifySecurity, (v) => state.updateNotificationPreferences(security: v, devices: state.notifyDevices, people: state.notifyPeople)),
                    const Divider(),
                    _prefSwitch(state, 'Device Activity', state.notifyDevices, (v) => state.updateNotificationPreferences(security: state.notifySecurity, devices: v, people: state.notifyPeople)),
                    const Divider(),
                    _prefSwitch(state, 'People & Access', state.notifyPeople, (v) => state.updateNotificationPreferences(security: state.notifySecurity, devices: state.notifyDevices, people: v)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _colorOption(AppState state, Color color) {
    bool isSelected = state.activeThemeColor.value == color.value;
    return GestureDetector(
      onTap: () => state.setThemeColor(color),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black54 : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            if (isSelected) BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2),
          ],
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
      ),
    );
  }

  Widget _prefSwitch(AppState state, String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      value: value,
      activeColor: state.activeThemeColor,
      onChanged: onChanged,
    );
  }
}
