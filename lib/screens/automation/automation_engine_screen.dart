import 'package:flutter/material.dart';
import '../../models/automation_rule.dart';
import '../../services/app_state.dart';
import '../../widgets/smart_home_card.dart';

class AutomationEngineScreen extends StatelessWidget {
  const AutomationEngineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, child) {
        final state = AppState();
        final rules = state.automationRules;
        final activeColor = state.activeThemeColor;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Automation Engine', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: rules.isEmpty
              ? const Center(child: Text('No IF-THEN automations created yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: rules.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final rule = rules[index];
                    return SmartHomeCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: rule.isEnabled
                              ? activeColor.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.15),
                          child: Icon(
                            _getTriggerIcon(rule.triggerType),
                            color: rule.isEnabled ? activeColor : Colors.grey,
                          ),
                        ),
                        title: Text(rule.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'IF: ${_formatTriggerText(rule)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue),
                            ),
                            Text(
                              'THEN: ${_formatActionText(state, rule)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.play_arrow_rounded, color: Colors.green),
                              tooltip: 'Test Automation Rule',
                              onPressed: () {
                                state.executeAutomationRule(rule);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Triggered rule: ${rule.name}')),
                                );
                              },
                            ),
                            Switch(
                              value: rule.isEnabled,
                              activeColor: activeColor,
                              onChanged: (val) {
                                state.toggleAutomationRule(rule.id, val);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                              onPressed: () {
                                state.deleteAutomationRule(rule.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Deleted rule: ${rule.name}')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: activeColor,
            foregroundColor: Colors.white,
            onPressed: () => _showCreateRuleDialog(context, state),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Add IF-THEN Rule', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  IconData _getTriggerIcon(String type) {
    switch (type) {
      case 'motion': return Icons.directions_run_rounded;
      case 'temperature': return Icons.thermostat_rounded;
      case 'sunset': return Icons.wb_twilight_rounded;
      case 'water_leak': return Icons.water_damage_rounded;
      case 'gas_leak': return Icons.gas_meter_rounded;
      case 'co2_high': return Icons.co2_rounded;
      default: return Icons.bolt_rounded;
    }
  }

  String _formatTriggerText(AutomationRule rule) {
    switch (rule.triggerType) {
      case 'motion': return 'Motion detected in ${rule.triggerValue}';
      case 'temperature': return 'Room temperature > ${rule.triggerValue}°C';
      case 'sunset': return 'Sunset time reached';
      case 'water_leak': return 'Water leak detected';
      case 'gas_leak': return 'Gas / LPG leak detected';
      case 'co2_high': return 'CO₂ concentration exceeds ${rule.triggerValue} ppm';
      default: return '${rule.triggerType} ${rule.triggerCondition} ${rule.triggerValue}';
    }
  }

  String _formatActionText(AppState state, AutomationRule rule) {
    if (rule.actionDeviceId == 'WATER_VALVE') {
      return 'Close Main Water Valve automatically';
    } else if (rule.actionDeviceId == 'GAS_VALVE') {
      return 'Close Gas Valve & Trigger Siren Alarm';
    } else if (rule.actionDeviceId == 'ALL_LIGHTS') {
      return 'Turn ON All Home Lights to 100%';
    } else {
      final dev = state.devices.firstWhere((d) => d.id == rule.actionDeviceId, orElse: () => state.devices.first);
      return '${dev.name} -> ${rule.actionCommand} (${rule.actionValue ?? ''})';
    }
  }

  void _showCreateRuleDialog(BuildContext context, AppState state) {
    final nameController = TextEditingController(text: 'New Automation Rule');
    String selectedTriggerType = 'motion';
    String selectedActionDevice = state.devices.isNotEmpty ? state.devices.first.id : 'WATER_VALVE';
    String selectedActionCommand = 'turnOn';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create IF-THEN Automation Rule', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Rule Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedTriggerType,
                  decoration: const InputDecoration(labelText: 'IF Trigger Condition', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'motion', child: Text('IF Motion Detected')),
                    DropdownMenuItem(value: 'sunset', child: Text('IF Sunset Reached')),
                    DropdownMenuItem(value: 'temperature', child: Text('IF Temp > 28°C')),
                    DropdownMenuItem(value: 'water_leak', child: Text('IF Water Leak Detected')),
                    DropdownMenuItem(value: 'gas_leak', child: Text('IF Gas Leak Detected')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedTriggerType = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedActionDevice,
                  decoration: const InputDecoration(labelText: 'THEN Target Device', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: 'WATER_VALVE', child: Text('Main Water Shutoff Valve')),
                    const DropdownMenuItem(value: 'GAS_VALVE', child: Text('Main Gas Shutoff Valve')),
                    const DropdownMenuItem(value: 'ALL_LIGHTS', child: Text('All House Lights')),
                    ...state.devices.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedActionDevice = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: state.activeThemeColor, foregroundColor: Colors.white),
              onPressed: () {
                final name = nameController.text.trim();
                final newRule = AutomationRule(
                  id: 'R${DateTime.now().millisecondsSinceEpoch}',
                  name: name.isEmpty ? 'Automation Rule' : name,
                  triggerType: selectedTriggerType,
                  triggerCondition: 'detected',
                  triggerValue: 'Living Room',
                  actionDeviceId: selectedActionDevice,
                  actionCommand: selectedActionCommand,
                );
                state.addAutomationRule(newRule);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Automation rule added: $name')),
                );
              },
              child: const Text('Create Rule'),
            ),
          ],
        ),
      ),
    );
  }
}
