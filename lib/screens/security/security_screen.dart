import 'package:flutter/material.dart';
import '../../services/app_state.dart';
import '../../services/biometric_service.dart';
import '../../widgets/smart_home_card.dart';
import '../../models/security_alert.dart';
import '../../models/smart_notification.dart';
import 'alarm_settings_screen.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, child) {
        final state = AppState();
        final currentStatus = state.securityStatus;
        final activeColor = state.activeThemeColor;
        final alerts = state.activeAlerts;
        final isEmergency = state.isEmergencyMode;

        return Scaffold(
          backgroundColor: isEmergency ? Colors.red.shade900 : null,
          appBar: AppBar(
            title: const Text('Security & Telemetry', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(onPressed: () => state.addSimulatedLeak(), icon: const Icon(Icons.bug_report_outlined)),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. MASTER STATUS & EMERGENCY (Section 6.1, 6.5)
                _buildMasterStatus(state, currentStatus, activeColor, isEmergency),
                const SizedBox(height: 25),

                // 2. ACTIVE ALARM INDICATION (Section 6.3)
                if (alerts.isNotEmpty) ...[
                  const Text('Active Alarms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...alerts.map((a) => _buildAlarmBanner(context, a)),
                  const SizedBox(height: 25),
                ],

                // 3. CORE SECURITY MODES (Section 6.1)
                const Text('Security Modes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _modeBtn(context, state, 'Armed Stay', Icons.home_rounded, currentStatus == 'Armed Stay', activeColor),
                    const SizedBox(width: 10),
                    _modeBtn(context, state, 'Armed Away', Icons.flight_takeoff_rounded, currentStatus == 'Armed Away', activeColor),
                    const SizedBox(width: 10),
                    _modeBtn(context, state, 'Disarmed', Icons.lock_open_rounded, currentStatus == 'Disarmed', Colors.amber),
                  ],
                ),
                const SizedBox(height: 30),

                // 4. LIVE VIDEO TELEMETRY (Section 6.4)
                const Text('Live Video Monitoring', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildVideoTelemetry(context, activeColor),
                const SizedBox(height: 30),

                // 5. SENSOR OVERVIEW (Section 6.2)
                const Text('Security Sensors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildSensorList(state),
                const SizedBox(height: 30),

                // 6. TEMPORARY GUEST PASSKEYS (Section 7.2)
                SmartHomeCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Colors.black12,
                      child: Icon(Icons.key_rounded, color: Colors.black87),
                    ),
                    title: const Text('Temporary Guest Passkeys', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Issue time-boxed PIN codes for cleaners & visitors'),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => _showGuestPasskeyDialog(context, state),
                      child: const Text('Issue PIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // HARDWARE SETTINGS LINK
                SmartHomeCard(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AlarmSettingsScreen())),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.settings_input_component_rounded, color: activeColor),
                    title: const Text('Alarm Hardware Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMasterStatus(AppState state, String status, Color activeColor, bool isEmergency) {
    return SmartHomeCard(
      color: isEmergency ? Colors.red : (status == 'Disarmed' ? Colors.amber.withValues(alpha: 0.1) : activeColor.withValues(alpha: 0.1)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEmergency ? 'EMERGENCY' : status, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isEmergency ? Colors.white : (status == 'Disarmed' ? Colors.amber.shade900 : activeColor))),
                  Text(isEmergency ? 'Services Dispatched' : 'All subsystems secure.', style: TextStyle(color: isEmergency ? Colors.white70 : Colors.grey, fontSize: 12)),
                ],
              ),
              IconButton.filled(
                onPressed: () => state.triggerEmergency(),
                style: IconButton.styleFrom(backgroundColor: isEmergency ? Colors.white : Colors.red, foregroundColor: isEmergency ? Colors.red : Colors.white),
                icon: const Icon(Icons.emergency_rounded),
                padding: const EdgeInsets.all(16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmBanner(BuildContext context, SecurityAlert alert) {
    final isWaterLeak = alert.title.contains('LEAK');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SmartHomeCard(
        color: Colors.red.shade800,
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alert.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      Text('Location: ${alert.location} — Time: ${_formatTime(alert.timestamp)}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(onPressed: () => AppState().clearAlerts(), icon: const Icon(Icons.close, color: Colors.white, size: 18)),
              ],
            ),
            if (isWaterLeak) ...[
              const Divider(color: Colors.white24, height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Automated Mitigation:', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red.shade900,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    onPressed: () {
                      AppState().clearAlerts();
                      AppState().activities.insert(0, 'Mitigation Triggered: Main Water Shutoff Valve Closed.');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Main Water Shutoff Valve Closed automatically.')),
                      );
                    },
                    icon: const Icon(Icons.water_drop_outlined, size: 14),
                    label: const Text('Shut Off Main Water Valve', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoTelemetry(BuildContext context, Color activeColor) {
    return SmartHomeCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Icon(Icons.videocam_rounded, color: Colors.white24, size: 48)),
              ),
              // Telemetry Overlay
              Positioned(
                top: 15, left: 15,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                  child: const Row(
                    children: [
                      CircleAvatar(radius: 3, backgroundColor: Colors.red),
                      SizedBox(width: 6),
                      Text('LIVE • 1080p', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 15, right: 15,
                child: Text(_formatTime(DateTime.now()), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              ),
            ],
          ),
          ListTile(
            title: const Text('Front Porch Camera', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Human detection active • Perimeter clear'),
            trailing: Icon(Icons.fullscreen_rounded, color: activeColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorList(AppState state) {
    final sensors = [
      {'name': 'Front Door', 'status': 'Closed', 'icon': Icons.door_front_door_rounded},
      {'name': 'Living Window', 'status': 'Locked', 'icon': Icons.window_rounded},
      {'name': 'Motion (Garage)', 'status': 'Clear', 'icon': Icons.directions_run_rounded},
      {'name': 'Smoke Detector', 'status': 'Normal', 'icon': Icons.smoke_free_rounded},
    ];

    return Column(
      children: sensors.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SmartHomeCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(s['icon'] as IconData, color: Colors.grey, size: 20),
              const SizedBox(width: 15),
              Text(s['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(s['status'] as String, style: TextStyle(color: state.activeThemeColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _modeBtn(BuildContext context, AppState state, String label, IconData icon, bool active, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          if (label == 'Disarmed' && state.securityStatus != 'Disarmed') {
            final bool authenticated = await BiometricService().authenticate(
              context: context,
              reason: 'Scan fingerprint to disarm home alarm system',
              title: 'Disarm Security System',
            );
            if (authenticated) {
              state.changeSecurityStatus(label);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Security system disarmed successfully.')),
                );
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Disarm cancelled. Biometric verification required.')),
                );
              }
            }
          } else {
            state.changeSecurityStatus(label);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: active ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? Colors.transparent : Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: active ? Colors.white : Colors.grey),
              const SizedBox(height: 6),
              Text(label.split(' ').last, style: TextStyle(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  void _showGuestPasskeyDialog(BuildContext context, AppState state) {
    final nameController = TextEditingController(text: 'Cleaner / Visitor');
    String selectedValidity = '2 Hours';
    String generatedPin = '${(100000 + (DateTime.now().millisecondsSinceEpoch % 899999))}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Temporary Guest Passkey', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Visitor Name / Service',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                children: [
                  const Text('Generated PIN Passkey', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Text(
                    generatedPin,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4, color: Colors.black),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedValidity,
              decoration: const InputDecoration(
                labelText: 'Validity Window',
                border: OutlineInputBorder(),
              ),
              items: ['1 Hour', '2 Hours', 'Today (24 Hours)', 'Recurring Weekly'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (val) {
                if (val != null) selectedValidity = val;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            onPressed: () {
              final visitor = nameController.text.trim();
              state.activities.insert(0, 'Guest Passkey Issued: PIN $generatedPin for $visitor ($selectedValidity)');
              state.addNotification(SmartNotification(
                id: 'N${DateTime.now().millisecondsSinceEpoch}',
                title: 'Guest Passkey Created',
                body: 'PIN $generatedPin generated for $visitor valid for $selectedValidity.',
                timestamp: DateTime.now(),
                propertyId: state.selectedHouseId,
                category: NotificationCategory.security,
              ));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Guest Passkey $generatedPin issued for $visitor')),
              );
            },
            child: const Text('Issue Passkey'),
          ),
        ],
      ),
    );
  }
}
