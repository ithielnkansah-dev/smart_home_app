import 'package:flutter/material.dart';
import '../../models/scenario.dart';
import '../../services/app_state.dart';
import '../../widgets/smart_home_card.dart';

class ModesScreen extends StatelessWidget {
  const ModesScreen({super.key});

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'dark_mode':
        return Icons.dark_mode_rounded;
      case 'blinds_closed':
        return Icons.blinds_closed_rounded;
      case 'movie':
        return Icons.movie_creation_rounded;
      case 'curtains_closed':
        return Icons.curtains_rounded;
      case 'wb_sunny':
      case 'morning':
        return Icons.wb_sunny_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'away':
        return Icons.flight_takeoff_rounded;
      case 'sleep':
        return Icons.bedtime_rounded;
      case 'party':
        return Icons.celebration_rounded;
      case 'work':
        return Icons.work_rounded;
      case 'outdoor':
        return Icons.deck_rounded;
      case 'bed':
        return Icons.bed_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, child) {
        final state = AppState();
        final scenarios = state.selectedHouseScenarios;
        final activeColor = state.activeThemeColor;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Modes & Scenarios',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: scenarios.isEmpty
              ? const Center(child: Text('No modes configured for this property.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: scenarios.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final scenario = scenarios[index];
                    return SmartHomeCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: activeColor.withValues(alpha: 0.1),
                          child: Icon(_getIconData(scenario.iconName), color: activeColor),
                        ),
                        title: Text(scenario.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          scenario.isPredefined
                              ? 'System Predefined Scenario'
                              : 'Custom Mode • ${scenario.deviceActions.length} automation(s)',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.play_circle_fill_rounded, color: activeColor, size: 32),
                              onPressed: () {
                                state.triggerScenario(scenario.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Activated scenario: ${scenario.name}')),
                                );
                              },
                            ),
                            if (!scenario.isPredefined) ...[
                              IconButton(
                                icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                                onPressed: () {
                                  _showCreateOrEditScenarioDialog(context, scenario: scenario);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                onPressed: () {
                                  state.deleteScenario(scenario.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Deleted scenario: ${scenario.name}')),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: activeColor,
            onPressed: () {
              _showCreateOrEditScenarioDialog(context);
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Create Mode', style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }

  void _showCreateOrEditScenarioDialog(BuildContext context, {Scenario? scenario}) {
    final isEditing = scenario != null;
    final nameController = TextEditingController(text: scenario?.name ?? '');
    String selectedIcon = scenario?.iconName ?? 'morning';
    final state = AppState();
    final currentDevices = state.selectedHouseDevices;
    final Map<String, bool> selectedActions = Map.from(scenario?.deviceActions ?? {});

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final activeColor = state.activeThemeColor;

            return AlertDialog(
              title: Text(isEditing ? 'Edit Mode' : 'Create Mode'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Mode Name',
                        hintText: 'e.g. Good Morning',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Icon Selection', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: ['home', 'away', 'morning', 'sleep', 'movie', 'party', 'work', 'outdoor'].map((iconName) {
                        final isSelected = selectedIcon == iconName;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = iconName;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
                              border: Border.all(color: isSelected ? activeColor : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_getIconData(iconName), color: isSelected ? activeColor : Colors.grey),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 25),
                    const Text('Select Automations', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    if (currentDevices.isEmpty)
                      const Text('No devices available.', style: TextStyle(color: Colors.grey)),
                    ...currentDevices.map((device) {
                      final isIncluded = selectedActions.containsKey(device.id);
                      final targetState = selectedActions[device.id] ?? false;

                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(device.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          isIncluded ? (targetState ? 'Action: Turn ON' : 'Action: Turn OFF') : 'Not included in scene',
                          style: TextStyle(
                            fontSize: 11,
                            color: isIncluded ? (targetState ? Colors.green : Colors.orange) : Colors.grey,
                            fontWeight: isIncluded ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        value: isIncluded,
                        activeColor: activeColor,
                        onChanged: (checked) {
                          setDialogState(() {
                            if (checked == true) {
                              selectedActions[device.id] = true;
                            } else {
                              selectedActions.remove(device.id);
                            }
                          });
                        },
                        secondary: isIncluded
                            ? Switch(
                                value: targetState,
                                activeColor: activeColor,
                                onChanged: (switchVal) {
                                  setDialogState(() {
                                    selectedActions[device.id] = switchVal;
                                  });
                                },
                              )
                            : null,
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final modeName = nameController.text.trim();
                    if (modeName.isEmpty) return;

                    if (isEditing) {
                      state.updateScenario(Scenario(
                        id: scenario.id,
                        name: modeName,
                        iconName: selectedIcon,
                        propertyId: scenario.propertyId,
                        isPredefined: false,
                        deviceActions: selectedActions,
                      ));
                    } else {
                      state.addScenario(Scenario(
                        id: 'S${DateTime.now().millisecondsSinceEpoch}',
                        name: modeName,
                        iconName: selectedIcon,
                        propertyId: state.selectedHouseId,
                        isPredefined: false,
                        deviceActions: selectedActions,
                      ));
                    }
                    Navigator.pop(context);
                  },
                  child: Text(isEditing ? 'Save' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
