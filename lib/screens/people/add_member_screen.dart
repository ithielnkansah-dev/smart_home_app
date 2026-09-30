
import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/app_state.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedRole = 'Family';

  bool _controlDevices = true;
  bool _viewCameras = true;
  bool _controlSecurity = false;
  bool _manageOtherUsers = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _addMember() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the member name and email.'),
        ),
      );
      return;
    }

    final user = HomeUser(
      id: 'U${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      role: '$_selectedRole • Custom Access',
      controlDevices: _controlDevices,
      viewCameras: _viewCameras,
      controlSecurity: _controlSecurity,
      manageOtherUsers: _manageOtherUsers,
    );

    AppState().addUser(user);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Member added successfully.'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Member'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Member Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: const InputDecoration(
              labelText: 'Role',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Family',
                child: Text('Family'),
              ),
              DropdownMenuItem(
                value: 'Guest',
                child: Text('Guest'),
              ),
              DropdownMenuItem(
                value: 'Installer',
                child: Text('Installer'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _selectedRole = value;
              });
            },
          ),
          const SizedBox(height: 25),

          const Text(
            'Permissions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          _permissionSwitch(
            'Control Devices',
            _controlDevices,
                (value) => setState(() => _controlDevices = value),
          ),
          _permissionSwitch(
            'View Cameras',
            _viewCameras,
                (value) => setState(() => _viewCameras = value),
          ),
          _permissionSwitch(
            'Control Security',
            _controlSecurity,
                (value) => setState(() => _controlSecurity = value),
          ),
          _permissionSwitch(
            'Manage Other Users',
            _manageOtherUsers,
                (value) => setState(() => _manageOtherUsers = value),
          ),

          const SizedBox(height: 25),

          SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: _addMember,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Send Invitation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _permissionSwitch(
      String title,
      bool value,
      ValueChanged<bool> onChanged,
      ) {
    return Card(
      child: SwitchListTile(
        title: Text(title),
        value: value,
        activeColor: const Color(0xFF2E7D32),
        onChanged: onChanged,
      ),
    );
  }
}