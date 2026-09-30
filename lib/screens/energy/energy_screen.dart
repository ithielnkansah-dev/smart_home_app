import 'package:flutter/material.dart';
import '../../services/app_state.dart';
import '../../widgets/smart_home_card.dart';

class EnergyScreen extends StatelessWidget {
  const EnergyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, child) {
        final state = AppState();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final powerLoad = state.currentPowerLoad;

        // Calculated renewable power metrics
        final solarGen = 3.8; // 3.8 kW Solar PV Generation
        final batterySoC = 84; // 84% Battery Storage
        final gridExport = (solarGen - powerLoad).clamp(0.0, 10.0);
        final gridImport = (powerLoad - solarGen).clamp(0.0, 10.0);
        final costPerHour = (gridImport * 0.18).toStringAsFixed(2);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Energy & Renewables', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 1. LIVE POWER FLOW SUMMARY CARD - FULLY ADAPTIVE TO LIGHT/DARK MODE
              SmartHomeCard(
                color: isDark ? const Color(0xFF1E1E1E) : Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('LIVE POWER FLOW', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              const SizedBox(height: 4),
                              Text('Self-Consumption Active', style: TextStyle(color: isDark ? Colors.greenAccent : Colors.green.shade700, fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                            child: Text('\$$costPerHour/hr', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ],
                      ),
                      Divider(color: isDark ? Colors.white24 : Colors.black12, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _flowMetric('Solar PV', '${solarGen.toStringAsFixed(1)} kW', Icons.solar_power_rounded, Colors.amber, isDark),
                          _flowMetric('Home Load', '${powerLoad.toStringAsFixed(2)} kW', Icons.bolt_rounded, Colors.blue, isDark),
                          _flowMetric('Grid Net', gridExport > 0 ? '+${gridExport.toStringAsFixed(1)} kW' : '-${gridImport.toStringAsFixed(1)} kW', Icons.electric_meter_rounded, isDark ? Colors.greenAccent : Colors.green.shade700, isDark),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. RENEWABLE STORAGE & MOBILITY CARDS
              const Text('Storage & Mobility', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: SmartHomeCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.battery_charging_full_rounded, color: Colors.green, size: 20),
                              SizedBox(width: 6),
                              Text('Battery SoC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('$batterySoC%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(value: batterySoC / 100, minHeight: 8, color: Colors.green, backgroundColor: Colors.grey.shade200),
                          ),
                          const SizedBox(height: 6),
                          const Text('Charging from Solar', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SmartHomeCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.ev_station_rounded, color: Colors.blue, size: 20),
                              SizedBox(width: 6),
                              Text('EV Charger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text('7.2 kW', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                            child: const Text('Solar Surplus Mode', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 3. TARIFF & COST OPTIMIZATION (Section 9.3)
              const Text('Tariff & Load Optimization', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SmartHomeCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: isDark ? Colors.white24 : Colors.black12,
                    child: Icon(Icons.auto_graph_rounded, color: isDark ? Colors.white : Colors.black87),
                  ),
                  title: const Text('Off-Peak Smart Scheduling', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('EV charging & heavy loads scheduled for lowest rate window (11pm - 6am).'),
                  trailing: Switch(
                    value: true,
                    activeThumbColor: isDark ? Colors.white : Colors.black,
                    onChanged: (val) {},
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _flowMetric(String label, String value, IconData icon, Color color, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 10)),
      ],
    );
  }
}
