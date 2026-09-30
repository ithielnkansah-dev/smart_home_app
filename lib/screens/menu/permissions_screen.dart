import 'package:flutter/material.dart';
import '../../services/app_state.dart';
import '../../widgets/smart_home_card.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check permissions when returning to the app
      setState(() {});
    }
  }

  Future<PermissionStatus> _getPermissionStatus(String name) async {
    switch (name) {
      case 'Bluetooth':
        return await Permission.bluetooth.status;
      case 'Location':
        return await Permission.location.status;
      case 'Local Network':
        // Note: permission_handler doesn't have a specific "Local Network" permission for Android yet.
        // It's mostly an iOS thing. We'll simulate or use nearby devices.
        return await Permission.nearbyWifiDevices.status;
      case 'Notifications':
        return await Permission.notification.status;
      default:
        return PermissionStatus.denied;
    }
  }

  void _requestPermission(String name) async {
    Permission permission;
    switch (name) {
      case 'Bluetooth':
        permission = Permission.bluetooth;
        break;
      case 'Location':
        permission = Permission.location;
        break;
      case 'Local Network':
        permission = Permission.nearbyWifiDevices;
        break;
      case 'Notifications':
        permission = Permission.notification;
        break;
      default:
        return;
    }

    final status = await permission.request();
    if (status.isPermanentlyDenied) {
      _showSettingsDialog(name);
    }
    setState(() {});
  }

  void _showSettingsDialog(String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$name Permission Required'),
        content: Text('You have permanently denied this permission. Please enable it in the phone settings to use this feature.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final permissionNames = state.permissions.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Permissions'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Hardware & Data Access',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'These permissions allow the app to securely interact with your physical home hardware.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ...permissionNames.map((name) {
            return FutureBuilder<PermissionStatus>(
              future: _getPermissionStatus(name),
              builder: (context, snapshot) {
                final status = snapshot.data ?? PermissionStatus.denied;
                final isGranted = status.isGranted;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SmartHomeCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(_getPermissionDescription(name)),
                      trailing: Switch(
                        value: isGranted,
                        activeColor: state.activeThemeColor,
                        onChanged: (val) => _requestPermission(name),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          const SizedBox(height: 20),
          SmartHomeCard(
            color: state.activeThemeColor.withOpacity(0.1),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.settings_outlined, color: state.activeThemeColor),
              title: const Text('Advanced Phone Settings', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Open Android System settings directly.'),
              trailing: const Icon(Icons.open_in_new_rounded, size: 20),
              onTap: () => openAppSettings(),
            ),
          ),
        ],
      ),
    );
  }

  String _getPermissionDescription(String name) {
    switch (name) {
      case 'Bluetooth':
        return 'Used to find and pair with new hardware nearby.';
      case 'Location':
        return 'Required for geofencing and automatic home-arrival scenes.';
      case 'Local Network':
        return 'Needed to communicate with hubs and cameras over WiFi.';
      case 'Notifications':
        return 'Allows critical security alerts and device status updates.';
      default:
        return 'System access required for smart home functions.';
    }
  }
}
