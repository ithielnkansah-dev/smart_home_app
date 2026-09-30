import 'cloud_relay_service.dart';

/// Legacy wrapper forwarding to the real .NET 9 [CloudRelayService].
class MockCloudService implements CloudRelayService {
  static final MockCloudService _instance = MockCloudService._internal();
  factory MockCloudService() => _instance;
  MockCloudService._internal();

  final CloudRelayService _relay = CloudRelayService();

  @override
  String get baseUrl => _relay.baseUrl;

  @override
  bool get isConnected => _relay.isConnected;

  @override
  void setCloudStatus(bool online) => _relay.setCloudStatus(online);

  @override
  Future<bool> checkConnection() => _relay.checkConnection();

  @override
  Future<List<dynamic>> getDevices() => _relay.getDevices();

  @override
  Future<Map<String, dynamic>> getDevice(String id) => _relay.getDevice(id);

  @override
  Future<bool> toggleDevice(String id) => _relay.toggleDevice(id);

  @override
  Future<Map<String, dynamic>> sendCommand(String deviceId, String action, {Map<String, String>? parameters}) =>
      _relay.sendCommand(deviceId, action, parameters: parameters);

  @override
  Future<List<dynamic>> registerDevices(List<dynamic> localDevices) => _relay.registerDevices(localDevices);

  @override
  Future<Map<String, dynamic>> updateDeviceState(Map<String, dynamic> deviceState) =>
      _relay.updateDeviceState(deviceState);
}
