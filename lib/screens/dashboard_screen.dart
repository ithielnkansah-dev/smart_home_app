import 'dart:io';
import 'package:flutter/material.dart';
import '../models/house.dart';
import '../services/app_state.dart';
import '../models/home_mode.dart';
import '../widgets/app_menu_drawer.dart';
import '../widgets/device_tile.dart';
import '../widgets/property_selector.dart';
import '../widgets/smart_home_card.dart';
import 'devices/device_control_screen.dart';
import 'menu/notifications_center_screen.dart';
import 'profile/profile_screen.dart';
import 'auth/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AppState appState = AppState();

  @override
  Widget build(BuildContext context) {
    final activeColor = appState.activeThemeColor;

    return AnimatedBuilder(
      animation: appState,
      builder: (context, child) {
        final currentHouse = appState.selectedHouse;
        final currentHouseName = currentHouse?.name ?? 'Select House';
        
        final favoriteDevices = appState.selectedHouseDevices
            .where((device) => device.isFavorite)
            .toList();

        return Scaffold(
          drawer: const AppMenuDrawer(),
          appBar: AppBar(
            titleSpacing: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Open Menu',
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                if (appState.isLoggedIn) {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const ProfileScreen()));
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const LoginScreen()));
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: activeColor.withValues(alpha: 0.15),
                      backgroundImage: appState.profileImagePath != null && File(appState.profileImagePath!).existsSync()
                          ? FileImage(File(appState.profileImagePath!))
                          : null,
                      child: appState.profileImagePath == null || !File(appState.profileImagePath!).existsSync()
                          ? Icon(
                              appState.isLoggedIn ? Icons.person_rounded : Icons.person_off_rounded,
                              size: 16,
                              color: activeColor,
                            )
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          appState.isLoggedIn
                              ? (appState.currentUser?.name ?? 'Home Owner')
                              : 'Logged Out',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          appState.isLoggedIn ? 'ONLINE • Account' : 'Tap to Login',
                          style: TextStyle(
                            fontSize: 9,
                            color: appState.isLoggedIn ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey, size: 20),
                  ],
                ),
              ),
            ),
            actions: [
              _NotificationBell(unreadCount: appState.unreadNotificationsCount),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. PROPERTY & WEATHER
                Row(
                  children: [
                    Expanded(child: PropertySelector(selectedProperty: currentHouseName, onTap: _showPropertySelector)),
                    const SizedBox(width: 12),
                    _buildWeatherWidget(),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. QUICK STATS & SYSTEM HEALTH
                _buildQuickStatsGrid(context),
                const SizedBox(height: 20),

                // 3. POWER MODES (Section 9)
                const Text('Power Source', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildPowerModeSelector(),
                const SizedBox(height: 25),

                // 4. HOME MODE SELECTOR
                _buildHomeModeSelector(context),
                const SizedBox(height: 25),

                // 5. HIGHLIGHTS (Section 14)
                _buildHighlightsSection(context),
                const SizedBox(height: 25),

                // 6. FAVORITE DEVICES (Section 8, 12 Garage included)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Favorite Controls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(onPressed: _showManageFavoritesDialog, child: Text('Edit', style: TextStyle(color: activeColor))),
                  ],
                ),
                _buildFavoritesGrid(favoriteDevices),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeatherWidget() {
    return SmartHomeCard(
      onTap: () {
        appState.fetchLiveWeather();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Refreshing live weather...')),
        );
      },
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          if (appState.isWeatherLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(appState.weatherIcon, color: appState.weatherIconColor, size: 20),
          const SizedBox(height: 4),
          Text(
            '${appState.weatherTemp.round()}°C',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            appState.weatherCondition,
            style: const TextStyle(fontSize: 9, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerModeSelector() {
    return SmartHomeCard(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: PowerSource.values.map((source) {
          bool selected = appState.powerSource == source;
          IconData icon;
          switch(source) {
            case PowerSource.solar: icon = Icons.solar_power_rounded; break;
            case PowerSource.battery: icon = Icons.battery_charging_full_rounded; break;
            case PowerSource.grid: icon = Icons.electric_bolt_rounded; break;
          }
          return GestureDetector(
            onTap: () => appState.setPowerSource(source),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? appState.activeThemeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: selected ? Colors.white : Colors.grey),
                  const SizedBox(width: 8),
                  Text(source.name.toUpperCase(), style: TextStyle(color: selected ? Colors.white : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHighlightsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Smart Highlights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _highlightCard(context, 'AI Optimization', 'System reduced power usage by 12% today.', Icons.auto_graph_rounded, Colors.blue),
              _highlightCard(context, 'Security Report', 'No abnormal motion detected in last 24h.', Icons.verified_user_rounded, Colors.green),
              _highlightCard(context, 'Health Check', 'Air quality is excellent in all rooms.', Icons.health_and_safety_rounded, Colors.purple),
            ],
          ),
        ),
      ],
    );
  }

  Widget _highlightCard(BuildContext context, String title, String desc, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      child: SmartHomeCard(
        color: isDark ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isDark ? color.withValues(alpha: 0.9) : color,
              size: 20,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.8,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _StatCard(title: 'Indoor Temp', value: '${appState.indoorTemp.toStringAsFixed(1)}°C', icon: Icons.thermostat_rounded, color: Colors.orange),
        _StatCard(title: 'Power Load', value: '${appState.currentPowerLoad.toStringAsFixed(2)} kW', icon: Icons.bolt_rounded, color: Colors.amber),
        _StatCard(title: 'Security', value: appState.securityStatus, icon: Icons.shield_rounded, color: appState.activeThemeColor),
        _StatCard(title: 'System Health', value: appState.offlineDevicesCount > 0 ? '${appState.offlineDevicesCount} Offline' : 'All Online', icon: Icons.cloud_done_rounded, color: appState.offlineDevicesCount > 0 ? Colors.red : Colors.blue),
      ],
    );
  }

  Widget _buildHomeModeSelector(BuildContext context) {
    return SmartHomeCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: HomeMode.values.map((mode) {
          bool isSelected = appState.homeMode == mode;
          return GestureDetector(
            onTap: () => appState.setHomeMode(mode),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? appState.activeThemeColor : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.withValues(alpha: 0.3)),
                  ),
                  child: Icon(_getModeIcon(mode), color: isSelected ? Colors.white : Colors.grey, size: 20),
                ),
                const SizedBox(height: 6),
                Text(mode.name, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? appState.activeThemeColor : Colors.grey)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFavoritesGrid(List<dynamic> favorites) {
    if (favorites.isEmpty) return SmartHomeCard(child: const Center(child: Text('No favorites selected.')));
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: favorites.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.85),
      itemBuilder: (context, index) {
        final device = favorites[index];
        return DeviceTile(device: device, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DeviceControlScreen(device: device))));
      },
    );
  }

  IconData _getModeIcon(HomeMode mode) {
    switch (mode) {
      case HomeMode.home: return Icons.home_rounded;
      case HomeMode.away: return Icons.flight_takeoff_rounded;
      case HomeMode.night: return Icons.nights_stay_rounded;
      case HomeMode.sleep: return Icons.bedtime_rounded;
      case HomeMode.vacation: return Icons.beach_access_rounded;
    }
  }

  void _showPropertySelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Select Property',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            ...appState.houses.map((h) {
              final isSelected = h.id == appState.selectedHouseId;
              return ListTile(
                leading: Icon(
                  Icons.home_rounded,
                  color: isSelected ? appState.activeThemeColor : Colors.grey,
                ),
                title: Text(
                  h.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(h.address),
                trailing: isSelected
                    ? Icon(Icons.check_circle_rounded, color: appState.activeThemeColor)
                    : null,
                onTap: () {
                  appState.selectHouse(h.id);
                  Navigator.pop(context);
                },
              );
            }),
            const Divider(),
            ListTile(
              leading: Icon(Icons.add_location_alt_rounded, color: appState.activeThemeColor),
              title: const Text('Add New Property', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Add another house, office, or apartment'),
              onTap: () {
                Navigator.pop(context);
                _showAddPropertyDialog(context);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showAddPropertyDialog(BuildContext context) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Property'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Property Name',
                hintText: 'e.g. Vacation Home, Office',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: 'e.g. 456 Palm Ave',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: appState.activeThemeColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final address = addressController.text.trim();

              final newHouse = House(
                id: 'H${DateTime.now().millisecondsSinceEpoch}',
                name: name,
                address: address.isEmpty ? 'Main St' : address,
              );

              appState.addHouse(newHouse);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added new property: $name')),
              );
            },
            child: const Text('Add Property'),
          ),
        ],
      ),
    );
  }

  void _showManageFavoritesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Favorites'),
        content: SizedBox(
          width: double.maxFinite,
          child: AnimatedBuilder(
            animation: appState,
            builder: (context, child) => ListView.builder(
              shrinkWrap: true,
              itemCount: appState.selectedHouseDevices.length,
              itemBuilder: (context, index) {
                final d = appState.selectedHouseDevices[index];
                return CheckboxListTile(title: Text(d.name), value: d.isFavorite, onChanged: (_) => appState.toggleDeviceFavorite(d.id));
              },
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final int unreadCount;
  const _NotificationBell({required this.unreadCount});
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const NotificationsCenterScreen())), icon: const Icon(Icons.notifications_none_rounded)),
        if (unreadCount > 0)
          Positioned(right: 8, top: 8, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 8)))),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value; final IconData icon; final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return SmartHomeCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: color, size: 14), const SizedBox(width: 4), Text(title, style: const TextStyle(fontSize: 9, color: Colors.grey))]),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
