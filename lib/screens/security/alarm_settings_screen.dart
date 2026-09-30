import 'package:flutter/material.dart';
import '../../services/app_state.dart';
import '../../widgets/smart_home_card.dart';

class AlarmSettingsScreen extends StatefulWidget {
  const AlarmSettingsScreen({super.key});

  @override
  State<AlarmSettingsScreen> createState() => _AlarmSettingsScreenState();
}

class _AlarmSettingsScreenState extends State<AlarmSettingsScreen> {
  String _visualStyle = 'Symbols'; // 'Symbols' or 'Pictures'

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, child) {
        final state = AppState();
        final activeColor = state.activeThemeColor;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Hardware Alarm Config', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Section 3: Visual Style Selection
              const Text('Visual Preference', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SmartHomeCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('How should devices identify themselves in alerts?', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        _styleBtn('Symbols', Icons.category_rounded, activeColor),
                        const SizedBox(width: 12),
                        _styleBtn('Pictures', Icons.image_rounded, activeColor),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Section 3: Device Specific Alarms
              const Text('Hardware Response Matrix', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              _alarmCategory(
                'Smart Speakers',
                'Audio siren and voice announcement.',
                Icons.speaker_group_rounded,
                Colors.blue,
                Switch(value: true, activeColor: activeColor, onChanged: (v) {}),
              ),
              const SizedBox(height: 12),

              _alarmCategory(
                'RGB Lighting',
                'Visual strobe and red alert pulsing.',
                Icons.color_lens_rounded,
                Colors.purple,
                Switch(value: true, activeColor: activeColor, onChanged: (v) {}),
              ),
              const SizedBox(height: 12),

              _alarmCategory(
                'Smoke Detectors',
                'Local hardware chime and whole-home alert.',
                Icons.smoke_free_rounded,
                Colors.orange,
                Switch(value: true, activeColor: activeColor, onChanged: (v) {}),
              ),
              
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  state.saveAlarmSettings();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('SAVE HARDWARE CONFIG'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _styleBtn(String label, IconData icon, Color activeColor) {
    bool isSelected = _visualStyle == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _visualStyle = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? activeColor : Colors.grey.withValues(alpha: 0.2), width: 2),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? activeColor : Colors.grey),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: isSelected ? activeColor : Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _alarmCategory(String title, String desc, IconData icon, Color color, Widget trailing) {
    return SmartHomeCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 11)),
        trailing: trailing,
      ),
    );
  }
}
