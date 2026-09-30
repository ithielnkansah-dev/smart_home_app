import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/device.dart';
import '../../services/app_state.dart';
import '../../services/biometric_service.dart';
import '../../widgets/device_tile.dart';
import '../../widgets/smart_home_card.dart';

class DeviceControlScreen extends StatefulWidget {
  final Device device;

  const DeviceControlScreen({
    super.key,
    required this.device,
  });

  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  String _tvSource = 'HDMI 1';
  double _curtainPos = 1.0; // 1.0 = Open, 0.0 = Closed

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, child) {
        final state = AppState();
        final device = state.devices.firstWhere(
          (d) => d.id == widget.device.id,
          orElse: () => widget.device,
        );
        final activeColor = state.activeThemeColor;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          appBar: AppBar(
            title: Text(device.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: Icon(
                  device.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: device.isFavorite ? Colors.amber : null,
                ),
                onPressed: () => state.toggleDeviceFavorite(device.id),
                tooltip: 'Toggle Favorite',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 1. SLEEK MASTER HERO STATUS CARD
                _buildHeroCard(context, state, device, activeColor, isDark),
                const SizedBox(height: 20),

                // 2. WINDOW INTERLOCK EFFICIENCY WARNING FOR AC
                if (device.type == 'ac' && state.isWindowOpen && device.isOn)
                  _buildInterlockWarning(),

                // 3. RICH GRANULAR CONTROLS PER DEVICE TYPE
                _buildGranularControls(context, state, device, activeColor, isDark),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroCard(BuildContext context, AppState state, Device device, Color activeColor, bool isDark) {
    final hasImage = (device.imageUrl != null && device.imageUrl!.isNotEmpty) ||
                     (device.imagePath != null && device.imagePath!.isNotEmpty);
    final isOn = (device.type == 'garage' || device.type == 'gate' || device.type == 'window')
        ? device.status != 'Closed'
        : device.isOn;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Stack(
          children: [
            // Background Image if available
            if (hasImage) ...[
              Positioned.fill(child: _buildDeviceImage(device)),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // Content Overlay
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Row: Status Badge & Camera Picker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: device.isOnline
                              ? (isOn ? Colors.green.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2))
                              : Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 4,
                              backgroundColor: device.isOnline
                                  ? (isOn ? Colors.greenAccent : Colors.grey)
                                  : Colors.redAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              device.isOnline ? (isOn ? 'ACTIVE' : 'STANDBY') : 'OFFLINE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: device.isOnline
                                    ? (isOn ? (hasImage ? Colors.greenAccent : activeColor) : Colors.grey)
                                    : Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor: hasImage ? Colors.black45 : (isDark ? Colors.white12 : Colors.black12),
                        ),
                        onPressed: () => _pickImage(context, state, device.id),
                        icon: Icon(Icons.add_a_photo_rounded, size: 18, color: hasImage ? Colors.white : (isDark ? Colors.white : Colors.black87)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Center: Device Type Icon & Name
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: isOn ? activeColor.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.15),
                        child: Icon(
                          DeviceTile.getIconData(device.type),
                          size: 28,
                          color: isOn ? (hasImage ? Colors.white : activeColor) : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        device.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: hasImage ? Colors.white : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Bottom Power Toggle Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getDisplayStatus(device),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: hasImage ? (isOn ? Colors.greenAccent : Colors.white70) : (isOn ? activeColor : Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: device.isOn,
                        activeThumbColor: activeColor,
                        onChanged: (val) async {
                          final bool isSensitiveLock = device.type == 'lock' ||
                              device.type == 'garage' ||
                              device.type == 'gate' ||
                              device.name.toLowerCase().contains('safelock') ||
                              device.name.toLowerCase().contains('lock');

                          if (isSensitiveLock && val == true) {
                            final messenger = ScaffoldMessenger.of(context);
                            final bool authenticated = await BiometricService().authenticate(
                              context: context,
                              reason: 'Scan fingerprint to authorize ${device.name}',
                              title: 'Authorization Required',
                            );
                            if (!authenticated) {
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Action cancelled for ${device.name}. Biometric verification required.')),
                                );
                              }
                              return;
                            }
                          }
                          state.toggleDevice(device.id, val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterlockWarning() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SmartHomeCard(
        color: Colors.red.withValues(alpha: 0.1),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Window Open Efficiency Warning', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  Text('A window in this room is open. AC cooling is reduced to save power.', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGranularControls(BuildContext context, AppState state, Device device, Color activeColor, bool isDark) {
    switch (device.type.toLowerCase()) {
      case 'light':
        return _buildLightDetailControls(state, device, activeColor, isDark);
      case 'ac':
      case 'thermostat':
        return _buildHvacDetailControls(state, device, activeColor, isDark);
      case 'lock':
        return _buildLockDetailControls(state, device, activeColor, isDark);
      case 'camera':
      case 'doorbell':
        return _buildCameraDetailControls(state, device, activeColor, isDark);
      case 'tv':
        return _buildTvDetailControls(state, device, activeColor);
      case 'curtain':
      case 'blinds':
        return _buildCurtainDetailControls(state, device, activeColor);
      case 'window':
        return _buildWindowDetailControls(state, device, activeColor);
      case 'gate':
        return _buildGateDetailControls(state, device, activeColor);
      case 'water_tank':
      case 'water_pump':
      case 'water_valve':
        return _buildWaterDetailControls(state, device, activeColor);
      case 'solar':
      case 'battery':
      case 'ev_charger':
        return _buildEnergyDetailControls(state, device, activeColor);
      case 'smoke_detector':
      case 'gas_detector':
      case 'leak_sensor':
        return _buildSafetySensorDetailControls(state, device, activeColor);
      case 'sensor':
      case 'co2_sensor':
      case 'air_quality_sensor':
      case 'lux_sensor':
        return _buildEnvSensorDetailControls(state, device, activeColor);
      case 'fridge':
      case 'refrigerator':
      case 'washer':
      case 'dryer':
      case 'dishwasher':
      case 'oven':
      case 'microwave':
        return _buildApplianceDetailControls(state, device, activeColor);
      case 'speaker':
        return _buildSpeakerDetailControls(activeColor);
      case 'fan':
        return _buildFanDetailControls(state, device, activeColor);
      case 'vacuum':
        return _buildVacuumDetailControls(activeColor);
      case 'air_purifier':
        return _buildAirPurifierDetailControls(state, device, activeColor);
      default:
        return SmartHomeCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(DeviceTile.getIconData(device.type), color: activeColor),
            title: Text('${device.name} Controls', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Status: ${device.status} • Power: ${device.isOn ? "ON" : "OFF"}'),
          ),
        );
    }
  }

  // --- LIGHTING CONTROLS ---
  Widget _buildLightDetailControls(AppState state, Device device, Color activeColor, bool isDark) {
    final colors = [
      {'name': 'Warm White', 'color': Colors.amber},
      {'name': 'Cool White', 'color': Colors.lightBlueAccent},
      {'name': 'Sunset', 'color': Colors.deepOrange},
      {'name': 'Ocean', 'color': Colors.blue},
      {'name': 'Neon', 'color': Colors.purpleAccent},
      {'name': 'Emerald', 'color': Colors.greenAccent},
      {'name': 'Crimson', 'color': Colors.redAccent},
    ];

    final modes = [
      {'key': 'Standard', 'name': 'Standard', 'icon': Icons.lightbulb_outline_rounded},
      {'key': 'Circadian', 'name': 'Circadian', 'icon': Icons.wb_sunny_rounded},
      {'key': 'NightPath', 'name': 'Night Path', 'icon': Icons.bedtime_rounded},
      {'key': 'FocusTask', 'name': 'Focus', 'icon': Icons.center_focus_strong_rounded},
      {'key': 'Sync', 'name': 'Sync Mode', 'icon': Icons.music_note_rounded},
    ];

    return Column(
      children: [
        SmartHomeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Operating Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              SizedBox(
                height: 70,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: modes.map((m) {
                    final isSelected = device.lightingMode == m['key'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          state.updateDeviceLightingMode(device.id, m['key'] as String);
                        },
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected ? activeColor : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(m['icon'] as IconData, color: isSelected ? Colors.white : Colors.grey, size: 20),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              m['name'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? activeColor : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SmartHomeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Brightness Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('${(device.brightness * 100).round()}%', style: TextStyle(fontWeight: FontWeight.bold, color: activeColor)),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: device.brightness.clamp(0.0, 1.0),
                activeColor: activeColor,
                onChanged: (val) => state.updateDeviceBrightness(device.id, val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SmartHomeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Color Temperature (Kelvin)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('${device.kelvinTemp}K', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade800)),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: device.kelvinTemp.toDouble().clamp(2200.0, 6500.0),
                min: 2200.0,
                max: 6500.0,
                divisions: 43,
                activeColor: Colors.amber.shade700,
                label: '${device.kelvinTemp}K',
                onChanged: (val) => state.updateDeviceKelvinTemp(device.id, val.round()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SmartHomeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Color Palette & Presets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: colors.map((c) {
                  final Color col = c['color'] as Color;
                  return GestureDetector(
                    onTap: () {
                      state.updateDeviceColor(device.id, col.toARGB32());
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Light color set to ${c['name']}')),
                      );
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: col,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- MOTORIZED WINDOW CONTROLS ---
  Widget _buildWindowDetailControls(AppState state, Device device, Color activeColor) {
    return Column(
      children: [
        SmartHomeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Opening Position', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('${(device.openPercentage * 100).round()}% Open', style: TextStyle(fontWeight: FontWeight.bold, color: activeColor)),
                ],
              ),
              const SizedBox(height: 10),
              Slider(
                value: device.openPercentage.clamp(0.0, 1.0),
                activeColor: activeColor,
                onChanged: (val) {
                  device.openPercentage = val;
                  device.status = val > 0 ? '${(val * 100).round()}% Open' : 'Closed';
                  state.notifyListeners();
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      device.openPercentage = 0.0;
                      device.status = 'Closed';
                      device.isOn = false;
                      state.notifyListeners();
                    },
                    child: const Text('CLOSE'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      device.openPercentage = 0.5;
                      device.status = '50% Open';
                      device.isOn = true;
                      state.notifyListeners();
                    },
                    child: const Text('VENTILATE 50%'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      device.openPercentage = 1.0;
                      device.status = 'Open';
                      device.isOn = true;
                      state.notifyListeners();
                    },
                    child: const Text('FULL OPEN'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SmartHomeCard(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Rain Auto-Close Protection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Automatically closes window when rain is detected'),
                value: device.rainProtection,
                activeThumbColor: activeColor,
                onChanged: (val) {
                  device.rainProtection = val;
                  state.notifyListeners();
                },
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Temperature-Based Ventilation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Opens partially when indoor temp exceeds 26°C'),
                value: device.tempVentilation,
                activeThumbColor: activeColor,
                onChanged: (val) {
                  device.tempVentilation = val;
                  state.notifyListeners();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- MOTORIZED GATE CONTROLS ---
  Widget _buildGateDetailControls(AppState state, Device device, Color activeColor) {
    return Column(
      children: [
        SmartHomeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Motorized Gate Position', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(device.status.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: activeColor)),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: () {
                      device.status = 'Open';
                      device.isOn = true;
                      state.notifyListeners();
                    },
                    icon: const Icon(Icons.sensor_door_outlined),
                    label: const Text('OPEN GATE'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white),
                    onPressed: () {
                      device.status = 'Stopped';
                      state.notifyListeners();
                    },
                    icon: const Icon(Icons.pause_rounded),
                    label: const Text('STOP'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                    onPressed: () {
                      device.status = 'Closed';
                      device.isOn = false;
                      state.notifyListeners();
                    },
                    icon: const Icon(Icons.sensor_door_rounded),
                    label: const Text('CLOSE'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- WATER MANAGEMENT CONTROLS ---
  Widget _buildWaterDetailControls(AppState state, Device device, Color activeColor) {
    return Column(
      children: [
        SmartHomeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Water Tank Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('${device.waterLevelPercentage.round()}% Full', style: TextStyle(fontWeight: FontWeight.bold, color: activeColor)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: device.waterLevelPercentage / 100.0,
                  minHeight: 16,
                  color: Colors.blue,
                  backgroundColor: Colors.blue.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SmartHomeCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.water_drop_rounded, color: Colors.white)),
                title: const Text('Main Shutoff Valve', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(device.isValveOpen ? 'Status: OPEN (Water Flowing)' : 'Status: CLOSED (Emergency Shutoff)'),
                trailing: Switch(
                  value: device.isValveOpen,
                  activeThumbColor: Colors.green,
                  onChanged: (val) {
                    device.isValveOpen = val;
                    device.status = val ? 'Valve Open' : 'Valve Closed';
                    state.notifyListeners();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- ENERGY, SOLAR, BATTERY & EV CONTROLS ---
  Widget _buildEnergyDetailControls(AppState state, Device device, Color activeColor) {
    return Column(
      children: [
        SmartHomeCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.solar_power_rounded, color: Colors.amber, size: 32),
                      const SizedBox(height: 4),
                      Text('${device.pvPowerKw} kW', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const Text('PV Power', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  Column(
                    children: [
                      const Icon(Icons.battery_charging_full_rounded, color: Colors.green, size: 32),
                      const SizedBox(height: 4),
                      Text('${device.batterySocPercentage.round()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const Text('Battery SoC', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  Column(
                    children: [
                      const Icon(Icons.ev_station_rounded, color: Colors.blue, size: 32),
                      const SizedBox(height: 4),
                      Text('${device.evChargingPowerKw} kW', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const Text('EV Charging', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- SAFETY & GAS SENSORS CONTROLS ---
  Widget _buildSafetySensorDetailControls(AppState state, Device device, Color activeColor) {
    final isAlarm = device.smokeDetected || device.gasDetected || device.waterLeakDetected;

    return Column(
      children: [
        SmartHomeCard(
          color: isAlarm ? Colors.red.shade900 : null,
          child: Column(
            children: [
              Icon(isAlarm ? Icons.warning_rounded : Icons.check_circle_rounded, size: 48, color: isAlarm ? Colors.white : Colors.green),
              const SizedBox(height: 10),
              Text(
                isAlarm ? 'DANGER DETECTED' : 'NORMAL / SECURE',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isAlarm ? Colors.white : Colors.green),
              ),
              const SizedBox(height: 6),
              Text(
                'Sensor telemetry monitored 24/7 by Cloud Relay.',
                style: TextStyle(fontSize: 11, color: isAlarm ? Colors.white70 : Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- ENVIRONMENTAL SENSORS CONTROLS ---
  Widget _buildEnvSensorDetailControls(AppState state, Device device, Color activeColor) {
    return Column(
      children: [
        SmartHomeCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('CO₂', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('${device.co2Ppm} ppm', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              Column(
                children: [
                  const Text('AQI', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('${device.aqi}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: device.aqi < 50 ? Colors.green : Colors.orange)),
                ],
              ),
              Column(
                children: [
                  const Text('Lux', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('${device.luxLevel.round()} lx', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- SMART APPLIANCES CONTROLS ---
  Widget _buildApplianceDetailControls(AppState state, Device device, Color activeColor) {
    return Column(
      children: [
        SmartHomeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Operating Program', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(device.applianceProgram, style: TextStyle(fontWeight: FontWeight.bold, color: activeColor)),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['Eco Normal', 'Heavy Clean', 'Express 30m'].map((prog) {
                  final isSelected = device.applianceProgram == prog;
                  return ChoiceChip(
                    label: Text(prog),
                    selected: isSelected,
                    selectedColor: activeColor,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : null),
                    onSelected: (val) {
                      device.applianceProgram = prog;
                      state.notifyListeners();
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- HVAC CONTROLS ---
  Widget _buildHvacDetailControls(AppState state, Device device, Color activeColor, bool isDark) {
    final hvacModes = [
      {'key': 'Cool', 'name': 'Cool', 'icon': Icons.ac_unit_rounded, 'color': Colors.blue},
      {'key': 'Heat', 'name': 'Heat', 'icon': Icons.wb_sunny_rounded, 'color': Colors.orange},
      {'key': 'Dry', 'name': 'Dry', 'icon': Icons.water_drop_rounded, 'color': Colors.teal},
      {'key': 'Eco', 'name': 'Eco Saver', 'icon': Icons.eco_rounded, 'color': Colors.green},
      {'key': 'Sleep', 'name': 'Sleep', 'icon': Icons.bedtime_rounded, 'color': Colors.indigo},
    ];

    return Column(
      children: [
        SmartHomeCard(
          child: Column(
            children: [
              const Text('Target Temperature', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: () => state.updateDeviceTargetTemp(device.id, (device.targetTemp - 1).clamp(16, 30)),
                    icon: const Icon(Icons.remove_rounded, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    '${device.targetTemp.round()}°C',
                    style: TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: activeColor),
                  ),
                  const SizedBox(width: 20),
                  IconButton.filledTonal(
                    onPressed: () => state.updateDeviceTargetTemp(device.id, (device.targetTemp + 1).clamp(16, 30)),
                    icon: const Icon(Icons.add_rounded, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Slider(
                value: device.targetTemp.clamp(16.0, 30.0),
                min: 16.0,
                max: 30.0,
                divisions: 14,
                activeColor: activeColor,
                label: '${device.targetTemp.round()}°C',
                onChanged: (val) => state.updateDeviceTargetTemp(device.id, val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SmartHomeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('HVAC Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: hvacModes.map((m) {
                  final isSelected = device.hvacMode == m['key'];
                  final Color c = m['color'] as Color;
                  return GestureDetector(
                    onTap: () => state.updateDeviceHvacMode(device.id, m['key'] as String),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? c : c.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(m['icon'] as IconData, color: isSelected ? Colors.white : c, size: 22),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          m['name'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? c : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SmartHomeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Fan Speed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['Low', 'Medium', 'High', 'Auto'].map((speed) {
                  bool selected = device.fanSpeed == speed;
                  return ChoiceChip(
                    label: Text(speed),
                    selected: selected,
                    selectedColor: activeColor,
                    labelStyle: TextStyle(color: selected ? Colors.white : null),
                    onSelected: (val) => state.updateDeviceFanSpeed(device.id, speed),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- SMART LOCK CONTROLS ---
  Widget _buildLockDetailControls(AppState state, Device device, Color activeColor, bool isDark) {
    final isLocked = device.status == 'Locked' || device.isLocked;

    return Column(
      children: [
        SmartHomeCard(
          child: Column(
            children: [
              Icon(
                isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                size: 60,
                color: isLocked ? Colors.green : Colors.amber.shade800,
              ),
              const SizedBox(height: 12),
              Text(
                isLocked ? 'DOOR LOCKED' : 'DOOR UNLOCKED',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isLocked ? Colors.green : Colors.amber.shade800,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLocked ? Colors.red.shade700 : Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (isLocked) {
                      final messenger = ScaffoldMessenger.of(context);
                      final bool authenticated = await BiometricService().authenticate(
                        context: context,
                        reason: 'Scan fingerprint to unlock ${device.name}',
                        title: 'High-Security Door Unlock',
                      );
                      if (!authenticated) {
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Unlock cancelled for ${device.name}. Biometric verification required.')),
                          );
                        }
                        return;
                      }
                    }

                    device.isLocked = !isLocked;
                    device.status = device.isLocked ? 'Locked' : 'Unlocked';
                    state.toggleDevice(device.id, !isLocked);
                  },
                  icon: Icon(isLocked ? Icons.lock_open_rounded : Icons.lock_rounded),
                  label: Text(isLocked ? 'UNLOCK DOOR' : 'LOCK DOOR', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SmartHomeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Access Control Modes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['AutoLock', 'Lockdown', 'Party'].map((m) {
                  bool selected = device.lockMode == m;
                  return ChoiceChip(
                    label: Text(m),
                    selected: selected,
                    selectedColor: activeColor,
                    labelStyle: TextStyle(color: selected ? Colors.white : null),
                    onSelected: (val) => state.updateDeviceLockMode(device.id, m),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- CAMERA CONTROLS ---
  Widget _buildCameraDetailControls(AppState state, Device device, Color activeColor, bool isDark) {
    return Column(
      children: [
        SmartHomeCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.videocam_rounded, color: Colors.white38, size: 48),
                          SizedBox(height: 8),
                          Text('1080p HD Live Stream', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                      child: const Row(
                        children: [
                          CircleAvatar(radius: 3, backgroundColor: Colors.red),
                          SizedBox(width: 6),
                          Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _CamAction(icon: Icons.mic_rounded, label: 'Talk'),
                    _CamAction(icon: Icons.fiber_manual_record_rounded, label: 'Record'),
                    _CamAction(icon: Icons.screenshot_rounded, label: 'Snapshot'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- TV / MEDIA CONTROLS ---
  Widget _buildTvDetailControls(AppState state, Device device, Color activeColor) {
    return Column(
      children: [
        SmartHomeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Source Input', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['HDMI 1', 'HDMI 2', 'Cable TV', 'Netflix', 'YouTube'].map((src) {
                  bool selected = _tvSource == src;
                  return ChoiceChip(
                    label: Text(src),
                    selected: selected,
                    selectedColor: activeColor,
                    labelStyle: TextStyle(color: selected ? Colors.white : null),
                    onSelected: (val) {
                      if (val) setState(() => _tvSource = src);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- CURTAIN / BLINDS CONTROLS ---
  Widget _buildCurtainDetailControls(AppState state, Device device, Color activeColor) {
    double currentPos = device.openPercentage.clamp(0.0, 1.0);

    return Column(
      children: [
        SmartHomeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Curtain / Blind Position', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(
                    '${(currentPos * 100).round()}% Open',
                    style: TextStyle(fontWeight: FontWeight.bold, color: activeColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Slider(
                value: currentPos,
                activeColor: activeColor,
                onChanged: (val) {
                  device.openPercentage = val;
                  device.isOn = val > 0;
                  device.status = val == 0 ? 'Closed' : '${(val * 100).round()}% Open';
                  state.notifyListeners();
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                    onPressed: () {
                      device.openPercentage = 0.0;
                      device.isOn = false;
                      device.status = 'Closed';
                      state.notifyListeners();
                    },
                    icon: const Icon(Icons.blinds_closed_rounded, size: 16),
                    label: const Text('CLOSE'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white),
                    onPressed: () {
                      device.openPercentage = 0.5;
                      device.isOn = true;
                      device.status = '50% Open';
                      state.notifyListeners();
                    },
                    icon: const Icon(Icons.blinds_rounded, size: 16),
                    label: const Text('50% HALF'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: () {
                      device.openPercentage = 1.0;
                      device.isOn = true;
                      device.status = 'Open';
                      state.notifyListeners();
                    },
                    icon: const Icon(Icons.sensor_door_outlined, size: 16),
                    label: const Text('OPEN'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SmartHomeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Automations & Operating Modes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['Manual', 'SolarTracking', 'Privacy'].map((m) {
                  bool selected = device.blindMode == m;
                  return ChoiceChip(
                    label: Text(m),
                    selected: selected,
                    selectedColor: activeColor,
                    labelStyle: TextStyle(color: selected ? Colors.white : null),
                    onSelected: (val) => state.updateDeviceBlindMode(device.id, m),
                  );
                }).toList(),
              ),
              const Divider(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Silent Acoustic Motor Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('Reduces motor speed for ultra-quiet night opening'),
                value: device.silentAcousticMode,
                activeThumbColor: activeColor,
                onChanged: (val) {
                  device.silentAcousticMode = val;
                  state.notifyListeners();
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Storm & Wind Protection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('Auto closes during high wind or stormy weather'),
                value: device.stormProtection,
                activeThumbColor: activeColor,
                onChanged: (val) {
                  device.stormProtection = val;
                  state.notifyListeners();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- SPEAKER CONTROLS ---
  Widget _buildSpeakerDetailControls(Color activeColor) {
    return SmartHomeCard(
      child: Column(
        children: [
          const Icon(Icons.music_note_rounded, size: 48, color: Colors.purple),
          const SizedBox(height: 10),
          const Text('Now Playing', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const Text('Ambient Smart Home Symphony', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.skip_previous_rounded, size: 36)),
              const SizedBox(width: 20),
              CircleAvatar(
                radius: 28,
                backgroundColor: activeColor,
                child: const Icon(Icons.pause_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 20),
              IconButton(onPressed: () {}, icon: const Icon(Icons.skip_next_rounded, size: 36)),
            ],
          ),
        ],
      ),
    );
  }

  // --- FAN CONTROLS ---
  Widget _buildFanDetailControls(AppState state, Device device, Color activeColor) {
    return SmartHomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fan Speed Setting', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Low', 'Medium', 'High', 'Auto'].map((speed) {
              bool selected = device.fanSpeed == speed;
              return ChoiceChip(
                label: Text(speed),
                selected: selected,
                selectedColor: activeColor,
                labelStyle: TextStyle(color: selected ? Colors.white : null),
                onSelected: (val) => state.updateDeviceFanSpeed(device.id, speed),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- VACUUM CONTROLS ---
  Widget _buildVacuumDetailControls(Color activeColor) {
    return SmartHomeCard(
      child: Column(
        children: [
          const Icon(Icons.cleaning_services_rounded, size: 48, color: Colors.blue),
          const SizedBox(height: 10),
          const Text('Robot Vacuum Status: Ready', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  // --- AIR PURIFIER CONTROLS ---
  Widget _buildAirPurifierDetailControls(AppState state, Device device, Color activeColor) {
    return SmartHomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Air Quality Index (AQI)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('18 • Excellent', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  String _getDisplayStatus(Device device) {
    if (device.type == 'garage' || device.type == 'gate' || device.type == 'window') {
      return device.status.toUpperCase();
    }
    if (device.type == 'sensor') return device.isOnline ? "MONITORING" : "OFFLINE";
    return device.isOn ? 'ON' : 'OFF';
  }

  Widget _buildDeviceImage(Device device) {
    if (device.imageUrl != null && device.imageUrl!.isNotEmpty) {
      return Image.network(device.imageUrl!, fit: BoxFit.cover);
    } else if (device.imagePath != null && device.imagePath!.isNotEmpty) {
      return Image.file(File(device.imagePath!), fit: BoxFit.cover);
    }
    return const SizedBox.shrink();
  }

  Future<void> _pickImage(BuildContext context, AppState state, String deviceId) async {
    final ImagePicker picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.photo_library_rounded), title: const Text('Gallery'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
            ListTile(leading: const Icon(Icons.camera_alt_rounded), title: const Text('Camera'), onTap: () => Navigator.pop(context, ImageSource.camera)),
          ],
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        state.updateDeviceImage(deviceId, path: image.path);
      }
    }
  }
}

class _CamAction extends StatelessWidget {
  final IconData icon; final String label;
  const _CamAction({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
