import 'package:flutter/material.dart';
import '../../models/room.dart';
import '../../widgets/device_tile.dart';
import '../../services/app_state.dart';
import '../../widgets/smart_home_card.dart';
import '../devices/device_control_screen.dart';

class RoomScreen extends StatelessWidget {
  final Room room;

  const RoomScreen({
    super.key,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, child) {
        final state = AppState();
        final zones = state.zones.where((z) => z.roomId == room.id).toList();
        final roomDevices = state.devices.where((d) => d.roomId == room.id).toList();
        final lightDevices = roomDevices.where((d) => d.type == 'light').toList();
        final activeLights = lightDevices.where((d) => d.isOn).length;

        return Scaffold(
          appBar: AppBar(
            title: Text(room.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 1. PER-ROOM DISPLAY SUMMARY
              const Text('Room Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildRoomSummaryCard(context, state, activeLights),
              const SizedBox(height: 30),

              // 2. LIGHTING SCENES (Section 4.5)
              if (lightDevices.isNotEmpty) ...[
                const Text('Lighting Scenes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildLightingScenesRow(context, state),
                const SizedBox(height: 30),
              ],

              // 3. ZONES
              if (zones.isNotEmpty) ...[
                const Text('Functional Zones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildZonesRow(zones, roomDevices),
                const SizedBox(height: 30),
              ],

              // 4. PER-ROOM CONTROLS
              const Text('Room Devices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              roomDevices.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No devices in this room.')))
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: roomDevices.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemBuilder: (context, index) {
                        final device = roomDevices[index];
                        return Stack(
                          children: [
                            DeviceTile(
                              device: device,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (c) => DeviceControlScreen(device: device)),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Switch(
                                value: device.isOn,
                                activeColor: state.activeThemeColor,
                                onChanged: (val) => state.toggleDevice(device.id, val),
                              ),
                            )
                          ],
                        );
                      },
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoomSummaryCard(BuildContext context, AppState state, int activeLights) {
    return SmartHomeCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _summaryItem(Icons.thermostat_rounded, '${state.indoorTemp.toStringAsFixed(1)}°C', 'Temp', Colors.orange),
          _summaryItem(Icons.lightbulb_rounded, '$activeLights active', 'Lights', Colors.amber),
          _summaryItem(Icons.person_search_rounded, 'Detected', 'Presence', state.activeThemeColor),
          _summaryItem(Icons.sensor_window_rounded, 'Closed', 'Window', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildLightingScenesRow(BuildContext context, AppState state) {
    final scenes = [
      {'name': 'Relax', 'icon': Icons.self_improvement_rounded, 'color': Colors.orange},
      {'name': 'Movie', 'icon': Icons.movie_filter_rounded, 'color': Colors.deepPurple},
      {'name': 'Dinner', 'icon': Icons.restaurant_rounded, 'color': Colors.red},
      {'name': 'Night', 'icon': Icons.nights_stay_rounded, 'color': Colors.indigo},
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: scenes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final scene = scenes[index];
          return SmartHomeCard(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onTap: () {
              state.triggerLightingScene(scene['name'] as String);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Activating ${scene['name']}...')));
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(scene['icon'] as IconData, color: scene['color'] as Color),
                const SizedBox(height: 8),
                Text(scene['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildZonesRow(List<dynamic> zones, List<dynamic> roomDevices) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: zones.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final zone = zones[index];
          final zoneDevices = roomDevices.where((d) => d.zoneId == zone.id).length;
          return SmartHomeCard(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(zone.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('$zoneDevices devices', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summaryItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
