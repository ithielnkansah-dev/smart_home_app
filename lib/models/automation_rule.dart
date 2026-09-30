class AutomationRule {
  final String id;
  String name;
  bool isEnabled;
  String triggerType; // 'motion', 'temperature', 'time', 'sunset', 'water_leak', 'gas_leak', 'co2_high'
  String triggerCondition; // 'equals', 'greater_than', 'less_than', 'detected'
  dynamic triggerValue; // e.g. 28.0, 'Living Room', '6:00 AM'
  String actionDeviceId; // Device ID or 'ALL_LIGHTS', 'WATER_VALVE', 'GAS_VALVE', 'SCENARIO'
  String actionCommand; // 'turnOn', 'turnOff', 'setTemp', 'setPosition', 'triggerScene'
  dynamic actionValue; // e.g. 23.0, 0.70, 'S001'
  DateTime? lastTriggered;

  AutomationRule({
    required this.id,
    required this.name,
    this.isEnabled = true,
    required this.triggerType,
    required this.triggerCondition,
    required this.triggerValue,
    required this.actionDeviceId,
    required this.actionCommand,
    this.actionValue,
    this.lastTriggered,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isEnabled': isEnabled,
        'triggerType': triggerType,
        'triggerCondition': triggerCondition,
        'triggerValue': triggerValue,
        'actionDeviceId': actionDeviceId,
        'actionCommand': actionCommand,
        'actionValue': actionValue,
        'lastTriggered': lastTriggered?.toIso8601String(),
      };

  factory AutomationRule.fromJson(Map<String, dynamic> json) => AutomationRule(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        isEnabled: json['isEnabled'] ?? true,
        triggerType: json['triggerType'] ?? 'motion',
        triggerCondition: json['triggerCondition'] ?? 'detected',
        triggerValue: json['triggerValue'],
        actionDeviceId: json['actionDeviceId'] ?? '',
        actionCommand: json['actionCommand'] ?? 'turnOn',
        actionValue: json['actionValue'],
        lastTriggered: json['lastTriggered'] != null
            ? DateTime.tryParse(json['lastTriggered'])
            : null,
      );
}
