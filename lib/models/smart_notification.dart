enum NotificationCategory { security, device, people, system }

class SmartNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String propertyId;
  final NotificationCategory category;
  bool isRead;

  SmartNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.propertyId,
    required this.category,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
    'propertyId': propertyId,
    'category': category.name,
    'isRead': isRead,
  };

  factory SmartNotification.fromJson(Map<String, dynamic> json) => SmartNotification(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    body: json['body'] ?? '',
    timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    propertyId: json['propertyId'] ?? '',
    category: NotificationCategory.values.firstWhere(
      (c) => c.name == json['category'],
      orElse: () => NotificationCategory.system,
    ),
    isRead: json['isRead'] ?? false,
  );
}
