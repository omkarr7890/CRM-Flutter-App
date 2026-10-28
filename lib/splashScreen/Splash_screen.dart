
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Login Page/login.dart';
import '../Profile/profile_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _glowController;
  late final AnimationController _contentController;

  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _loadingAnimation;

  Timer? _timer;
  bool _isNavigating = false;

  static const Color _blue = Color(0xFF0755D9);
  static const Color _brightBlue = Color(0xFF4D9CFF);
  static const Color _navy = Color(0xFF061326);

  @override
  void initState() {
    super.initState();

    // Continuous 3D logo rotation.
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    // Pulsing blue lighting.
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // Logo, title, and loading animation.
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _titleFade = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.35, 0.8, curve: Curves.easeIn),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.3, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _loadingAnimation = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
    );

    _contentController.forward();

    // Keep the splash visible for 3 seconds.
    _timer = Timer(
      const Duration(seconds: 3),
      checkLoginStatus,
    );
  }

  Future<void> checkLoginStatus() async {
    if (_isNavigating) return;

    _isNavigating = true;

    try {
      final SharedPreferences prefs =
      await SharedPreferences.getInstance();

      // STEP 1: Read saved login details
      final bool isLoggedIn =
          prefs.getBool('isLoggedIn') ?? false;

      final String empName =
          prefs.getString('empName') ?? '';

      final String username =
          prefs.getString('username') ?? '';

      final String password =
          prefs.getString('password') ?? '';

      final String empId =
      (prefs.get('emp_id') ?? '').toString();

      // STEP 2: Validate complete login session
      final bool hasCompleteSession =
          isLoggedIn &&
              empName.trim().isNotEmpty &&
              username.trim().isNotEmpty &&
              password.isNotEmpty &&
              empId.trim().isNotEmpty;

      // STEP 3: Debug saved session details
      debugPrint('========== SPLASH LOGIN CHECK ==========');
      debugPrint('Logged In: $isLoggedIn');
      debugPrint('Employee Name: ${empName.isNotEmpty}');
      debugPrint('Username: ${username.isNotEmpty}');
      debugPrint('Password: ${password.isNotEmpty}');
      debugPrint('Employee ID: ${empId.isNotEmpty}');
      debugPrint('Complete Session: $hasCompleteSession');
      debugPrint('========================================');

      if (!mounted) return;

      // STEP 4: Navigate based on session
      if (hasCompleteSession) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ProfilePage(
              empName: empName,
            ),
          ),
        );
      } else {
        // Incomplete session - require fresh login
        await prefs.setBool('isLoggedIn', false);

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const LoginPage(),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'Splash login validation error: ${e.runtimeType}',
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rotationController.dispose();
    _glowController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: Stack(
        children: [
          // Dark navy background with blue ambient lighting.
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.15),
                  radius: 1.15,
                  colors: [
                    Color(0xFF102E59),
                    Color(0xFF091B35),
                    _navy,
                  ],
                  stops: [0.0, 0.48, 1.0],
                ),
              ),
            ),
          ),

          // Subtle decorative blue light near the logo.
          Center(
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                final glow = 0.55 + (_glowController.value * 0.45);

                return Container(
                  width: 190 + (_glowController.value * 35),
                  height: 190 + (_glowController.value * 35),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _brightBlue.withOpacity(0.12 * glow),
                        blurRadius: 70,
                        spreadRadius: 15,
                      ),
                      BoxShadow(
                        color: _blue.withOpacity(0.14 * glow),
                        blurRadius: 110,
                        spreadRadius: 25,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Main animated content.
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 3D rotating logo with perspective.
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _rotationController,
                    _glowController,
                  ]),
                  builder: (context, child) {
                    final angle =
                        math.sin(_rotationController.value * 2 * math.pi) *
                            0.65;

                    final glow = 0.5 + _glowController.value * 0.5;

                    final transform = Matrix4.identity()
                      ..setEntry(3, 2, 0.0018)
                      ..rotateY(angle)
                      ..rotateX(
                        math.sin(
                          _rotationController.value * 2 * math.pi,
                        ) *
                            0.10,
                      );

                    return Transform(
                      alignment: Alignment.center,
                      transform: transform,
                      child: Container(
                        width: 142,
                        height: 142,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFB9DDFF),
                              Color(0xFF3287FF),
                              Color(0xFF0755D9),
                              Color(0xFF16366B),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _brightBlue.withOpacity(0.28 * glow),
                              blurRadius: 35,
                              spreadRadius: 3,
                            ),
                            BoxShadow(
                              color: _blue.withOpacity(0.22 * glow),
                              blurRadius: 65,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF10213B),
                            borderRadius: BorderRadius.circular(27),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(19),
                            child: Image.asset(
                              'Assets/icon.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.business_rounded,
                                  size: 76,
                                  color: Colors.white,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 36),

                // Animated CRM title.
                FadeTransition(
                  opacity: _titleFade,
                  child: SlideTransition(
                    position: _titleSlide,
                    child: Column(
                      children: [
                        const Text(
                          'C R M',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 35,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 48,
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF75BCFF),
                                Color(0xFF0755D9),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: _brightBlue.withOpacity(0.55),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 17),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 55),

                // Animated blue loading bar.
                SizedBox(
                  width: 155,
                  height: 3,
                  child: AnimatedBuilder(
                    animation: _loadingAnimation,
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _loadingAnimation.value,
                          backgroundColor: Colors.white.withOpacity(0.12),
                          valueColor:
                          const AlwaysStoppedAnimation<Color>(
                            _brightBlue,
                          ),
                          minHeight: 3,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Footer branding.
          Positioned(
            left: 0,
            right: 0,
            bottom: 36,
            child: Text(
              'SMARTER CONNECTIONS  •  BETTER BUSINESS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.42),
                fontSize: 9,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
