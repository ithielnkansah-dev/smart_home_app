class Scenario {
  final String id;
  final String name;
  final String iconName;
  final String propertyId;
  final bool isPredefined;
  final Map<String, bool> deviceActions;

  Scenario({
    required this.id,
    required this.name,
    required this.iconName,
    required this.propertyId,
    this.isPredefined = false,
    required this.deviceActions,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'iconName': iconName,
    'propertyId': propertyId,
    'isPredefined': isPredefined,
    'deviceActions': deviceActions,
  };

  factory Scenario.fromJson(Map<String, dynamic> json) => Scenario(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    iconName: json['iconName'] ?? 'morning',
    propertyId: json['propertyId'] ?? '',
    isPredefined: json['isPredefined'] ?? false,
    deviceActions: Map<String, bool>.from(json['deviceActions'] ?? {}),
  );
}
