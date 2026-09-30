import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/app_state.dart';

class HighlightsScreen extends StatefulWidget {
  const HighlightsScreen({super.key});

  @override
  State<HighlightsScreen> createState() => _HighlightsScreenState();
}

class _HighlightsScreenState extends State<HighlightsScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _highlights = [
    {
      'title': 'Universal Control',
      'desc': 'Manage speakers, lights, AC, cameras, and more from one unified interface.',
      'icon': Icons.devices_other_rounded,
      'color': Colors.blue,
    },
    {
      'title': 'Smart Scenarios',
      'desc': 'Create custom modes like "Cinema" or "Shades Down" to automate your home state.',
      'icon': Icons.auto_awesome_rounded,
      'color': Colors.purple,
    },
    {
      'title': 'Hardware Security',
      'desc': 'Real-time alerts for smoke, leaks, and unauthorized entry with 1080p video telemetry.',
      'icon': Icons.shield_rounded,
      'color': Colors.green,
    },
    {
      'title': 'System Permissions',
      'desc': 'We need access to Bluetooth and Notifications to securely manage your hardware.',
      'isPermissionPage': true,
      'icon': Icons.security_rounded,
      'color': Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemCount: _highlights.length,
            itemBuilder: (context, index) {
              final h = _highlights[index];
              return Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(h['icon'] as IconData, size: 100, color: h['color'] as Color),
                    const SizedBox(height: 40),
                    Text(h['title'] as String, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    Text(h['desc'] as String, style: const TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
                    if (h['isPermissionPage'] == true) ...[
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _requestInitialPermissions,
                        child: const Text('Grant Essential Access'),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 60,
            left: 0, right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_highlights.length, (idx) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8, height: 8,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: _currentPage == idx ? AppState().activeThemeColor : Colors.grey.withValues(alpha: 0.3)),
                  )),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppState().activeThemeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(_currentPage == _highlights.length - 1 ? 'GET STARTED' : 'CONTINUE'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _highlights.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      AppState().completeFirstLaunch();
    }
  }

  Future<void> _requestInitialPermissions() async {
    await [Permission.notification, Permission.bluetooth].request();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissions processed.')));
  }
}
