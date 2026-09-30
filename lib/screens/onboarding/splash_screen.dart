import 'package:flutter/material.dart';

class IbsSplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const IbsSplashScreen({super.key, required this.onComplete});

  @override
  State<IbsSplashScreen> createState() => _IbsSplashScreenState();
}

class _IbsSplashScreenState extends State<IbsSplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bulbScale;
  late Animation<double> _bulbGlow;
  late Animation<double> _brainOpacity;
  late Animation<Offset> _iSlide;
  late Animation<Offset> _sSlide;
  late Animation<double> _lettersOpacity;
  late Animation<double> _lineWidth;
  late Animation<double> _subtextOpacity;

  final Color ibsGreen = const Color(0xFF009640);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));

    _brainOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3, curve: Curves.easeIn)));
    _bulbScale = CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.5, curve: Curves.elasticOut));
    _bulbGlow = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.6, curve: Curves.easeInOut)));
    _iSlide = Tween<Offset>(begin: const Offset(-1.5, 0), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.5, 0.8, curve: Curves.easeOutBack)));
    _sSlide = Tween<Offset>(begin: const Offset(1.5, 0), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.5, 0.8, curve: Curves.easeOutBack)));
    _lettersOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.5, 0.6)));
    _lineWidth = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.8, 0.95, curve: Curves.easeInOut)));
    _subtextOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.85, 1.0)));

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        widget.onComplete();
      });
    });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                SlideTransition(position: _iSlide, child: FadeTransition(opacity: _lettersOpacity, child: Text('i', style: TextStyle(fontSize: 140, fontWeight: FontWeight.w900, color: ibsGreen, fontFamily: 'Georgia', height: 1)))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text('b', style: TextStyle(fontSize: 140, fontWeight: FontWeight.w900, color: ibsGreen, fontFamily: 'Georgia', height: 1)),
                      Positioned(
                        left: 20, top: 40,
                        child: FadeTransition(
                          opacity: _brainOpacity,
                          child: CustomPaint(
                            size: const Size(60, 80),
                            painter: BrainBulbPainter(color: Colors.white, bulbGlow: _bulbGlow, bulbScale: _bulbScale),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SlideTransition(position: _sSlide, child: FadeTransition(opacity: _lettersOpacity, child: Text('s', style: TextStyle(fontSize: 140, fontWeight: FontWeight.w900, color: ibsGreen, fontFamily: 'Georgia', height: 1)))),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedBuilder(animation: _lineWidth, builder: (context, child) => Container(height: 3, width: 360 * _lineWidth.value, color: ibsGreen)),
            const SizedBox(height: 12),
            FadeTransition(opacity: _subtextOpacity, child: Text('INTELLIGENT BUILDING SOLUTIONS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ibsGreen, letterSpacing: 1.5))),
          ],
        ),
      ),
    );
  }
}

class BrainBulbPainter extends CustomPainter {
  final Color color; final Animation<double> bulbGlow; final Animation<double> bulbScale;
  BrainBulbPainter({required this.color, required this.bulbGlow, required this.bulbScale}) : super(repaint: Listenable.merge([bulbGlow, bulbScale]));
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.0;
    final path = Path();
    path.moveTo(size.width * 0.8, size.height * 0.1); path.quadraticBezierTo(size.width * 0.9, 0, size.width * 0.5, 0); path.quadraticBezierTo(size.width * 0.1, 0, size.width * 0.1, size.height * 0.3); path.lineTo(0, size.height * 0.4); path.lineTo(size.width * 0.1, size.height * 0.45); path.lineTo(size.width * 0.1, size.height * 0.6); path.quadraticBezierTo(size.width * 0.2, size.height * 0.8, size.width * 0.6, size.height * 0.8);
    canvas.drawPath(path, paint);
    final bulbPaint = Paint()..color = Colors.white.withValues(alpha: 0.7 + (bulbGlow.value * 0.3))..style = PaintingStyle.fill;
    if (bulbGlow.value > 0) { canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.35), 25 * bulbGlow.value, Paint()..color = Colors.yellow.withValues(alpha: 0.4 * bulbGlow.value)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)); }
    canvas.save(); canvas.translate(size.width * 0.5, size.height * 0.35); canvas.scale(bulbScale.value); canvas.drawCircle(Offset.zero, 15, bulbPaint); canvas.drawRect(Rect.fromLTWH(-8, 12, 16, 8), bulbPaint); canvas.restore();
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
