import 'package:flutter/material.dart';
import '../../models/device.dart';
import '../../widgets/device_tile.dart';
import '../../services/app_state.dart';
import 'device_control_screen.dart';
import 'provisioning_screen.dart';

class DevicesScreen extends StatefulWidget {
  final List<Device> devices; // Backwards compatibility if needed

  const DevicesScreen({
    super.key,
    this.devices = const [],
  });

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'light',
    'ac',
    'curtain',
    'window',
    'lock',
    'gate',
    'garage',
    'camera',
    'sensor',
    'smoke_detector',
    'gas_detector',
    'water_tank',
    'solar',
    'battery',
    'ev_charger',
    'fridge',
    'tv',
    'speaker',
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, child) {
        final state = AppState();
        final allPropertyDevices = state.selectedHouseDevices;

        final filteredDevices = allPropertyDevices.where((device) {
          final matchesSearch = device.name.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesCategory = _selectedCategory == 'All' || device.type == _selectedCategory;
          return matchesSearch && matchesCategory;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Hardware Registry',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded),
                tooltip: 'Pair Hardware (QR/NFC)',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const ProvisioningScreen()),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Search input box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Find hardware nodes...',
                    prefixIcon: Icon(Icons.search_rounded, color: state.activeThemeColor),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Categories Selector chips row
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat.replaceAll('_', ' ').toUpperCase()),
                        selected: isSelected,
                        selectedColor: state.activeThemeColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),

              // Main Devices listing grid
              Expanded(
                child: filteredDevices.isEmpty
                    ? const Center(child: Text('No active devices match filters.'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredDevices.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.85,
                        ),
                        itemBuilder: (context, index) {
                          final device = filteredDevices[index];
                          return DeviceTile(
                            device: device,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DeviceControlScreen(device: device),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: state.activeThemeColor,
            foregroundColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const ProvisioningScreen()),
              );
            },
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Pair Device', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}
