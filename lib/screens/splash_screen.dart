import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/session_service.dart';
import 'app_shell.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  late final Future<AppSession?> _session;
  bool _started = false, _navigated = false;

  @override
  void initState() {
    super.initState();
    _session = SessionService.read().catchError((Object _) => null);
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );
    _animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _goNext());
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _prepareArtwork();
  }

  Future<void> _prepareArtwork() async {
    await precacheImage(
      const AssetImage('assets/images/scenes/mill_intro_wheat.png'),
      context,
      onError: (error, stack) {},
    );
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.value = 1;
    } else {
      _animation.forward();
    }
  }

  Future<void> _goNext() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    AppSession? session;
    try {
      session = await _session;
    } catch (_) {
      // Keep login accessible if local session storage is unavailable.
    }
    if (!mounted) return;
    final next = session == null
        ? const LoginScreen()
        : AppShell(session: session);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 450),
        pageBuilder: (_, animation, secondaryAnimation) => next,
        transitionsBuilder: (_, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    child: Scaffold(
      backgroundColor: const Color(0xFFF5F2EB),
      body: Semantics(
        label: 'Мельница. Открытие приложения',
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _animation,
            child: Image.asset(
              'assets/images/scenes/mill_intro_wheat.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              excludeFromSemantics: true,
              errorBuilder: (_, error, stack) => const Center(
                child: Text(
                  'МЕЛЬНИЦА',
                  style: TextStyle(
                    color: Color(0xFF765125),
                    fontSize: 30,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
            builder: (context, child) {
              final t = _animation.value;
              final fade = Curves.easeOut.transform((t / .28).clamp(0.0, 1.0));
              return Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: fade,
                    child: Transform.scale(
                      scale: 1.025 - .025 * Curves.easeOutCubic.transform(t),
                      child: child,
                    ),
                  ),
                  IgnorePointer(
                    child: RepaintBoundary(
                      child: CustomPaint(painter: _WheatGrainsPainter(t)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _WheatGrainsPainter extends CustomPainter {
  final double progress;
  const _WheatGrainsPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = math.sin(progress * math.pi) * .7;
    if (opacity <= 0) return;
    for (var i = 0; i < 8; i++) {
      // Keep the brand name and the central ear unobstructed.
      final left = i.isEven;
      final x =
          size.width * (left ? .12 : .86) + math.sin(progress * 4 + i) * 12;
      final y = size.height * ((i / 8 + progress * .24) % 1);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(i + progress * 1.8);
      final rect = Rect.fromCenter(center: Offset.zero, width: 4, height: 10);
      canvas.drawOval(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: [
              const Color(0xFF815520).withValues(alpha: opacity),
              const Color(0xFFE3BB6D).withValues(alpha: opacity),
              const Color(0xFFAC7734).withValues(alpha: opacity),
            ],
          ).createShader(rect),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _WheatGrainsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
