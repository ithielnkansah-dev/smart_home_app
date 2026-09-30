import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/app_state.dart';
import '../../services/biometric_service.dart';
import '../../models/user.dart';
import '../../widgets/smart_home_card.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _twoFactorEnabled = true;

  Future<void> _pickProfileImage(BuildContext context, AppState state) async {
    final ImagePicker picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Set Profile Picture', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Colors.blueAccent),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Colors.green),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              if (state.profileImagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  title: const Text('Remove Picture', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    state.updateProfileImage(null);
                  },
                ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await picker.pickImage(source: source);
      if (image != null && mounted) {
        state.updateProfileImage(image.path);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully!')),
        );
      }
    }
  }

  void _showEditProfileDialog(BuildContext context, AppState state, HomeUser user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Profile Info', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newName = nameController.text.trim();
              final newEmail = emailController.text.trim();
              if (newName.isNotEmpty) {
                state.login(newEmail, newName);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully!')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of your Smart Home account?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Exit profile page
              state.logout();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully.')),
              );
            },
            child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, child) {
        final state = AppState();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final activeColor = state.activeThemeColor;
        final user = state.currentUser ?? HomeUser(id: 'U000', name: 'Guest User', email: 'guest@example.com', role: 'Guest');

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              if (state.isLoggedIn)
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () => _showEditProfileDialog(context, state, user),
                  tooltip: 'Edit Profile',
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 1. HERO USER AVATAR & IDENTITY CARD WITH IMAGE UPLOAD
              SmartHomeCard(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _pickProfileImage(context, state),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 46,
                              backgroundColor: activeColor.withValues(alpha: 0.15),
                              backgroundImage: state.profileImagePath != null && File(state.profileImagePath!).existsSync()
                                  ? FileImage(File(state.profileImagePath!))
                                  : null,
                              child: state.profileImagePath == null || !File(state.profileImagePath!).existsSync()
                                  ? Icon(
                                      Icons.person_rounded,
                                      size: 52,
                                      color: activeColor,
                                    )
                                  : null,
                            ),
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: activeColor,
                              child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        state.isLoggedIn ? user.name : 'Guest Account',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.isLoggedIn ? user.email : 'Log in to sync with .NET Cloud Relay',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: state.isLoggedIn
                              ? activeColor.withValues(alpha: 0.12)
                              : Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.role,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: state.isLoggedIn ? activeColor : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. PERMISSIONS & AUTHORIZATION ACCESS
              const Text('Access Permissions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SmartHomeCard(
                child: Column(
                  children: [
                    _accessPermissionTile('Control Smart Hardware', user.controlDevices, Icons.devices_rounded, activeColor),
                    const Divider(height: 1),
                    _accessPermissionTile('View CCTV Live Video Feeds', user.viewCameras, Icons.videocam_rounded, activeColor),
                    const Divider(height: 1),
                    _accessPermissionTile('Arm/Disarm Security System', user.controlSecurity, Icons.shield_rounded, activeColor),
                    const Divider(height: 1),
                    _accessPermissionTile('Manage Family & Guest Access', user.manageOtherUsers, Icons.people_rounded, activeColor),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. SECURITY & PREFERENCES
              const Text('Account Security', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SmartHomeCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: Icon(Icons.fingerprint_rounded, color: activeColor),
                      title: const Text('Biometric Authentication', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Use FaceID / Fingerprint for quick app unlocks & sensitive actions'),
                      value: state.biometricsEnabled,
                      activeThumbColor: isDark ? Colors.white : Colors.black,
                      onChanged: (val) async {
                        final messenger = ScaffoldMessenger.of(context);
                        final bool authenticated = await BiometricService().authenticate(
                          context: context,
                          reason: val
                              ? 'Scan fingerprint to enable Biometric Authentication'
                              : 'Scan fingerprint to disable Biometric Authentication',
                          title: val ? 'Enable Biometrics' : 'Disable Biometrics',
                          forcePrompt: true,
                        );

                        if (authenticated) {
                          state.setBiometricsEnabled(val);
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  val
                                      ? 'Biometric Authentication enabled successfully.'
                                      : 'Biometric Authentication disabled.',
                                ),
                              ),
                            );
                          }
                        } else {
                          if (mounted) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Authentication failed. Settings unchanged.'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: Icon(Icons.security_rounded, color: activeColor),
                      title: const Text('Two-Factor Verification (2FA)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Require OTP code when logging in from new devices'),
                      value: _twoFactorEnabled,
                      activeThumbColor: isDark ? Colors.white : Colors.black,
                      onChanged: (val) => setState(() => _twoFactorEnabled = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // 4. LOGOUT / LOGIN BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: state.isLoggedIn
                    ? ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showLogoutDialog(context, state),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('LOG OUT ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activeColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (c) => const LoginScreen()));
                        },
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('LOG IN ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _accessPermissionTile(String title, bool granted, IconData icon, Color activeColor) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: granted ? activeColor.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.12),
        child: Icon(icon, size: 16, color: granted ? activeColor : Colors.grey),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      trailing: Icon(
        granted ? Icons.check_circle_rounded : Icons.cancel_rounded,
        color: granted ? Colors.green : Colors.grey,
        size: 20,
      ),
    );
  }
}
