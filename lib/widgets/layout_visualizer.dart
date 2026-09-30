import 'package:flutter/material.dart';
import '../models/room.dart';

class LayoutVisualizer extends StatelessWidget {
  final List<Room> rooms;

  const LayoutVisualizer({super.key, required this.rooms});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.black26 
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          painter: CADPainter(
            rooms: rooms,
            lineColor: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class CADPainter extends CustomPainter {
  final List<Room> rooms;
  final Color lineColor;

  CADPainter({required this.rooms, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final wallPaint = Paint()
      ..color = lineColor.withOpacity(0.3)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = lineColor.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Simple grid-based placement for rooms in CAD view
    if (rooms.isEmpty) return;

    double margin = 20.0;
    double usableWidth = size.width - (margin * 2);
    double usableHeight = size.height - (margin * 2);

    int cols = (rooms.length > 2) ? 2 : rooms.length;
    int rows = (rooms.length / cols).ceil();

    double roomWidth = usableWidth / cols;
    double roomHeight = usableHeight / rows;

    for (int i = 0; i < rooms.length; i++) {
      int row = i ~/ cols;
      int col = i % cols;

      Rect roomRect = Rect.fromLTWH(
        margin + (col * roomWidth),
        margin + (row * roomHeight),
        roomWidth - 10,
        roomHeight - 10,
      );

      // Draw Room Walls
      canvas.drawRect(roomRect, wallPaint);
      canvas.drawRect(roomRect, fillPaint);

      // Draw Room Label
      textPainter.text = TextSpan(
        text: rooms[i].name,
        style: TextStyle(
          color: lineColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          roomRect.center.dx - (textPainter.width / 2),
          roomRect.center.dy - (textPainter.height / 2),
        ),
      );
      
      // Draw simulated door
      canvas.drawLine(
        Offset(roomRect.left + 10, roomRect.bottom),
        Offset(roomRect.left + 30, roomRect.bottom),
        Paint()..color = Colors.white24..strokeWidth = 4,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
