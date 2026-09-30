class House {
  final String id;
  final String name;
  final String address;

  House({
    required this.id,
    required this.name,
    required this.address,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
  };

  factory House.fromJson(Map<String, dynamic> json) => House(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    address: json['address'] ?? '',
  );
}
