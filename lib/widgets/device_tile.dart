import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/device.dart';
import '../services/app_state.dart';
import '../services/biometric_service.dart';
import 'smart_home_card.dart';

class DeviceTile extends StatelessWidget {
  final Device device;
  final VoidCallback onTap;

  const DeviceTile({
    super.key,
    required this.device,
    required this.onTap,
  });

  static IconData getIconData(String type) {
    switch (type.toLowerCase()) {
      case 'light':
        return Icons.lightbulb_rounded;
      case 'ac':
        return Icons.ac_unit_rounded;
      case 'window':
        return Icons.window_rounded;
      case 'fridge':
      case 'refrigerator':
        return Icons.kitchen_rounded;
      case 'lock':
        return Icons.lock_rounded;
      case 'camera':
        return Icons.videocam_rounded;
      case 'sensor':
        return Icons.sensors_rounded;
      case 'co2_sensor':
        return Icons.co2_rounded;
      case 'air_quality_sensor':
        return Icons.air_rounded;
      case 'lux_sensor':
        return Icons.wb_sunny_rounded;
      case 'tv':
        return Icons.tv_rounded;
      case 'curtain':
      case 'blinds':
        return Icons.blinds_rounded;
      case 'garage':
        return Icons.garage_rounded;
      case 'gate':
        return Icons.fence_rounded;
      case 'speaker':
        return Icons.speaker_rounded;
      case 'thermostat':
        return Icons.thermostat_rounded;
      case 'fan':
        return Icons.toys_rounded;
      case 'air_purifier':
        return Icons.air_rounded;
      case 'vacuum':
        return Icons.cleaning_services_rounded;
      case 'oven':
        return Icons.microwave_rounded;
      case 'dishwasher':
        return Icons.flatware_rounded;
      case 'washer':
        return Icons.wash_rounded;
      case 'dryer':
        return Icons.dry_rounded;
      case 'outlet':
        return Icons.outlet_rounded;
      case 'doorbell':
        return Icons.doorbell_rounded;
      case 'smoke_detector':
        return Icons.smoke_free_rounded;
      case 'gas_detector':
        return Icons.gas_meter_rounded;
      case 'leak_sensor':
        return Icons.water_damage_rounded;
      case 'water_tank':
        return Icons.water_rounded;
      case 'water_pump':
        return Icons.invert_colors_rounded;
      case 'water_valve':
        return Icons.water_drop_rounded;
      case 'router':
        return Icons.router_rounded;
      case 'solar':
        return Icons.solar_power_rounded;
      case 'battery':
        return Icons.battery_charging_full_rounded;
      case 'ev_charger':
        return Icons.ev_station_rounded;
      case 'sprinkler':
        return Icons.water_drop_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }

  Widget? _buildBackgroundImage(Device device) {
    if (device.imagePath != null && device.imagePath!.isNotEmpty) {
      final file = File(device.imagePath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      }
    }
    if (device.imageUrl != null && device.imageUrl!.isNotEmpty) {
      return Image.network(
        device.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      );
    }
    return null;
  }

  void _showImageOptionsDialog(BuildContext context, String deviceId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Set Background Picture',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.photo_library_rounded, color: Colors.white, size: 20),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    AppState().updateDeviceImage(deviceId, path: image.path);
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                ),
                title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    AppState().updateDeviceImage(deviceId, path: image.path);
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.purpleAccent,
                  child: Icon(Icons.link_rounded, color: Colors.white, size: 20),
                ),
                title: const Text('Enter Image URL', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _showUrlInputDialog(context, deviceId);
                },
              ),
              if (device.imagePath != null || device.imageUrl != null)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                  ),
                  title: const Text('Remove Picture', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(context);
                    AppState().updateDeviceImage(deviceId, path: null, url: null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUrlInputDialog(BuildContext context, String deviceId) {
    final controller = TextEditingController(text: device.imageUrl ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Image URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://images.unsplash.com/...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = controller.text.trim();
              AppState().updateDeviceImage(deviceId, url: url.isEmpty ? null : url);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    final activeColor = Theme.of(context).colorScheme.primary;
    final isOnline = device.isOnline;
    final isOn = device.type == 'garage' ? device.status != 'Closed' : device.isOn;
    final hasImage = (device.imagePath != null && device.imagePath!.isNotEmpty) ||
                     (device.imageUrl != null && device.imageUrl!.isNotEmpty);

    Color statusColor = Colors.grey;
    if (device.type == 'garage' || device.type == 'gate' || device.type == 'window') {
      if (device.status == 'Open') statusColor = Colors.orange;
      if (device.status == 'Closed') statusColor = activeColor;
      if (device.status == 'Moving') statusColor = Colors.blue;
    } else {
      if (isOn) statusColor = activeColor;
    }

    final bgImg = _buildBackgroundImage(device);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              // 1. FULL BACKGROUND IMAGE OR SOLID CARD
              if (hasImage && bgImg != null) ...[
                Positioned.fill(child: bgImg),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Positioned.fill(
                  child: SmartHomeCard(
                    padding: EdgeInsets.zero,
                    child: const SizedBox.expand(),
                  ),
                ),
              ],

              // 2. CARD CONTENT & BUTTONS OVERLAY WRAPPED IN POSITIONED.FILL & EXPANDED
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TOP ROW: Icon, Camera/Image Picker, Wifi
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: hasImage
                                  ? Colors.black45
                                  : (isOn ? activeColor.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.12)),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              getIconData(device.type),
                              color: hasImage ? Colors.white : (isOn ? activeColor : Colors.grey),
                              size: 16,
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _showImageOptionsDialog(context, device.id),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: hasImage ? Colors.black45 : Colors.grey.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add_a_photo_rounded,
                                    size: 12,
                                    color: hasImage ? Colors.white : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                isOnline ? Icons.wifi : Icons.wifi_off,
                                size: 12,
                                color: hasImage
                                    ? (isOnline ? Colors.greenAccent : Colors.redAccent)
                                    : (isOnline ? activeColor.withValues(alpha: 0.6) : Colors.red.withValues(alpha: 0.6)),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // EXPANDED SPACER TO ABSORB EXTRA VERTICAL SPACE FLEXIBLY
                      const Expanded(child: SizedBox.shrink()),

                      // BOTTOM ROW: Name, Status, Power Toggle Button
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            device.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: hasImage ? Colors.white : null,
                              shadows: hasImage
                                  ? const [Shadow(color: Colors.black, blurRadius: 6)]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                (device.type == 'garage' || device.type == 'gate' || device.type == 'window')
                                    ? device.status.toUpperCase()
                                    : (isOn ? 'ON' : 'OFF'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: hasImage
                                      ? (isOn ? Colors.greenAccent : Colors.white70)
                                      : statusColor,
                                  shadows: hasImage
                                      ? const [Shadow(color: Colors.black, blurRadius: 6)]
                                      : null,
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  final bool isSensitiveLock = device.type == 'lock' ||
                                      device.type == 'garage' ||
                                      device.type == 'gate' ||
                                      device.name.toLowerCase().contains('safelock') ||
                                      device.name.toLowerCase().contains('lock');

                                  final bool isUnlocking = !device.isOn || device.isLocked || device.status == 'Locked' || device.status == 'Closed';

                                  if (isSensitiveLock && isUnlocking) {
                                    final bool authenticated = await BiometricService().authenticate(
                                      context: context,
                                      reason: 'Scan fingerprint to authorize ${device.name}',
                                      title: 'Action Authorization',
                                    );
                                    if (!authenticated) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Action cancelled for ${device.name}. Biometric verification required.')),
                                        );
                                      }
                                      return;
                                    }
                                  }

                                  appState.toggleDevice(device.id, !device.isOn);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isOn ? activeColor : (hasImage ? Colors.white24 : Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: isOn
                                        ? [BoxShadow(color: activeColor.withValues(alpha: 0.4), blurRadius: 6)]
                                        : null,
                                  ),
                                  child: Text(
                                    isOn ? 'ON' : 'OFF',
                                    style: TextStyle(
                                      color: isOn ? Colors.white : (hasImage ? Colors.white : Colors.black87),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
