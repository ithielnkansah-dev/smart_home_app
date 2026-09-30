import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_home_app/services/app_state.dart';
import '../../models/device.dart';
import '../../models/room.dart';
import '../../models/house.dart';
import '../../models/floor.dart';
import '../../widgets/smart_home_card.dart';

class GuidedSetupScreen extends StatefulWidget {
  const GuidedSetupScreen({super.key});

  @override
  State<GuidedSetupScreen> createState() => _GuidedSetupScreenState();
}

class _GuidedSetupScreenState extends State<GuidedSetupScreen> {
  int _currentStep = 0;
  bool _isSearching = true;
  List<Map<String, String>> _discoveredDevices = [];
  Map<String, String>? _selectedDevice;
  
  double _handshakeProgress = 0.0;
  double _otaProgress = 0.0;
  
  String _selectedHouse = '';
  String _selectedFloor = '';
  String _selectedRoom = '';
  final TextEditingController _deviceNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  void _startDiscovery() {
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _discoveredDevices = [
            {'name': 'Smart RGB Bulb X1', 'type': 'light'},
            {'name': 'Eco Thermostat Z', 'type': 'thermostat'},
            {'name': 'SafeLock Pro', 'type': 'lock'},
            {'name': 'HD Ultra Camera', 'type': 'camera'},
          ];
        });
      }
    });
  }

  void _startHandshake() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _handshakeProgress += 0.05;
        if (_handshakeProgress >= 1.0) {
          _handshakeProgress = 1.0;
          timer.cancel();
          Future.delayed(const Duration(milliseconds: 300), () {
            setState(() => _currentStep = 2);
            _startOTA();
          });
        }
      });
    });
  }

  void _startOTA() {
    Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _otaProgress += 0.04;
        if (_otaProgress >= 1.0) {
          _otaProgress = 1.0;
          timer.cancel();
          Future.delayed(const Duration(milliseconds: 300), () {
            setState(() {
              _currentStep = 3;
              if (_selectedDevice != null) {
                _deviceNameController.text = _selectedDevice!['name']!;
              }
            });
          });
        }
      });
    });
  }

  void _showCreateRoomDialog(BuildContext context, AppState state) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Room'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g. Patio, Office, Garage...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final houseObj = state.houses.firstWhere((h) => h.name == _selectedHouse, orElse: () => state.houses.first);
                final floorObj = state.floors.firstWhere((f) => f.name == _selectedFloor, orElse: () => state.floors.first);
                final newRoom = Room(
                  id: 'R${DateTime.now().millisecondsSinceEpoch}',
                  houseId: houseObj.id,
                  floorId: floorObj.id,
                  name: name,
                );
                state.addRoom(newRoom);
                setState(() => _selectedRoom = name);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = AppState().activeThemeColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guided Device Setup', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        controlsBuilder: (context, details) => const SizedBox.shrink(),
        steps: [
          Step(
            title: const Text('Discovery'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: _buildDiscoveryStep(activeColor),
          ),
          Step(
            title: const Text('Handshake'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: _buildHandshakeStep(activeColor),
          ),
          Step(
            title: const Text('Firmware'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content: _buildOTAStep(activeColor),
          ),
          Step(
            title: const Text('Setup'),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.indexed,
            content: _buildFinalSetupStep(activeColor),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryStep(Color activeColor) {
    return Column(
      children: [
        if (_isSearching) ...[
          const SizedBox(height: 40),
          CircularProgressIndicator(strokeWidth: 6, color: activeColor),
          const SizedBox(height: 20),
          const Text('Scanning for nearby signals...', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ] else ...[
          const Text('Select a device to begin provisioning:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ..._discoveredDevices.map((device) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: SmartHomeCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.bluetooth_searching_rounded, color: activeColor),
                title: Text(device['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Type: ${device['type']!.toUpperCase()}'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  setState(() {
                    _selectedDevice = device;
                    _deviceNameController.text = device['name']!;
                    _currentStep = 1;
                  });
                  _startHandshake();
                },
              ),
            ),
          )),
        ]
      ],
    );
  }

  Widget _buildHandshakeStep(Color activeColor) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Icon(Icons.vpn_lock_rounded, size: 60, color: activeColor),
        const SizedBox(height: 20),
        Text('Establishing Secure Handshake with ${_selectedDevice?['name']}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('Exchanging encryption keys...', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 30),
        LinearProgressIndicator(value: _handshakeProgress, color: activeColor, minHeight: 10),
      ],
    );
  }

  Widget _buildOTAStep(Color activeColor) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Icon(Icons.system_update_alt_rounded, size: 60, color: activeColor),
        const SizedBox(height: 20),
        const Text('Firmware Validation & OTA Update', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text('Downloading version 2.4.0 for ${_selectedDevice?['name']}...', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 30),
        LinearProgressIndicator(value: _otaProgress, color: activeColor, minHeight: 10),
        const SizedBox(height: 10),
        Text('${(_otaProgress * 100).round()}% Completed'),
      ],
    );
  }

  Widget _buildFinalSetupStep(Color activeColor) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, child) {
        final state = AppState();
        final houseOptions = state.houses.map((h) => h.name).toList();
        if (_selectedHouse.isEmpty && houseOptions.isNotEmpty) _selectedHouse = houseOptions.first;

        final houseObj = state.houses.firstWhere(
          (h) => h.name == _selectedHouse,
          orElse: () => state.houses.isNotEmpty ? state.houses.first : House(id: 'H001', name: 'My House', address: '123 Main St'),
        );

        final floorOptions = state.floors.where((f) => f.houseId == houseObj.id).map((f) => f.name).toList();
        if (!floorOptions.contains(_selectedFloor) && floorOptions.isNotEmpty) {
          _selectedFloor = floorOptions.first;
        }

        final floorObj = state.floors.firstWhere(
          (f) => f.name == _selectedFloor && f.houseId == houseObj.id,
          orElse: () => state.floors.isNotEmpty ? state.floors.first : Floor(id: 'F001', houseId: houseObj.id, name: 'Ground Floor'),
        );

        final roomOptions = state.rooms
            .where((r) => r.houseId == houseObj.id && r.floorId == floorObj.id)
            .map((r) => r.name)
            .toList();

        if (!roomOptions.contains(_selectedRoom)) {
          _selectedRoom = roomOptions.isNotEmpty ? roomOptions.first : '';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Almost ready!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 5),
            const Text('Configure device name and assign room location.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            // Custom Device Name Field
            TextField(
              controller: _deviceNameController,
              decoration: InputDecoration(
                labelText: 'Device Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            
            _DropdownField(
              label: 'Select Property',
              value: _selectedHouse,
              items: houseOptions,
              onChanged: (v) => setState(() {
                _selectedHouse = v!;
                _selectedFloor = '';
                _selectedRoom = '';
              }),
            ),
            const SizedBox(height: 12),
            _DropdownField(
              label: 'Select Floor',
              value: _selectedFloor,
              items: floorOptions,
              onChanged: (v) => setState(() {
                _selectedFloor = v!;
                _selectedRoom = '';
              }),
            ),
            const SizedBox(height: 12),
            _DropdownField(
              label: 'Select Room',
              value: _selectedRoom,
              items: roomOptions,
              onChanged: (v) => setState(() => _selectedRoom = v!),
            ),
            const SizedBox(height: 6),

            // Option to Create a New Room
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showCreateRoomDialog(context, state),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create New Room'),
              ),
            ),
            
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final houseObj = state.houses.firstWhere((h) => h.name == _selectedHouse, orElse: () => state.houses.first);
                  final floorObj = state.floors.firstWhere((f) => f.name == _selectedFloor, orElse: () => state.floors.first);
                  final roomObj = state.rooms.firstWhere((r) => r.name == _selectedRoom, orElse: () => state.rooms.first);

                  final name = _deviceNameController.text.trim().isEmpty ? _selectedDevice!['name']! : _deviceNameController.text.trim();
                  final hardwareId = _selectedDevice!['id'] ?? 'D${DateTime.now().millisecondsSinceEpoch}';

                  final newDevice = Device(
                    id: hardwareId,
                    name: name,
                    type: _selectedDevice!['type']!,
                    houseId: houseObj.id,
                    floorId: floorObj.id,
                    roomId: roomObj.id,
                    isOnline: true,
                    isOn: false,
                    status: _selectedDevice!['type'] == 'garage' ? 'Closed' : 'OFF',
                  );

                  state.addDevice(newDevice);
                  state.unprovisionedDevices.removeWhere((d) => d['name'] == _selectedDevice!['name'] && d['type'] == _selectedDevice!['type']);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Registered $name successfully!')),
                  );

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('FINISH & REGISTER', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        );
      },
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value.isEmpty ? null : value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }
}
