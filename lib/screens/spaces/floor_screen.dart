import 'package:flutter/material.dart';
import '../../models/floor.dart';
import '../../models/room.dart';
import '../../widgets/room_tile.dart';
import '../../services/app_state.dart';
import '../../widgets/layout_visualizer.dart';
import 'room_screen.dart';

class FloorScreen extends StatelessWidget {
  final Floor floor;

  const FloorScreen({
    super.key,
    required this.floor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, child) {
        final rooms = AppState().rooms.where((r) => r.floorId == floor.id).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(
              floor.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Spatial Layout (CAD View)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              LayoutVisualizer(rooms: rooms),
              const SizedBox(height: 30),
              const Text(
                'Available Rooms',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...rooms.map((room) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RoomTile(
                  room: room,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoomScreen(
                          room: room,
                        ),
                      ),
                    );
                  },
                ),
              )).toList(),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppState().activeThemeColor,
            onPressed: () {
              _showAddRoom(context);
            },
            icon: const Icon(
              Icons.add,
              color: Colors.white,
            ),
            label: const Text(
              'Add New Room',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddRoom(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Room'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Room Name',
              hintText: 'e.g. Master Bedroom',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  final newRoom = Room(
                    id: 'R${DateTime.now().millisecondsSinceEpoch}',
                    houseId: floor.houseId,
                    floorId: floor.id,
                    name: controller.text.trim(),
                  );
                  AppState().addRoom(newRoom);
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
