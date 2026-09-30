class Floor {
  final String id;
  final String houseId;
  final String name;

  Floor({
    required this.id,
    required this.houseId,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'houseId': houseId,
    'name': name,
  };

  factory Floor.fromJson(Map<String, dynamic> json) => Floor(
    id: json['id'] ?? '',
    houseId: json['houseId'] ?? '',
    name: json['name'] ?? '',
  );
}
