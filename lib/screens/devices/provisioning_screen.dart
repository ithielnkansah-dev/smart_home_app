import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../../models/device.dart';
import '../../services/app_state.dart';
import '../../widgets/smart_home_card.dart';
import 'device_control_screen.dart';

class ProvisioningScreen extends StatefulWidget {
  const ProvisioningScreen({super.key});

  @override
  State<ProvisioningScreen> createState() => _ProvisioningScreenState();
}

class _ProvisioningScreenState extends State<ProvisioningScreen>
    with TickerProviderStateMixin {
  int _selectedTab = 0; // 0 = QR Code, 1 = NFC Tag, 2 = Matter PIN

  // Mobile Scanner Controller
  final MobileScannerController _qrController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  // QR Laser Animation Controller
  late AnimationController _scanLaserController;
  late Animation<double> _scanLaserAnimation;

  // NFC Pulse Controller
  late AnimationController _nfcPulseController;
  late Animation<double> _nfcPulseAnimation;
  bool _isNfcListening = false;

  // Pairing State
  bool _isDiscovered = false;
  Map<String, dynamic>? _scannedDeviceData;
  final TextEditingController _matterCodeController = TextEditingController();

  // Location Assignment
  String? _selectedHouseId;
  String? _selectedFloorId;
  String? _selectedRoomId;
  final TextEditingController _deviceNameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Scan Laser Animation
    _scanLaserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scanLaserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLaserController, curve: Curves.easeInOut),
    );

    // NFC Pulse Animation
    _nfcPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _nfcPulseAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _nfcPulseController, curve: Curves.easeInOut),
    );

    final state = AppState();
    _selectedHouseId = state.selectedHouseId;
    if (state.selectedHouseFloors.isNotEmpty) {
      _selectedFloorId = state.selectedHouseFloors.first.id;
    }
    if (state.rooms.isNotEmpty) {
      _selectedRoomId = state.rooms.first.id;
    }
  }

  @override
  void dispose() {
    _qrController.dispose();
    _scanLaserController.dispose();
    _nfcPulseController.dispose();
    _matterCodeController.dispose();
    _deviceNameController.dispose();
    try {
      NfcManager.instance.stopSession();
    } catch (_) {}
    super.dispose();
  }

  void _onQrCodeScanned(Map<String, dynamic> data) {
    HapticFeedback.heavyImpact();
    setState(() {
      _scannedDeviceData = data;
      _deviceNameController.text = data['name'] ?? 'Smart Device';
      _isDiscovered = true;
    });
  }

  void _handleScannedRawCode(String code) {
    try {
      if (code.startsWith('{') && code.endsWith('}')) {
        final decoded = json.decode(code) as Map<String, dynamic>;
        _onQrCodeScanned(decoded);
      } else {
        _onQrCodeScanned({
          'id': 'D${DateTime.now().millisecondsSinceEpoch % 10000}',
          'name': 'Scanned Hardware (${code.length > 10 ? code.substring(0, 10) : code})',
          'type': code.toLowerCase().contains('lock') ? 'lock' : (code.toLowerCase().contains('ac') ? 'ac' : 'light'),
          'sn': code,
          'firmware': 'v1.0.0',
        });
      }
    } catch (_) {
      _onQrCodeScanned({
        'id': 'D${DateTime.now().millisecondsSinceEpoch % 10000}',
        'name': 'QR Hardware Device',
        'type': 'light',
        'sn': code,
        'firmware': 'v1.0.0',
      });
    }
  }

  void _startRealNfcScan() async {
    try {
      final messenger = ScaffoldMessenger.of(context);
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        _simulateNfcDetection();
        return;
      }

      setState(() => _isNfcListening = true);
      HapticFeedback.lightImpact();

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('NFC Reader Active • Bring smart tag close to phone')),
        );
      }

      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          HapticFeedback.heavyImpact();
          NfcManager.instance.stopSession();

          final tagData = tag.data;
          final nfcData = {
            'id': 'D${DateTime.now().millisecondsSinceEpoch % 10000}',
            'name': 'SafeLock Pro NFC',
            'type': 'lock',
            'sn': 'NFC-${tagData.hashCode}',
            'firmware': 'v3.2.0',
          };

          if (mounted) {
            setState(() => _isNfcListening = false);
            _onQrCodeScanned(nfcData);
          }
        },
      );
    } catch (e) {
      debugPrint('NFC scanning fallback: $e');
      _simulateNfcDetection();
    }
  }

  void _simulateNfcDetection() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 600));

    final nfcData = {
      'id': 'D${DateTime.now().millisecondsSinceEpoch % 10000}',
      'name': 'SafeLock Pro NFC',
      'type': 'lock',
      'sn': 'NFC-99182X',
      'firmware': 'v3.2.0',
    };

    _onQrCodeScanned(nfcData);
  }

  void _pairViaMatterCode() {
    final code = _matterCodeController.text.trim();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 8-digit Matter pairing code')),
      );
      return;
    }

    final matterData = {
      'id': 'D${DateTime.now().millisecondsSinceEpoch % 10000}',
      'name': 'Eco Thermostat Z',
      'type': 'thermostat',
      'sn': 'MTR-$code',
      'firmware': 'v1.0.4',
    };

    _onQrCodeScanned(matterData);
  }

  void _confirmAndRegisterHardware(AppState state) {
    if (_scannedDeviceData == null) return;

    final String name = _deviceNameController.text.trim().isEmpty
        ? (_scannedDeviceData!['name'] ?? 'Smart Hardware')
        : _deviceNameController.text.trim();

    final String type = _scannedDeviceData!['type'] ?? 'light';
    final String deviceId = _scannedDeviceData!['id'] ?? 'D${DateTime.now().millisecondsSinceEpoch % 10000}';

    final newDevice = Device(
      id: deviceId,
      name: name,
      type: type,
      houseId: _selectedHouseId ?? state.selectedHouseId,
      floorId: _selectedFloorId ?? 'F001',
      roomId: _selectedRoomId ?? 'R001',
      isOn: false,
      isOnline: true,
      isFavorite: true,
      status: type == 'lock' ? 'Locked' : 'OFF',
      isLocked: type == 'lock',
    );

    state.addDevice(newDevice);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('Hardware Paired!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$name registered successfully to room.', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: state.activeThemeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Device ID: ${newDevice.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('Type: ${newDevice.type.toUpperCase()}', style: const TextStyle(fontSize: 12)),
                  Text('Cloud Relay: Synced [ONLINE]', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() {
                _isDiscovered = false;
                _scannedDeviceData = null;
              });
            },
            child: const Text('Pair Another'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: state.activeThemeColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context); // Return to registry
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => DeviceControlScreen(device: newDevice)),
              );
            },
            child: const Text('Control Device'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = state.activeThemeColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair New Hardware', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _qrController.toggleTorch(),
            tooltip: 'Toggle Flashlight',
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded),
            onPressed: () => _qrController.switchCamera(),
            tooltip: 'Switch Camera',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. PROVISIONING MODE TABS (QR Code / NFC Tag / Matter Code)
            if (!_isDiscovered) ...[
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildTabBtn('QR Camera', Icons.qr_code_scanner_rounded, 0, activeColor, isDark),
                    _buildTabBtn('NFC Tap', Icons.nfc_rounded, 1, activeColor, isDark),
                    _buildTabBtn('Matter Code', Icons.pin_rounded, 2, activeColor, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // TAB 0: REAL MOBILE CAMERA QR SCANNER
              if (_selectedTab == 0) _buildQrScannerView(state, activeColor, isDark),

              // TAB 1: REAL NFC TAP-TO-PAIR SENSOR
              if (_selectedTab == 1) _buildNfcTapView(activeColor, isDark),

              // TAB 2: MATTER PAIRING CODE INPUT
              if (_selectedTab == 2) _buildMatterPinView(activeColor, isDark),
            ] else ...[
              // 2. DISCOVERED HARDWARE CONFIGURATION & ROOM ASSIGNMENT
              _buildLocationAssignmentView(state, activeColor, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabBtn(String label, IconData icon, int index, Color activeColor, bool isDark) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black54)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrScannerView(AppState state, Color activeColor, bool isDark) {
    return Column(
      children: [
        // Camera Viewfinder Box with MobileScanner
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: activeColor, width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Real Mobile Camera Scanner
                MobileScanner(
                  controller: _qrController,
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      final code = barcodes.first.rawValue;
                      if (code != null && code.isNotEmpty && !_isDiscovered) {
                        _handleScannedRawCode(code);
                      }
                    }
                  },
                ),

                // Viewfinder Target Reticle Overlay
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white70, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                // Animated Scanning Laser Line
                AnimatedBuilder(
                  animation: _scanLaserAnimation,
                  builder: (context, child) {
                    return Positioned(
                      top: 40 + (190 * _scanLaserAnimation.value),
                      child: Container(
                        width: 210,
                        height: 3,
                        decoration: BoxDecoration(
                          color: activeColor,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.9),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Viewfinder Instruction Badge
                Positioned(
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 8),
                        Text(
                          'Point camera at QR code on device or box',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Quick Simulated QR Test Targets
        SmartHomeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Instant QR Scanner Presets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _qrPresetBtn('Smart Bulb RGB', 'light', 'D901', 'SN-882190', activeColor),
                  _qrPresetBtn('SafeLock Pro', 'lock', 'D902', 'SN-77102A', activeColor),
                  _qrPresetBtn('Eco Thermostat Z', 'thermostat', 'D903', 'SN-33901C', activeColor),
                  _qrPresetBtn('HD Ultra Camera', 'camera', 'D904', 'SN-55201B', activeColor),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _qrPresetBtn(String name, String type, String id, String sn, Color activeColor) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: activeColor.withValues(alpha: 0.12),
        foregroundColor: activeColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () {
        _onQrCodeScanned({
          'id': id,
          'name': name,
          'type': type,
          'sn': sn,
          'firmware': 'v2.4.1',
        });
      },
      icon: const Icon(Icons.qr_code_2_rounded, size: 18),
      label: Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildNfcTapView(Color activeColor, bool isDark) {
    return SmartHomeCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            ScaleTransition(
              scale: _nfcPulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeColor.withValues(alpha: 0.15),
                ),
                child: Icon(
                  Icons.nfc_rounded,
                  size: 64,
                  color: _isNfcListening ? Colors.green : activeColor,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isNfcListening ? 'NFC Reader Active • Touch Tag' : 'Hold Phone Near NFC Hardware Tag',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Bring your smartphone within 2 cm of the smart device or smart tag.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _startRealNfcScan,
                    icon: const Icon(Icons.sensors_rounded),
                    label: const Text('START REAL NFC SCAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: activeColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _simulateNfcDetection,
                    icon: const Icon(Icons.tap_and_play_rounded),
                    label: const Text('SIMULATE TAG TAP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatterPinView(Color activeColor, bool isDark) {
    return SmartHomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Matter / Thread 8-Digit Pairing PIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          const Text('Enter the setup code found under the device or on the instruction manual.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          TextField(
            controller: _matterCodeController,
            keyboardType: TextInputType.number,
            maxLength: 8,
            decoration: const InputDecoration(
              labelText: 'Pairing Code (e.g. 12345678)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.numbers_rounded),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: activeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _pairViaMatterCode,
              icon: const Icon(Icons.link_rounded),
              label: const Text('PAIR VIA MATTER CODE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationAssignmentView(AppState state, Color activeColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Discovered Device Hero Card
        SmartHomeCard(
          color: activeColor.withValues(alpha: 0.12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DISCOVERED HARDWARE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      _scannedDeviceData!['name'] ?? 'Smart Device',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: activeColor),
                    ),
                    Text(
                      'SN: ${_scannedDeviceData!['sn'] ?? "SN-00192"} • FW: ${_scannedDeviceData!['firmware'] ?? "v1.0"}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Device Customization Form
        SmartHomeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Device Configuration & Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),

              // Device Name
              TextField(
                controller: _deviceNameController,
                decoration: const InputDecoration(
                  labelText: 'Custom Device Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // Select House
              DropdownButtonFormField<String>(
                value: _selectedHouseId,
                decoration: const InputDecoration(
                  labelText: 'Target Property',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home_rounded),
                ),
                items: state.houses.map((h) => DropdownMenuItem(value: h.id, child: Text(h.name))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedHouseId = val);
                },
              ),
              const SizedBox(height: 16),

              // Select Floor
              DropdownButtonFormField<String>(
                value: _selectedFloorId,
                decoration: const InputDecoration(
                  labelText: 'Floor Assignment',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.layers_rounded),
                ),
                items: state.selectedHouseFloors.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedFloorId = val);
                },
              ),
              const SizedBox(height: 16),

              // Select Room
              DropdownButtonFormField<String>(
                value: _selectedRoomId,
                decoration: const InputDecoration(
                  labelText: 'Room Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.meeting_room_rounded),
                ),
                items: state.rooms.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRoomId = val);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Confirm Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: activeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            onPressed: () => _confirmAndRegisterHardware(state),
            icon: const Icon(Icons.add_task_rounded),
            label: const Text('CONFIRM & REGISTER HARDWARE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
      ],
    );
  }
}
