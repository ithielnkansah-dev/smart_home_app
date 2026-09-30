import 'dart:async';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/app_state.dart';
import '../../services/biometric_service.dart';
import '../auth/login_screen.dart';

class LauncherSplashScreen extends StatefulWidget {
  const LauncherSplashScreen({super.key});

  @override
  State<LauncherSplashScreen> createState() => _LauncherSplashScreenState();
}

class _LauncherSplashScreenState extends State<LauncherSplashScreen> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _pulseController;

  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _pulseAnimation;

  String _statusMessage = 'Initializing System Engine...';
  double _progress = 0.1;
  bool _isAppLocked = false;

  @override
  void initState() {
    super.initState();

    // 1. Entrance Staggered Controller
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack)),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.4, 0.9, curve: Curves.easeIn)),
    );

    _textSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic)),
    );

    // 2. Pulse Controller for Ambient Glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _entranceController.forward();
    _runInitializationSequence();
  }

  void _runInitializationSequence() async {
    final state = AppState();

    // Step 1: Database
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _statusMessage = 'Initializing Local Database...';
        _progress = 0.3;
      });
    }

    // Step 2: .NET 9 Relay Link
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _statusMessage = 'Connecting to .NET 9 Cloud Relay...';
        _progress = 0.6;
      });
    }
    await state.syncWithCloud();

    // Step 3: Weather & Location
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _statusMessage = 'Detecting GPS Location & Weather...';
        _progress = 0.85;
      });
    }
    state.fetchLiveWeather();

    // Step 4: Hardware Nodes
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _statusMessage = 'Synced ${state.devices.length} Hardware Nodes [ONLINE]';
        _progress = 1.0;
      });
    }

    // Step 5: Check Authentication State
    if (!state.isLoggedIn) {
      _proceedToMainScreen();
      return;
    }

    // Step 6: Biometric App Launch / Startup Unlock (for logged-in users)
    if (state.biometricsEnabled) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Security Locked • Scan Fingerprint to Unlock';
          _isAppLocked = true;
        });
      }

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      bool authenticated = await BiometricService().authenticate(
        context: context,
        reason: 'Scan fingerprint to open Smart Home app',
        title: 'App Launch Security Unlock',
      );

      if (!authenticated) {
        if (mounted) {
          setState(() {
            _statusMessage = 'App Security Locked • Tap below to unlock';
            _isAppLocked = true;
          });
        }
        return;
      }
    }

    _proceedToMainScreen();
  }

  Future<void> _proceedToMainScreen() async {
    if (!mounted) return;
    final state = AppState();

    if (!state.isLoggedIn) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  Future<void> _unlockAppWithBiometrics() async {
    bool authenticated = await BiometricService().authenticate(
      context: context,
      reason: 'Scan fingerprint to open Smart Home app',
      title: 'App Launch Security Unlock',
      forcePrompt: true,
    );

    if (authenticated) {
      _proceedToMainScreen();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = state.activeThemeColor;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // LOGO WITH AMBIENT GLOW & STAGGERED ENTRANCE
              FadeTransition(
                opacity: _logoFadeAnimation,
                child: ScaleTransition(
                  scale: _logoScaleAnimation,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ambient Glow Aura
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.08),
                          ),
                        ),
                      ),

                      // Glassmorphism Logo Card Container
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.black12,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          width: 200,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.business_rounded, size: 70, color: primaryColor),
                                const SizedBox(height: 8),
                                Text(
                                  'ibs',
                                  style: TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                Text(
                                  'INTELLIGENT BUILDING SOLUTIONS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // SLIDING SUBTITLE TEXT
              FadeTransition(
                opacity: _textFadeAnimation,
                child: SlideTransition(
                  position: _textSlideAnimation,
                  child: Column(
                    children: [
                      Text(
                        'INTELLIGENT BUILDING SOLUTIONS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Universal Smart Control Platform',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // REAL-TIME SYSTEM INITIALIZATION PROGRESS & STATUS
              FadeTransition(
                opacity: _textFadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 180,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 4,
                            color: _isAppLocked ? Colors.orange : primaryColor,
                            backgroundColor: isDark ? Colors.white24 : Colors.black12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _isAppLocked ? Colors.orange : primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Powered by .NET 9 Cloud Relay',
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      if (_isAppLocked) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onPressed: _unlockAppWithBiometrics,
                          icon: const Icon(Icons.fingerprint_rounded, size: 20),
                          label: const Text('SCAN FINGERPRINT TO UNLOCK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
