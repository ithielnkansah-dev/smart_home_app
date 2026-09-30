import 'package:flutter/material.dart';
import '../../services/app_state.dart';
import '../../widgets/smart_home_card.dart';

class IntegrationCenterScreen extends StatelessWidget {
  const IntegrationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final protocols = [
      {
        'name': 'Matter over Thread',
        'status': 'Active • Mesh Ready',
        'icon': Icons.hub_rounded,
        'devices': '4 Nodes',
      },
      {
        'name': '.NET 9 Cloud Relay',
        'status': 'Connected (${state.cloudBaseUrl})',
        'icon': Icons.cloud_done_rounded,
        'devices': '${state.devices.length} Synced',
      },
      {
        'name': 'Wi-Fi 6 Gateway',
        'status': 'Online • 2.4/5GHz',
        'icon': Icons.wifi_rounded,
        'devices': '8 Clients',
      },
      {
        'name': 'Bluetooth LE Mesh',
        'status': 'Scanning Proximity',
        'icon': Icons.bluetooth_searching_rounded,
        'devices': 'Nearby Active',
      },
      {
        'name': 'Zigbee 3.0 Bridge',
        'status': 'Online • Channel 15',
        'icon': Icons.settings_input_antenna_rounded,
        'devices': '3 Sensors',
      },
      {
        'name': 'MQTT Broker',
        'status': 'Connected • local.mqtt:1883',
        'icon': Icons.sync_alt_rounded,
        'devices': 'Telemetry Stream',
      },
      {
        'name': 'Modbus / BACnet Gateway',
        'status': 'Standby • BMS Ready',
        'icon': Icons.power_rounded,
        'devices': 'Meter / Inverter',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Integration Center', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Gateways & Protocol Connectors',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Normalized multi-protocol communication hub according to universal spec.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),
          ...protocols.map((p) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SmartHomeCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: isDark ? Colors.white24 : Colors.black12,
                    child: Icon(p['icon'] as IconData, color: isDark ? Colors.white : Colors.black87),
                  ),
                  title: Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(p['status'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      p['devices'] as String,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
