class Room {
  final String id;
  final String houseId;
  final String floorId;
  final String name;

  Room({
    required this.id,
    required this.houseId,
    required this.floorId,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'houseId': houseId,
    'floorId': floorId,
    'name': name,
  };

  factory Room.fromJson(Map<String, dynamic> json) => Room(
    id: json['id'] ?? '',
    houseId: json['houseId'] ?? '',
    floorId: json['floorId'] ?? '',
    name: json['name'] ?? '',
  );
}
