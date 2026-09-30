import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/house.dart';
import '../models/floor.dart';
import '../models/room.dart';
import '../models/zone.dart';
import '../models/device.dart';
import '../models/user.dart';
import '../models/scenario.dart';
import '../models/alarm_settings.dart';
import '../models/smart_notification.dart';
import '../models/home_mode.dart';
import '../models/security_alert.dart';
import '../models/automation_rule.dart';
import 'notification_service.dart';
import 'cloud_relay_service.dart';

enum PowerSource { solar, battery, grid }

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  static AppState get instance => _instance;
  factory AppState() => _instance;
  AppState._internal() {
    _initPersistence();
    Timer.periodic(const Duration(seconds: 3), (timer) {
      _recalculateTelemetry();
      _evaluateAutomations();
      notifyListeners();
    });
  }

  final List<Map<String, String>> unprovisionedDevices = [
    {'name': 'Smart RGB Bulb X1', 'type': 'light'},
    {'name': 'Eco Thermostat Z', 'type': 'thermostat'},
    {'name': 'SafeLock Pro', 'type': 'lock'},
    {'name': 'HD Ultra Camera', 'type': 'camera'},
  ];

  void _recalculateTelemetry() {
    // Real power load calculation based on active appliances
    double load = 0.3; // Base standby load (0.3 kW)
    for (var d in devices) {
      if (d.isOn) {
        if (d.type == 'ac') {
          load += 1.5;
        } else if (d.type == 'light') {
          load += (d.brightness * 0.08);
        } else if (d.type == 'tv') {
          load += 0.15;
        } else if (d.type == 'ev_charger') {
          load += 7.2;
        } else if (d.type == 'washer' || d.type == 'dryer') {
          load += 1.2;
        } else {
          load += 0.05;
        }
      }
    }
    _currentPowerLoad = double.parse(load.toStringAsFixed(2));

    // Real indoor temperature response to AC target setpoint & open windows
    final acList = devices.where((d) => d.type == 'ac');
    if (acList.isNotEmpty) {
      final acUnit = acList.first;
      if (acUnit.isOn && !isWindowOpen) {
        if (_indoorTemp > acUnit.targetTemp) {
          _indoorTemp = max(acUnit.targetTemp, _indoorTemp - 0.2);
        } else if (_indoorTemp < acUnit.targetTemp) {
          _indoorTemp = min(acUnit.targetTemp, _indoorTemp + 0.2);
        }
      }
    }

    if (isWindowOpen) {
      if (_indoorTemp > outdoorTemp) {
        _indoorTemp = max(outdoorTemp, _indoorTemp - 0.1);
      } else if (_indoorTemp < outdoorTemp) {
        _indoorTemp = min(outdoorTemp, _indoorTemp + 0.1);
      }
    }

    // Real CO2 & Humidity dynamics
    _co2Level = isWindowOpen ? 410 : (hvacRunning ? 440 : 520);
    _humidity = isWindowOpen ? 60.0 : (hvacRunning ? 42.0 : 48.0);
  }

  // --- AUTOMATION ENGINE ---
  final List<AutomationRule> _automationRules = [
    AutomationRule(
      id: 'R001',
      name: 'Night Motion Lighting',
      triggerType: 'motion',
      triggerCondition: 'detected',
      triggerValue: 'Living Room',
      actionDeviceId: 'D001',
      actionCommand: 'turnOn',
    ),
    AutomationRule(
      id: 'R002',
      name: 'Sunset Curtains Closing',
      triggerType: 'sunset',
      triggerCondition: 'equals',
      triggerValue: 'Sunset',
      actionDeviceId: 'D007',
      actionCommand: 'setPosition',
      actionValue: 0.30,
    ),
    AutomationRule(
      id: 'R003',
      name: 'High Heat AC Cooling',
      triggerType: 'temperature',
      triggerCondition: 'greater_than',
      triggerValue: 28.0,
      actionDeviceId: 'D002',
      actionCommand: 'turnOn',
    ),
    AutomationRule(
      id: 'R004',
      name: 'Water Leak Emergency Shutoff',
      triggerType: 'water_leak',
      triggerCondition: 'detected',
      triggerValue: 'Kitchen',
      actionDeviceId: 'WATER_VALVE',
      actionCommand: 'closeValve',
    ),
  ];

  List<AutomationRule> get automationRules => _automationRules;

  void addAutomationRule(AutomationRule rule) {
    _automationRules.add(rule);
    _activities.insert(0, 'Automation rule created: ${rule.name}');
    notifyListeners();
  }

  void toggleAutomationRule(String id, bool enabled) {
    final idx = _automationRules.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _automationRules[idx].isEnabled = enabled;
      _activities.insert(0, 'Automation rule ${enabled ? "enabled" : "disabled"}: ${_automationRules[idx].name}');
      notifyListeners();
    }
  }

  void deleteAutomationRule(String id) {
    final idx = _automationRules.indexWhere((r) => r.id == id);
    if (idx != -1) {
      final name = _automationRules[idx].name;
      _automationRules.removeAt(idx);
      _activities.insert(0, 'Automation rule deleted: $name');
      notifyListeners();
    }
  }

  void executeAutomationRule(AutomationRule rule) async {
    _activities.insert(0, 'Executing automation: ${rule.name}');
    rule.lastTriggered = DateTime.now();

    if (rule.actionDeviceId == 'WATER_VALVE') {
      final valveIdx = devices.indexWhere((d) => d.type == 'water_valve' || d.id == 'D00F');
      if (valveIdx != -1) {
        devices[valveIdx].isValveOpen = false;
        devices[valveIdx].status = 'Valve Closed';
        devices[valveIdx].isOn = false;
        _syncDeviceToCloud(devices[valveIdx]);
      }
      addNotification(SmartNotification(
        id: 'N${DateTime.now().millisecondsSinceEpoch}',
        title: 'Automation Triggered',
        body: 'Main Water Shutoff Valve closed automatically by rule: ${rule.name}',
        timestamp: DateTime.now(),
        propertyId: selectedHouseId,
        category: NotificationCategory.security,
      ));
    } else if (rule.actionDeviceId == 'ALL_LIGHTS') {
      for (var d in devices.where((dev) => dev.type == 'light')) {
        d.isOn = true;
        d.status = 'ON';
        d.brightness = 1.0;
        _syncDeviceToCloud(d);
      }
    } else {
      final devIdx = devices.indexWhere((d) => d.id == rule.actionDeviceId);
      if (devIdx != -1) {
        if (rule.actionCommand == 'turnOn') {
          devices[devIdx].isOn = true;
          devices[devIdx].status = 'ON';
        } else if (rule.actionCommand == 'turnOff') {
          devices[devIdx].isOn = false;
          devices[devIdx].status = 'OFF';
        }
        _syncDeviceToCloud(devices[devIdx]);
      }
    }
    notifyListeners();
  }

  void _evaluateAutomations() {
    for (var rule in _automationRules) {
      if (!rule.isEnabled) continue;

      if (rule.triggerType == 'temperature' && indoorTemp > 28.0) {
        if (rule.lastTriggered == null || DateTime.now().difference(rule.lastTriggered!).inMinutes > 30) {
          executeAutomationRule(rule);
        }
      } else if (rule.triggerType == 'water_leak' && activeAlerts.any((a) => a.title.contains('LEAK'))) {
        if (rule.lastTriggered == null || DateTime.now().difference(rule.lastTriggered!).inMinutes > 5) {
          executeAutomationRule(rule);
        }
      }
    }
  }

  // --- .NET 9 CLOUD RELAY ---
  final CloudRelayService _cloud = CloudRelayService();
  bool get isCloudConnected => _cloud.isConnected;
  String get cloudBaseUrl => _cloud.baseUrl;

  Future<void> syncWithCloud() async {
    try {
      List<dynamic> cloudData = await _cloud.getDevices();

      if (cloudData.isEmpty) {
        cloudData = await _cloud.registerDevices(devices);
      }

      for (var data in cloudData) {
        final String cloudId = data['id'];
        final String cloudName = data['name'] ?? 'Cloud Device $cloudId';
        final String cloudType = data['type'] ?? 'light';
        final index = devices.indexWhere((d) => d.id == cloudId);

        if (index != -1) {
          final String status = data['status'] ?? 'OFF';
          devices[index].status = status;
          devices[index].isOn = (status == 'ON' || status == 'Open' || status == 'Unlocked');
          if (data['temperature'] != null) {
            devices[index].targetTemp = (data['temperature'] as num).toDouble();
          }
          if (data['brightness'] != null) {
            double bVal = (data['brightness'] as num).toDouble();
            if (bVal > 1.0) {
              bVal = bVal / 100.0;
            }
            devices[index].brightness = bVal.clamp(0.0, 1.0);
          }
        } else {
          final String status = data['status'] ?? 'OFF';
          final newDevice = Device(
            id: cloudId,
            name: cloudName,
            type: cloudType,
            houseId: selectedHouseId,
            floorId: 'F001',
            roomId: 'R001',
            isOn: (status == 'ON' || status == 'Open' || status == 'Unlocked'),
            status: status,
            isOnline: data['isOnline'] ?? true,
            isFavorite: true,
            targetTemp: data['temperature'] != null ? (data['temperature'] as num).toDouble() : 22.0,
            brightness: data['brightness'] != null ? ((data['brightness'] as num).toDouble() > 1.0 ? (data['brightness'] as num).toDouble() / 100.0 : (data['brightness'] as num).toDouble()).clamp(0.0, 1.0) : 1.0,
          );
          devices.add(newDevice);
          _activities.insert(0, '.NET Cloud Device Discovered: $cloudName ($cloudId)');
        }
      }
      _activities.insert(0, 'Handshake successful: Synced with .NET 9 Cloud Relay (${_cloud.baseUrl}).');
      notifyListeners();
    } catch (e) {
      debugPrint('Cloud sync error: $e');
      _activities.insert(0, '.NET Relay sync warning: Operating offline ($e)');
      notifyListeners();
    }
  }

  void toggleCloudConnection(bool online) {
    _cloud.setCloudStatus(online);
    notifyListeners();
  }

  Future<void> runCloudDiagnostic() async {
    _activities.insert(0, 'Diagnostic: Testing .NET 9 Cloud Relay connection...');
    notifyListeners();
    try {
      bool isPingOk = await _cloud.checkConnection();
      _activities.insert(0, 'Diagnostic: .NET 9 Relay Ping -> ${isPingOk ? "ONLINE" : "UNREACHABLE"}');

      List<dynamic> cloudDevices = await _cloud.getDevices();
      _activities.insert(0, 'Diagnostic: Fetched ${cloudDevices.length} devices from .NET Relay.');

      _activities.insert(0, 'Diagnostic: Toggling D001 on .NET Relay...');
      bool newState = await _cloud.toggleDevice('D001');
      _activities.insert(0, 'Diagnostic: D001 toggled to $newState on .NET 9 Relay.');

      await syncWithCloud();
      _activities.insert(0, 'Diagnostic: .NET 9 Cloud Relay test completed successfully.');
    } catch (e) {
      _activities.insert(0, 'Diagnostic Error (.NET Relay): $e');
    }
    notifyListeners();
  }

  // --- LIVE WEATHER ---
  double weatherTemp = 28.0;
  String weatherCondition = 'Sunny';
  IconData weatherIcon = Icons.wb_sunny_rounded;
  Color weatherIconColor = Colors.orange;
  bool isWeatherLoading = false;

  Future<void> fetchLiveWeather({double? lat, double? lon}) async {
    isWeatherLoading = true;
    notifyListeners();

    double targetLat = lat ?? 5.6037;
    double targetLon = lon ?? -0.1870;

    if (lat == null || lon == null) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
            Position? lastPosition = await Geolocator.getLastKnownPosition();
            if (lastPosition != null) {
              targetLat = lastPosition.latitude;
              targetLon = lastPosition.longitude;
            } else {
              Position position = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.medium,
                  timeLimit: Duration(seconds: 8),
                ),
              );
              targetLat = position.latitude;
              targetLon = position.longitude;
            }
          }
        }
      } catch (e) {
        debugPrint('GPS location detection fallback: $e');
      }
    }

    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$targetLat&longitude=$targetLon&current=temperature_2m,weather_code',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];
        if (current != null) {
          weatherTemp = (current['temperature_2m'] as num).toDouble();
          final int code = (current['weather_code'] as num).toInt();
          _parseWeatherCode(code);
        }
      }
    } catch (e) {
      debugPrint('Live weather fetch error: $e');
    } finally {
      isWeatherLoading = false;
      notifyListeners();
    }
  }

  void _parseWeatherCode(int code) {
    if (code == 0) {
      weatherCondition = 'Sunny';
      weatherIcon = Icons.wb_sunny_rounded;
      weatherIconColor = Colors.orange;
    } else if (code >= 1 && code <= 3) {
      weatherCondition = 'Partly Cloudy';
      weatherIcon = Icons.cloud_rounded;
      weatherIconColor = Colors.amber;
    } else if (code == 45 || code == 48) {
      weatherCondition = 'Foggy';
      weatherIcon = Icons.blur_on_rounded;
      weatherIconColor = Colors.blueGrey;
    } else if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      weatherCondition = 'Rainy';
      weatherIcon = Icons.water_drop_rounded;
      weatherIconColor = Colors.blue;
    } else {
      weatherCondition = 'Clear';
      weatherIcon = Icons.wb_sunny_rounded;
      weatherIconColor = Colors.orange;
    }
  }

  // --- PERSISTENCE ---
  late SharedPreferences _prefs;
  bool biometricsEnabled = true;

  Future<void> _initPersistence() async {
    _prefs = await SharedPreferences.getInstance();
    isFirstLaunch = _prefs.getBool('first_launch') ?? true;
    biometricsEnabled = _prefs.getBool('biometrics_enabled') ?? true;

    _loadAllStoredData();

    await syncWithCloud();
    fetchLiveWeather();
    notifyListeners();
  }

  void _loadAllStoredData() {
    try {
      isDarkMode = _prefs.getBool('is_dark_mode') ?? false;
      final savedColorHex = _prefs.getInt('active_theme_color');
      if (savedColorHex != null) activeThemeColor = Color(savedColorHex);

      final savedPowerIndex = _prefs.getInt('power_source');
      if (savedPowerIndex != null && savedPowerIndex < PowerSource.values.length) {
        powerSource = PowerSource.values[savedPowerIndex];
      }

      final savedHomeModeIndex = _prefs.getInt('home_mode');
      if (savedHomeModeIndex != null && savedHomeModeIndex < HomeMode.values.length) {
        homeMode = HomeMode.values[savedHomeModeIndex];
      }

      securityStatus = _prefs.getString('security_status') ?? 'Armed Stay';

      final String? housesJson = _prefs.getString('stored_houses');
      if (housesJson != null && housesJson.isNotEmpty) {
        final List<dynamic> decoded = json.decode(housesJson);
        houses.clear();
        houses.addAll(decoded.map((item) => House.fromJson(item)));
      }
      selectedHouseId = _prefs.getString('selected_house_id') ?? (houses.isNotEmpty ? houses.first.id : 'H001');

      final String? devicesJson = _prefs.getString('stored_devices');
      if (devicesJson != null && devicesJson.isNotEmpty) {
        final List<dynamic> decoded = json.decode(devicesJson);
        final loadedDevices = decoded.map((item) => Device.fromJson(item)).toList();

        // Smart merge: Add any missing default ecosystem devices (e.g. D007-D016)
        final Set<String> existingIds = loadedDevices.map((d) => d.id).toSet();
        for (var defaultDev in _defaultTemplateDevices) {
          if (!existingIds.contains(defaultDev.id)) {
            loadedDevices.add(defaultDev);
          }
        }

        devices.clear();
        devices.addAll(loadedDevices);
      }

      isLoggedIn = _prefs.getBool('is_logged_in') ?? false;
      profileImagePath = _prefs.getString('profile_image_path');
      final String? userJson = _prefs.getString('current_user');
      if (userJson != null && userJson.isNotEmpty) {
        currentUser = HomeUser.fromJson(json.decode(userJson));
      }

      final String? scenariosJson = _prefs.getString('stored_scenarios');
      if (scenariosJson != null && scenariosJson.isNotEmpty) {
        final List<dynamic> decoded = json.decode(scenariosJson);
        _scenarios.clear();
        _scenarios.addAll(decoded.map((item) => Scenario.fromJson(item)));
      }

      final String? rulesJson = _prefs.getString('stored_automations');
      if (rulesJson != null && rulesJson.isNotEmpty) {
        final List<dynamic> decoded = json.decode(rulesJson);
        _automationRules.clear();
        _automationRules.addAll(decoded.map((item) => AutomationRule.fromJson(item)));
      }
    } catch (e) {
      debugPrint('Error loading stored app data: $e');
    }
  }

  void saveAllStoredData() {
    try {
      _prefs.setBool('first_launch', isFirstLaunch);
      _prefs.setBool('biometrics_enabled', biometricsEnabled);
      _prefs.setBool('is_dark_mode', isDarkMode);
      _prefs.setInt('active_theme_color', activeThemeColor.toARGB32());
      _prefs.setInt('power_source', powerSource.index);
      _prefs.setInt('home_mode', homeMode.index);
      _prefs.setString('security_status', securityStatus);
      _prefs.setString('selected_house_id', selectedHouseId);

      _prefs.setString('stored_houses', json.encode(houses.map((h) => h.toJson()).toList()));
      _prefs.setString('stored_devices', json.encode(devices.map((d) => d.toJson()).toList()));
      _prefs.setBool('is_logged_in', isLoggedIn);

      if (currentUser != null) {
        _prefs.setString('current_user', json.encode(currentUser!.toJson()));
      }

      _prefs.setString('stored_scenarios', json.encode(_scenarios.map((s) => s.toJson()).toList()));
      _prefs.setString('stored_automations', json.encode(_automationRules.map((r) => r.toJson()).toList()));
      _prefs.setStringList('stored_activities', _activities.take(50).toList());
    } catch (e) {
      debugPrint('Error saving app data: $e');
    }
  }

  void setBiometricsEnabled(bool enabled) {
    biometricsEnabled = enabled;
    _activities.insert(0, 'Security: Biometric authentication ${enabled ? "enabled" : "disabled"}.');
    notifyListeners();
  }

  void completeFirstLaunch() { isFirstLaunch = false; saveAllStoredData(); notifyListeners(); }

  @override
  void notifyListeners() {
    saveAllStoredData();
    super.notifyListeners();
  }

  // --- UI & THEME ---
  bool isDarkMode = false;
  bool isFirstLaunch = true;
  Color activeThemeColor = const Color(0xFF2E7D32);
  void toggleDarkMode() { isDarkMode = !isDarkMode; saveAllStoredData(); notifyListeners(); }
  void setThemeColor(Color color) { activeThemeColor = color; saveAllStoredData(); notifyListeners(); }

  // --- DASHBOARD & HVAC ---
  HomeMode homeMode = HomeMode.home;
  PowerSource powerSource = PowerSource.grid;
  double _indoorTemp = 22.5;
  final double _outdoorTemp = 18.0;
  double _currentPowerLoad = 1.2;
  final double _dailyPowerUsage = 14.5;
  int _co2Level = 450; 
  double _humidity = 48.0;
  bool isWindowOpen = false;

  double get indoorTemp => _indoorTemp;
  double get outdoorTemp => _outdoorTemp;
  double get currentPowerLoad => _currentPowerLoad;
  double get dailyPowerUsage => _dailyPowerUsage;
  int get co2Level => _co2Level;
  double get humidity => _humidity;

  void setPowerSource(PowerSource source) { powerSource = source; _activities.insert(0, 'Power: ${source.name.toUpperCase()}'); saveAllStoredData(); notifyListeners(); }
  void toggleWindowStatus() {
    isWindowOpen = !isWindowOpen;
    if (isWindowOpen && hvacRunning) {
      addNotification(SmartNotification(id: 'N${DateTime.now().millisecondsSinceEpoch}', title: 'Efficiency Warning', body: 'Window opened during AC operation.', timestamp: DateTime.now(), propertyId: selectedHouseId, category: NotificationCategory.security));
    }
    notifyListeners();
  }

  // --- PERMISSIONS ---
  final Map<String, bool> permissions = { 'Bluetooth': true, 'Location': false, 'Local Network': true, 'Notifications': true };
  void togglePermission(String name) { if (permissions.containsKey(name)) { permissions[name] = !permissions[name]!; notifyListeners(); } }

  // --- SECURITY ---
  String securityStatus = 'Armed Stay';
  final List<SecurityAlert> activeAlerts = [];
  bool isEmergencyMode = false;

  void changeSecurityStatus(String status) {
    if (!isLoggedIn) return;
    securityStatus = status;
    _activities.insert(0, 'Security: $status');
    addNotification(SmartNotification(id: 'N${DateTime.now().millisecondsSinceEpoch}', title: 'Security Alert', body: 'System is now $status.', timestamp: DateTime.now(), propertyId: selectedHouseId, category: NotificationCategory.security));
    notifyListeners();
  }

  void triggerEmergency() {
    if (!isLoggedIn) return;
    isEmergencyMode = !isEmergencyMode;
    if (isEmergencyMode) {
      _activities.insert(0, 'EMERGENCY MODE ACTIVATED');
      for (var d in devices) {
        if (d.type == 'light') {
          d.isOn = true;
          d.status = 'ON';
          d.brightness = 1.0;
          _syncDeviceToCloud(d);
        }
      }
    }
    notifyListeners();
  }

  void addSimulatedLeak() {
    activeAlerts.add(SecurityAlert(
      id: 'A${DateTime.now().millisecondsSinceEpoch}',
      title: 'WATER LEAK DETECTED',
      location: 'Kitchen',
      timestamp: DateTime.now(),
      icon: Icons.water_damage_rounded,
    ));
    _evaluateAutomations();
    notifyListeners();
  }
  void clearAlerts() { activeAlerts.clear(); notifyListeners(); }

  // --- FULL 20 ECOSYSTEM DEVICES DATA MODEL ---
  final List<House> houses = [ House(id: 'H001', name: 'My House', address: '123 Main St') ];
  final List<Floor> floors = [ Floor(id: 'F001', houseId: 'H001', name: 'Ground Floor'), Floor(id: 'F002', houseId: 'H001', name: 'First Floor') ];
  final List<Room> rooms = [
    Room(id: 'R001', houseId: 'H001', floorId: 'F001', name: 'Living Room'),
    Room(id: 'R002', houseId: 'H001', floorId: 'F001', name: 'Kitchen'),
    Room(id: 'R003', houseId: 'H001', floorId: 'F002', name: 'Master Bedroom'),
  ];
  final List<Zone> zones = [ Zone(id: 'Z001', roomId: 'R001', name: 'Entertainment Area') ];

  static final List<Device> _defaultTemplateDevices = [
    Device(id: 'D001', name: 'Living Room Lights', type: 'light', houseId: 'H001', floorId: 'F001', roomId: 'R001', zoneId: 'Z001', isOn: true, status: 'ON', isFavorite: true, imageUrl: 'https://images.unsplash.com/photo-1540518614846-7eded433c457?q=80&w=200&auto=format&fit=crop'),
    Device(id: 'D002', name: 'Main AC Unit', type: 'ac', houseId: 'H001', floorId: 'F001', roomId: 'R001', isOn: true, status: 'ON', targetTemp: 21.0, isFavorite: true),
    Device(id: 'D003', name: 'Garage Door', type: 'garage', houseId: 'H001', floorId: 'F001', roomId: 'R001', isOn: false, status: 'Closed', isFavorite: true),
    Device(id: 'D004', name: 'Front Porch Camera', type: 'camera', houseId: 'H001', floorId: 'F001', roomId: 'R001', isOn: true, isOnline: true, imageUrl: 'https://images.unsplash.com/photo-1558002038-1055907df827?q=80&w=200&auto=format&fit=crop'),
    Device(id: 'D005', name: 'Motion Sensor', type: 'sensor', houseId: 'H001', floorId: 'F001', roomId: 'R001', isOn: true, isOnline: true),
    Device(id: 'D006', name: 'SafeLock Pro', type: 'lock', houseId: 'H001', floorId: 'F001', roomId: 'R001', isOn: false, isLocked: true, status: 'Locked', isFavorite: true),
    Device(id: 'D007', name: 'Living Room Curtains', type: 'curtain', houseId: 'H001', floorId: 'F001', roomId: 'R001', isOn: true, status: '65% Open', isFavorite: true, openPercentage: 0.65),
    Device(id: 'D008', name: 'Motorized Window', type: 'window', houseId: 'H001', floorId: 'F001', roomId: 'R001', isOn: false, status: 'Closed', isFavorite: true, openPercentage: 0.0),
    Device(id: 'D009', name: 'Main Motorized Gate', type: 'gate', houseId: 'H001', floorId: 'F001', roomId: 'R001', isOn: false, status: 'Closed', isFavorite: true),
    Device(id: 'D00A', name: 'Smoke & Fire Detector', type: 'smoke_detector', houseId: 'H001', floorId: 'F001', roomId: 'R002', isOn: true, status: 'Normal', isFavorite: true),
    Device(id: 'D00B', name: 'LPG Gas Detector', type: 'gas_detector', houseId: 'H001', floorId: 'F001', roomId: 'R002', isOn: true, status: 'Normal', isFavorite: true),
    Device(id: 'D00C', name: 'Kitchen Water Leak Sensor', type: 'leak_sensor', houseId: 'H001', floorId: 'F001', roomId: 'R002', isOn: true, status: 'Dry Normal', isFavorite: true),
    Device(id: 'D00D', name: 'Overhead Water Tank', type: 'water_tank', houseId: 'H001', floorId: 'F002', roomId: 'R003', isOn: true, status: '82% Full', waterLevelPercentage: 82.0, isFavorite: true),
    Device(id: 'D00E', name: 'Main Water Pump', type: 'water_pump', houseId: 'H001', floorId: 'F001', roomId: 'R002', isOn: false, status: 'Auto Standby', isFavorite: true),
    Device(id: 'D00F', name: 'Smart Water Shutoff Valve', type: 'water_valve', houseId: 'H001', floorId: 'F001', roomId: 'R002', isOn: true, isValveOpen: true, status: 'Valve Open', isFavorite: true),
    Device(id: 'D010', name: 'Solar PV System', type: 'solar', houseId: 'H001', floorId: 'F002', roomId: 'R003', isOn: true, status: '8.42 kW Generating', pvPowerKw: 8.42, isFavorite: true),
    Device(id: 'D011', name: 'Home Battery Storage', type: 'battery', houseId: 'H001', floorId: 'F001', roomId: 'R001', isOn: true, status: '78% SoC', batterySocPercentage: 78.0, isFavorite: true),
    Device(id: 'D012', name: 'EV Charger Station', type: 'ev_charger', houseId: 'H001', floorId: 'F001', roomId: 'R001', isOn: true, status: '7.2 kW Charging', evChargingPowerKw: 7.2, evBatteryPercentage: 64.0, isFavorite: true),
    Device(id: 'D013', name: 'Smart Refrigerator', type: 'fridge', houseId: 'H001', floorId: 'F001', roomId: 'R002', isOn: true, status: 'Cooling 3°C', freezerTemp: -18.0, isFavorite: true),
    Device(id: 'D014', name: 'Smart Washing Machine', type: 'washer', houseId: 'H001', floorId: 'F001', roomId: 'R002', isOn: false, status: 'Standby', isFavorite: true),
    Device(id: 'D015', name: 'Living Room TV', type: 'tv', houseId: 'H001', floorId: 'F001', roomId: 'R001', isOn: true, status: 'ON', isFavorite: true),
    Device(id: 'D016', name: 'Whole-House Audio Speaker', type: 'speaker', houseId: 'H001', floorId: 'F001', roomId: 'R001', isOn: true, status: 'Playing', isFavorite: true),
  ];

  final List<Device> devices = List.from(_defaultTemplateDevices);

  final List<HomeUser> users = [ HomeUser(id: 'U001', name: 'Home Owner', email: 'owner@example.com', role: 'Owner • Full Access') ];

  // --- USER AUTHENTICATION & PROFILE ---
  bool isLoggedIn = false;
  String? profileImagePath;
  late HomeUser? currentUser = users.first;

  void toggleBiometrics(bool val) {
    setBiometricsEnabled(val);
  }

  void login(String email, String name) {
    isLoggedIn = true;
    currentUser = HomeUser(
      id: 'U001',
      name: name.isEmpty ? 'Home Owner' : name,
      email: email.isEmpty ? 'owner@example.com' : email,
      role: 'Owner • Full Access',
      controlDevices: true,
      viewCameras: true,
      controlSecurity: true,
      manageOtherUsers: true,
    );
    _activities.insert(0, 'Authentication: Logged in as ${currentUser!.name}.');
    notifyListeners();
  }

  void updateProfileImage(String? path) {
    profileImagePath = path;
    _activities.insert(0, 'Profile: Avatar picture updated.');
    notifyListeners();
  }

  void logout() {
    isLoggedIn = false;
    currentUser = null;
    _activities.insert(0, 'Authentication: User logged out.');
    notifyListeners();
  }

  // --- LOGIC ---
  String selectedHouseId = 'H001';
  House? get selectedHouse => houses.firstWhere((h) => h.id == selectedHouseId, orElse: () => houses.first);
  List<Floor> get selectedHouseFloors => floors.where((f) => f.houseId == selectedHouseId).toList();
  List<Device> get selectedHouseDevices => devices.where((d) => d.houseId == selectedHouseId).toList();
  List<Scenario> get selectedHouseScenarios => _scenarios.where((s) => s.propertyId == selectedHouseId).toList();
  bool get hvacRunning => devices.any((d) => d.type == 'ac' && d.isOn);
  int get activeLightsCount => devices.where((d) => d.type == 'light' && d.isOn).length;
  int get offlineDevicesCount => devices.where((d) => !d.isOnline).length;

  void updateDeviceImage(String id, {String? path, String? url}) {
    final idx = devices.indexWhere((d) => d.id == id);
    if (idx != -1) { devices[idx].imagePath = path; devices[idx].imageUrl = url; notifyListeners(); }
  }

  void toggleDevice(String id, bool isOn) async {
    if (!isLoggedIn) return;
    final idx = devices.indexWhere((d) => d.id == id);
    if (idx == -1) return;

    devices[idx].isOn = isOn;

    // Set appropriate status string per device category
    if (devices[idx].type == 'garage' || devices[idx].type == 'gate' || devices[idx].type == 'window' || devices[idx].type == 'curtain' || devices[idx].type == 'blinds') {
      devices[idx].status = isOn ? (devices[idx].type == 'curtain' ? '65% Open' : 'Open') : 'Closed';
      if (devices[idx].type == 'curtain' || devices[idx].type == 'window') {
        devices[idx].openPercentage = isOn ? 1.0 : 0.0;
      }
    } else if (devices[idx].type == 'lock') {
      devices[idx].isLocked = !isOn;
      devices[idx].status = isOn ? 'Unlocked' : 'Locked';
    } else if (devices[idx].type == 'water_valve') {
      devices[idx].isValveOpen = isOn;
      devices[idx].status = isOn ? 'Valve Open' : 'Valve Closed';
    } else {
      devices[idx].status = isOn ? 'ON' : 'OFF';
    }

    addNotification(SmartNotification(
      id: 'N${DateTime.now().millisecondsSinceEpoch}',
      title: 'Device State Changed',
      body: '${devices[idx].name} turned ${devices[idx].status}',
      timestamp: DateTime.now(),
      propertyId: selectedHouseId,
      category: NotificationCategory.device,
    ));

    notifyListeners();

    try {
      final cloudState = await _cloud.toggleDevice(id);
      devices[idx].isOn = cloudState;
      if (devices[idx].type == 'garage' || devices[idx].type == 'gate' || devices[idx].type == 'window') {
        devices[idx].status = cloudState ? 'Open' : 'Closed';
      } else if (devices[idx].type == 'lock') {
        devices[idx].isLocked = !cloudState;
        devices[idx].status = cloudState ? 'Unlocked' : 'Locked';
      } else {
        devices[idx].status = cloudState ? 'ON' : 'OFF';
      }
      _activities.insert(0, '.NET Relay confirmed: ${devices[idx].name} -> ${devices[idx].status}');
      notifyListeners();
    } catch (e) {
      // Local standalone mode when Cloud Relay is offline — preserve user's toggle state!
      _activities.insert(0, '.NET Relay offline: ${devices[idx].name} updated locally.');
      notifyListeners();
    }
  }

  Future<void> _syncDeviceToCloud(Device device) async {
    try {
      await _cloud.updateDeviceState(device.toJson());
      _activities.insert(0, '.NET Relay updated: ${device.name} -> ${device.status}');
    } catch (e) {
      debugPrint('Cloud sync error for ${device.name}: $e');
    }
  }

  void updateDeviceHvacMode(String id, String mode) {
    final index = devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      devices[index].hvacMode = mode;
      devices[index].status = mode;
      if (mode == 'Eco') {
        devices[index].targetTemp = 24.0;
      } else if (mode == 'Sleep') {
        devices[index].targetTemp = 20.0;
      }
      notifyListeners();
      _syncDeviceToCloud(devices[index]);
    }
  }

  void updateDeviceLockMode(String id, String mode) {
    final index = devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      devices[index].lockMode = mode;
      notifyListeners();
      _syncDeviceToCloud(devices[index]);
    }
  }

  void updateDeviceCameraArmMode(String id, String mode) {
    final index = devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      devices[index].cameraArmMode = mode;
      notifyListeners();
      _syncDeviceToCloud(devices[index]);
    }
  }

  void updateDeviceBlindMode(String id, String mode) {
    final index = devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      devices[index].blindMode = mode;
      notifyListeners();
      _syncDeviceToCloud(devices[index]);
    }
  }

  void updateDeviceKelvinTemp(String id, int kelvin) {
    final index = devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      devices[index].kelvinTemp = kelvin;
      devices[index].colorTemp = ((kelvin - 2200) / (6500 - 2200)).clamp(0.0, 1.0);
      notifyListeners();
      _syncDeviceToCloud(devices[index]);
    }
  }

  void updateDeviceLightingMode(String id, String mode) {
    final index = devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      devices[index].lightingMode = mode;
      
      if (mode == 'Circadian') {
        final hour = DateTime.now().hour;
        if (hour >= 6 && hour < 12) {
          devices[index].kelvinTemp = 5000;
          devices[index].brightness = 0.9;
        } else if (hour >= 12 && hour < 18) {
          devices[index].kelvinTemp = 4000;
          devices[index].brightness = 1.0;
        } else {
          devices[index].kelvinTemp = 2700;
          devices[index].brightness = 0.4;
        }
      } else if (mode == 'NightPath') {
        devices[index].brightness = 0.08;
        devices[index].kelvinTemp = 2200;
      } else if (mode == 'FocusTask') {
        devices[index].brightness = 1.0;
        devices[index].kelvinTemp = 6500;
      }

      notifyListeners();
      _syncDeviceToCloud(devices[index]);
    }
  }

  void updateDeviceBrightness(String id, double val) {
    final index = devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      devices[index].brightness = val;
      notifyListeners();
      _syncDeviceToCloud(devices[index]);
    }
  }

  void updateDeviceTargetTemp(String id, double val) {
    final index = devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      devices[index].targetTemp = val;
      notifyListeners();
      _syncDeviceToCloud(devices[index]);
    }
  }

  void updateDeviceFanSpeed(String id, String val) {
    final index = devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      devices[index].fanSpeed = val;
      notifyListeners();
      _syncDeviceToCloud(devices[index]);
    }
  }

  void updateDeviceColorTemp(String id, double val) {
    final index = devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      devices[index].colorTemp = val;
      notifyListeners();
      _syncDeviceToCloud(devices[index]);
    }
  }

  void updateDeviceColor(String id, int? hex) {
    final index = devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      devices[index].colorHex = hex;
      notifyListeners();
      _syncDeviceToCloud(devices[index]);
    }
  }

  final List<SmartNotification> _notifications = [];
  List<SmartNotification> get notifications => _notifications;
  bool notifySecurity = true; bool notifyDevices = true; bool notifyPeople = true;

  void updateNotificationPreferences({required bool security, required bool devices, required bool people}) {
    notifySecurity = security;
    notifyDevices = devices;
    notifyPeople = people;
    _activities.insert(0, 'Notification preferences updated.');
    notifyListeners();
  }

  void addNotification(SmartNotification n) {
    _notifications.insert(0, n);
    NotificationService().showNotification(id: n.id.hashCode, title: n.title, body: n.body);
    notifyListeners();
  }
  void markAllNotificationsAsRead() { for (var n in _notifications) { n.isRead = true; } notifyListeners(); }
  void markSingleNotificationAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) { _notifications[index].isRead = true; notifyListeners(); }
  }
  int get unreadNotificationsCount => _notifications.where((n) => !n.isRead).length;

  final List<Scenario> _scenarios = [
    Scenario(
      id: 'S001',
      name: 'Good Morning',
      iconName: 'morning',
      propertyId: 'H001',
      isPredefined: false,
      deviceActions: {'D001': true, 'D002': true, 'D007': true, 'D015': false},
    ),
    Scenario(
      id: 'S002',
      name: 'Good Night / Sleep',
      iconName: 'sleep',
      propertyId: 'H001',
      isPredefined: false,
      deviceActions: {'D001': false, 'D003': false, 'D006': true, 'D007': false, 'D015': false},
    ),
    Scenario(
      id: 'S003',
      name: 'Movie Night',
      iconName: 'movie',
      propertyId: 'H001',
      isPredefined: false,
      deviceActions: {'D001': false, 'D002': true, 'D007': false, 'D015': true},
    ),
    Scenario(
      id: 'S004',
      name: 'Leaving Home',
      iconName: 'away',
      propertyId: 'H001',
      isPredefined: false,
      deviceActions: {'D001': false, 'D002': false, 'D003': false, 'D006': true, 'D007': false, 'D015': false},
    ),
  ];
  List<Scenario> get scenarios => _scenarios;
  final List<String> _activities = ['Security ready.'];
  List<String> get activities => _activities;

  final SpeakerAlarmSettings speakerSettings = SpeakerAlarmSettings();
  final RgbAlarmSettings rgbSettings = RgbAlarmSettings();
  final SmokeDetectorSettings smokeSettings = SmokeDetectorSettings();

  void selectHouse(String id) { selectedHouseId = id; notifyListeners(); }
  void setHomeMode(HomeMode mode) { homeMode = mode; notifyListeners(); }

  void triggerLightingScene(String name) {
    _activities.insert(0, 'Lighting scene activated: $name');
    for (var d in devices.where((dev) => dev.type == 'light')) {
      if (name == 'Bright' || name == 'Daylight') {
        d.isOn = true;
        d.brightness = 1.0;
        d.kelvinTemp = 5500;
      } else if (name == 'Relax' || name == 'Warm') {
        d.isOn = true;
        d.brightness = 0.5;
        d.kelvinTemp = 2700;
      } else if (name == 'Focus') {
        d.isOn = true;
        d.brightness = 0.9;
        d.kelvinTemp = 6000;
      } else if (name == 'Night') {
        d.isOn = true;
        d.brightness = 0.1;
        d.kelvinTemp = 2200;
      }
    }
    notifyListeners();
  }

  void addHouse(House h) {
    houses.add(h);
    selectedHouseId = h.id;
    _activities.insert(0, 'Property added: ${h.name}');
    notifyListeners();
  }
  void addFloor(Floor f) { floors.add(f); notifyListeners(); }
  void addRoom(Room r) { rooms.add(r); notifyListeners(); }
  void addDevice(Device d) {
    devices.add(d);
    _cloud.registerDevices([d]);
    _activities.insert(0, '.NET Relay registered: ${d.name}');
    notifyListeners();
  }
  void addUser(HomeUser u) { users.add(u); notifyListeners(); }
  void toggleDeviceFavorite(String id) {
    final idx = devices.indexWhere((d) => d.id == id);
    if (idx != -1) { devices[idx].isFavorite = !devices[idx].isFavorite; notifyListeners(); }
  }

  void addScenario(Scenario s) {
    _scenarios.add(s);
    _activities.insert(0, 'Scene created: ${s.name}');
    notifyListeners();
  }

  void updateScenario(Scenario s) {
    final idx = _scenarios.indexWhere((sc) => sc.id == s.id);
    if (idx != -1) {
      _scenarios[idx] = s;
      _activities.insert(0, 'Scene updated: ${s.name}');
      notifyListeners();
    }
  }

  void deleteScenario(String id) {
    final idx = _scenarios.indexWhere((sc) => sc.id == id);
    if (idx != -1) {
      final name = _scenarios[idx].name;
      _scenarios.removeAt(idx);
      _activities.insert(0, 'Scene deleted: $name');
      notifyListeners();
    }
  }

  void triggerScenario(String id) async {
    final idx = _scenarios.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    final scenario = _scenarios[idx];

    _activities.insert(0, 'Activating scene: ${scenario.name}...');
    notifyListeners();

    for (var entry in scenario.deviceActions.entries) {
      final deviceId = entry.key;
      final targetState = entry.value;

      final devIdx = devices.indexWhere((d) => d.id == deviceId);
      if (devIdx != -1) {
        devices[devIdx].isOn = targetState;
        devices[devIdx].status = targetState ? 'ON' : 'OFF';
        try {
          await _cloud.sendCommand(deviceId, 'SetStatus', parameters: {'status': targetState ? 'ON' : 'OFF'});
        } catch (e) {
          debugPrint('Error triggering scenario device $deviceId: $e');
        }
      }
    }

    _activities.insert(0, 'Scene active: ${scenario.name}');
    notifyListeners();
  }

  void saveAlarmSettings() {}
}
