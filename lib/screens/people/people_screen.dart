import 'package:flutter/material.dart';
import '../../services/app_state.dart';
import '../../widgets/person_tile.dart';
import 'add_member_screen.dart';

class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, child) {
        final people = AppState().users;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'People',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          body: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: people.length,
            separatorBuilder: (context, index) {
              return const SizedBox(height: 12);
            },
            itemBuilder: (context, index) {
              return PersonTile(
                user: people[index],
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF2E7D32),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddMemberScreen(),
                    ),
              );
            },
            icon: const Icon(
              Icons.person_add,
              color: Colors.white,
            ),
            label: const Text(
              'Add New Member',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
