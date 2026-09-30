class Zone {
  final String id;
  final String roomId;
  final String name;

  Zone({
    required this.id,
    required this.roomId,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'roomId': roomId,
    'name': name,
  };

  factory Zone.fromJson(Map<String, dynamic> json) => Zone(
    id: json['id'] ?? '',
    roomId: json['roomId'] ?? '',
    name: json['name'] ?? '',
  );
}
