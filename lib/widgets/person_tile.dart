import 'package:flutter/material.dart';
import '../models/user.dart';
import 'smart_home_card.dart';

class PersonTile extends StatelessWidget {
  final HomeUser user;

  const PersonTile({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return SmartHomeCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Icon(
              Icons.person_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  user.role,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
