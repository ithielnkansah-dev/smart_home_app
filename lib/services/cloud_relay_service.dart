import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudRelayService {
  static final CloudRelayService _instance = CloudRelayService._internal();
  factory CloudRelayService() => _instance;
  CloudRelayService._internal();

  // 10.0.2.2 is the special alias for host's localhost in Android Emulators.
  // Uses http://localhost:5000 when running on Web or Desktop platforms.
  String get baseUrl => kIsWeb || !defaultTargetPlatform.toString().contains('android')
      ? 'http://localhost:5000'
      : 'http://10.0.2.2:5000';

  bool _isManualOffline = false;

  bool get isConnected => !_isManualOffline;

  void setCloudStatus(bool online) {
    _isManualOffline = !online;
  }

  /// Pings the .NET 9 Relay server to verify connectivity.
  Future<bool> checkConnection() async {
    if (_isManualOffline) return false;
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/devices'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('CloudRelayService connection check error: $e');
      return false;
    }
  }

  /// Fetches all device states from the .NET 9 Relay backend.
  Future<List<dynamic>> getDevices() async {
    if (_isManualOffline) {
      throw Exception('Cloud Relay is manually set to offline mode.');
    }
    final response = await http
        .get(Uri.parse('$baseUrl/api/devices'))
        .timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to fetch devices from .NET Relay (HTTP ${response.statusCode})');
    }
  }

  /// Gets a specific device state from .NET Relay backend.
  Future<Map<String, dynamic>> getDevice(String id) async {
    if (_isManualOffline) {
      throw Exception('Cloud Relay is manually set to offline mode.');
    }
    final response = await http
        .get(Uri.parse('$baseUrl/api/devices/$id'))
        .timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Device $id not found on .NET Relay (HTTP ${response.statusCode})');
    }
  }

  /// Toggles device ON/OFF state via .NET Relay backend (`POST /api/devices/{id}/toggle`).
  Future<bool> toggleDevice(String id) async {
    if (_isManualOffline) {
      throw Exception('Cloud Relay is manually set to offline mode.');
    }
    final response = await http
        .post(Uri.parse('$baseUrl/api/devices/$id/toggle'))
        .timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final String status = data['status'] ?? 'OFF';
      return status == 'ON';
    } else {
      throw Exception('Failed to toggle device $id on .NET Relay (HTTP ${response.statusCode})');
    }
  }

  /// Sends a command to the .NET 9 Relay backend.
  Future<Map<String, dynamic>> sendCommand(String deviceId, String action, {Map<String, String>? parameters}) async {
    if (_isManualOffline) {
      throw Exception('Cloud Relay is manually set to offline mode.');
    }
    final body = json.encode({
      'deviceId': deviceId,
      'homeId': 'H001',
      'action': action,
      'parameters': parameters ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    });

    final response = await http
        .post(
          Uri.parse('$baseUrl/api/devices/command'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to dispatch command to .NET Relay (HTTP ${response.statusCode})');
    }
  }

  /// Bulk registers/syncs a list of local devices to the .NET 9 Relay backend (`POST /api/devices/bulk`).
  Future<List<dynamic>> registerDevices(List<dynamic> localDevices) async {
    if (_isManualOffline) {
      throw Exception('Cloud Relay is manually set to offline mode.');
    }
    final payload = localDevices.map((d) {
      try {
        final map = (d as dynamic).toJson() as Map<String, dynamic>;
        map['lastUpdated'] = DateTime.now().toIso8601String();
        return map;
      } catch (_) {
        return {
          'id': d.id,
          'name': d.name,
          'type': d.type,
          'status': d.status,
          'isOnline': d.isOnline,
          'brightness': (d.brightness * 100).round(),
          'temperature': d.targetTemp,
          'lastUpdated': DateTime.now().toIso8601String(),
        };
      }
    }).toList();

    final response = await http
        .post(
          Uri.parse('$baseUrl/api/devices/bulk'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(payload),
        )
        .timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to bulk register devices on .NET Relay (HTTP ${response.statusCode})');
    }
  }

  /// Directly updates a device state on the .NET 9 Relay server (`POST /api/devices/{id}/state`).
  Future<Map<String, dynamic>> updateDeviceState(Map<String, dynamic> deviceState) async {
    if (_isManualOffline) {
      throw Exception('Cloud Relay is manually set to offline mode.');
    }
    final String id = deviceState['id'];
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/devices/$id/state'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(deviceState),
        )
        .timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to update device state on .NET Relay (HTTP ${response.statusCode})');
    }
  }
}
