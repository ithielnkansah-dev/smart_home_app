import 'package:flutter/material.dart';
import '../../widgets/floor_tile.dart';
import '../../services/app_state.dart';
import '../../models/floor.dart';
import 'floor_screen.dart';

class SpacesScreen extends StatelessWidget {
  const SpacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, child) {
        final state = AppState();
        final floors = state.selectedHouseFloors;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Property Spaces', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: floors.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final floor = floors[index];
              return FloorTile(
                floor: floor,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => FloorScreen(floor: floor)));
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: state.activeThemeColor,
            onPressed: () => _showAddFloor(context, state),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Floor', style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }

  void _showAddFloor(BuildContext context, AppState state) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Floor'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Floor Name', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  state.addFloor(Floor(
                    id: 'F${DateTime.now().millisecondsSinceEpoch}',
                    houseId: state.selectedHouseId,
                    name: controller.text.trim(),
                  ));
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
