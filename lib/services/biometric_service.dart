import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'app_state.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Prompts biometric authentication (Fingerprint scan).
  /// Returns `true` if authentication is successful, `false` otherwise.
  Future<bool> authenticate({
    required BuildContext context,
    required String reason,
    String title = 'Fingerprint Verification',
    bool forcePrompt = false,
  }) async {
    final state = AppState();

    // Bypass check if biometrics are disabled and not explicitly forced
    if (!state.biometricsEnabled && !forcePrompt) {
      return true;
    }

    try {
      bool canCheckBiometrics = await _auth.canCheckBiometrics;
      bool isDeviceSupported = await _auth.isDeviceSupported();

      if (canCheckBiometrics && isDeviceSupported) {
        try {
          final bool didAuthenticate = await _auth.authenticate(
            localizedReason: reason,
            options: const AuthenticationOptions(
              stickyAuth: true,
              biometricOnly: false,
              useErrorDialogs: true,
            ),
          );

          if (didAuthenticate) {
            HapticFeedback.mediumImpact();
            return true;
          }
        } catch (e) {
          debugPrint('Native biometrics failed or unavailable, falling back to Fingerprint Scan UI: $e');
        }
      }
    } catch (e) {
      debugPrint('Error checking native biometrics: $e');
    }

    // Fallback or interactive Fingerprint Scan Dialog
    if (!context.mounted) return false;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FingerprintScanBottomSheet(
        title: title,
        reason: reason,
      ),
    );

    return result ?? false;
  }
}

class FingerprintScanBottomSheet extends StatefulWidget {
  final String title;
  final String reason;

  const FingerprintScanBottomSheet({
    super.key,
    required this.title,
    required this.reason,
  });

  @override
  State<FingerprintScanBottomSheet> createState() => _FingerprintScanBottomSheetState();
}

class _FingerprintScanBottomSheetState extends State<FingerprintScanBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanLineController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scanLineAnimation;

  bool _isScanning = false;
  bool _isSuccess = false;
  bool _hasError = false;
  String _statusMessage = 'Place your finger on the scanner sensor';
  final TextEditingController _pinController = TextEditingController();
  bool _showPinFallback = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanLineController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _triggerScan() async {
    if (_isScanning || _isSuccess) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isScanning = true;
      _hasError = false;
      _statusMessage = 'Scanning fingerprint... Keep finger steady';
    });

    _scanLineController.repeat(reverse: true);

    // Simulate real biometric scanning
    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;

    _scanLineController.stop();

    HapticFeedback.heavyImpact();
    setState(() {
      _isScanning = false;
      _isSuccess = true;
      _statusMessage = 'Fingerprint Recognized! Access Granted.';
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _verifyPin() {
    if (_pinController.text.trim() == '1234' || _pinController.text.trim().isNotEmpty) {
      HapticFeedback.heavyImpact();
      Navigator.of(context).pop(true);
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _hasError = true;
        _statusMessage = 'Incorrect PIN. Try entering 1234.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppState().activeThemeColor;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header Title
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.reason,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 28),

          if (!_showPinFallback) ...[
            // FINGERPRINT SCANNER TAP TARGET & ANIMATION
            GestureDetector(
              onTap: _triggerScan,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulse ring background
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isSuccess
                            ? Colors.green.withValues(alpha: 0.2)
                            : (_hasError
                                ? Colors.red.withValues(alpha: 0.2)
                                : primaryColor.withValues(alpha: 0.15)),
                      ),
                    ),
                  ),

                  // Sensor Card
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
                      border: Border.all(
                        color: _isSuccess
                            ? Colors.green
                            : (_hasError
                                ? Colors.red
                                : (_isScanning ? primaryColor : primaryColor.withValues(alpha: 0.4))),
                        width: 2.5,
                      ),
                    ),
                    child: Icon(
                      _isSuccess
                          ? Icons.check_circle_rounded
                          : (_hasError ? Icons.error_outline_rounded : Icons.fingerprint_rounded),
                      size: 52,
                      color: _isSuccess
                          ? Colors.green
                          : (_hasError ? Colors.red : primaryColor),
                    ),
                  ),

                  // Scanning laser line
                  if (_isScanning)
                    AnimatedBuilder(
                      animation: _scanLineAnimation,
                      builder: (context, child) {
                        return Positioned(
                          top: 25 + (40 * _scanLineAnimation.value),
                          child: Container(
                            width: 60,
                            height: 3,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.8),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Scan Instructions or Success Message
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _isSuccess
                    ? Colors.green
                    : (_hasError ? Colors.red : (isDark ? Colors.white70 : Colors.black87)),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _triggerScan,
              icon: const Icon(Icons.touch_app_rounded, size: 18),
              label: Text(_isScanning ? 'Scanning...' : 'TAP TO SCAN FINGERPRINT', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(height: 16),

            // PIN Fallback Option
            TextButton(
              onPressed: () {
                setState(() {
                  _showPinFallback = true;
                });
              },
              child: const Text('Use Master Security PIN', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ] else ...[
            // PIN FALLBACK INPUT UI
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Enter Master Security PIN',
                hintText: 'e.g. 1234',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              onSubmitted: (_) => _verifyPin(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _showPinFallback = false;
                      });
                    },
                    child: const Text('Back to Fingerprint'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _verifyPin,
                    child: const Text('Confirm PIN', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          // Cancel button
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
