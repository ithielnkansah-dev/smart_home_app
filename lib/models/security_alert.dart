import 'package:flutter/material.dart';

enum AlertSeverity { warning, critical }

class SecurityAlert {
  final String id;
  final String title;
  final String location;
  final DateTime timestamp;
  final AlertSeverity severity;
  final IconData icon;

  SecurityAlert({
    required this.id,
    required this.title,
    required this.location,
    required this.timestamp,
    this.severity = AlertSeverity.critical,
    required this.icon,
  });
}
