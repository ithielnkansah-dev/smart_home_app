class HomeUser {
  final String id;
  final String name;
  final String email;
  final String role;

  final bool controlDevices;
  final bool viewCameras;
  final bool controlSecurity;
  final bool manageOtherUsers;

  HomeUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.controlDevices = true,
    this.viewCameras = true,
    this.controlSecurity = false,
    this.manageOtherUsers = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'controlDevices': controlDevices,
    'viewCameras': viewCameras,
    'controlSecurity': controlSecurity,
    'manageOtherUsers': manageOtherUsers,
  };

  factory HomeUser.fromJson(Map<String, dynamic> json) => HomeUser(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    role: json['role'] ?? '',
    controlDevices: json['controlDevices'] ?? true,
    viewCameras: json['viewCameras'] ?? true,
    controlSecurity: json['controlSecurity'] ?? false,
    manageOtherUsers: json['manageOtherUsers'] ?? false,
  );
}
