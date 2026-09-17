import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.78, curve: Curves.easeOut),
    );

    _scale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Timer(const Duration(milliseconds: 1850), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 550),
          pageBuilder: (_, animation, __) => const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SplashBackground(),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _TruckMark(size: 112),
                    const SizedBox(height: 26),
                    Text(
                      'ГАЗЕЛЬ',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontSize: 38,
                            letterSpacing: 5.2,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'рабочая система',
                      style: TextStyle(
                        color: AppColors.textSoft,
                        fontSize: 13,
                        letterSpacing: 2.1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 42,
            child: Center(
              child: Text(
                'DRIVER SYSTEM',
                style: TextStyle(
                  color: Color(0xFF5E626B),
                  fontSize: 10,
                  letterSpacing: 3.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.12),
          radius: 0.88,
          colors: [
            Color(0xFF24130A),
            AppColors.background,
            Color(0xFF06070A),
          ],
          stops: [0, 0.56, 1],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _TruckMark extends StatelessWidget {
  final double size;

  const _TruckMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        color: const Color(0xFF101216),
        border: Border.all(color: const Color(0xFF63300D)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44FF7A1A),
            blurRadius: 34,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Icon(
        Icons.local_shipping_rounded,
        color: AppColors.orange,
        size: size * 0.55,
      ),
    );
  }
}
