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
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: CustomPaint(painter: _MillIntroPainter(_animation)),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final reveal = Curves.easeOutCubic.transform(
                    ((_animation.value - .23) / .25).clamp(0.0, 1.0),
                  );
                  return Opacity(
                    opacity: reveal,
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - reveal)),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 160),
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'МЕЛЬНИЦА',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                            color: Color(0xFF242C2D),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 46,
                        height: 2,
                        color: const Color(0xFFB7853F),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'КАЖДЫЙ РЕЙС — В ДЕЛЕ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          color: Color(0xFF737671),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MillIntroPainter extends CustomPainter {
  final Animation<double> animation;
  _MillIntroPainter(this.animation) : super(repaint: animation);
  static const ink = Color(0xFF242C2D), amber = Color(0xFFB7853F);

  double reveal(double start, double length) => Curves.easeOutCubic.transform(
    ((animation.value - start) / length).clamp(0.0, 1.0),
  );

  void wheat(
    Canvas c,
    Offset origin,
    double angle,
    double scale,
    double opacity,
  ) {
    c.save();
    c.translate(origin.dx, origin.dy);
    c.rotate(angle);
    c.scale(scale);
    final stem = Paint()
      ..color = ink.withValues(alpha: opacity)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    c.drawPath(
      Path()
        ..moveTo(0, 38)
        ..quadraticBezierTo(-4, -20, 0, -108),
      stem,
    );
    final grain = Paint()..color = amber.withValues(alpha: opacity);
    for (var i = 0; i < 6; i++) {
      for (final side in [-1.0, 1.0]) {
        c.save();
        c.translate(side * 8, -20 - i * 14);
        c.rotate(side * .6);
        c.drawOval(const Rect.fromLTWH(-5, -13, 10, 25), grain);
        c.restore();
      }
    }
    c.drawOval(const Rect.fromLTWH(-4, -120, 8, 21), grain);
    c.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final scale = math.min(size.width / 390, size.height / 780);
    final edge = reveal(0, .3);
    wheat(
      canvas,
      Offset(size.width + 18 * (1 - edge), size.height * .14),
      -.85,
      scale * 1.35,
      edge,
    );
    wheat(
      canvas,
      Offset(size.width * .9, size.height * .17),
      -1.25,
      scale,
      edge,
    );
    wheat(
      canvas,
      Offset(-18 * (1 - edge), size.height * .87),
      .8,
      scale * 1.2,
      edge,
    );
    wheat(
      canvas,
      Offset(size.width * .08, size.height * .89),
      .4,
      scale * .85,
      edge,
    );

    // Fine factory skyline enters from the bottom, like the reference's fence.
    canvas.save();
    canvas.translate(0, size.height * .94 + (1 - edge) * 30);
    final line = Paint()
      ..color = ink.withValues(alpha: edge * .65)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final skyline = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0);
    for (var i = 0; i < 5; i++) {
      final x = size.width * (.32 + i * .12);
      skyline.moveTo(x, 0);
      skyline.lineTo(x, -30 * scale);
      skyline.quadraticBezierTo(
        x + 13 * scale,
        -48 * scale,
        x + 26 * scale,
        -30 * scale,
      );
      skyline.lineTo(x + 26 * scale, 0);
    }
    canvas.drawPath(skyline, line);
    canvas.restore();

    final logo = reveal(.12, .32);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2 - 62);
    canvas.scale(scale * (.88 + logo * .12));
    final fill = Paint()..color = ink.withValues(alpha: logo);
    final gold = Paint()..color = amber.withValues(alpha: logo);
    canvas.drawCircle(
      Offset.zero,
      66,
      Paint()..color = amber.withValues(alpha: logo * .12),
    );
    canvas.drawArc(
      const Rect.fromLTWH(-70, -70, 140, 140),
      -.8,
      5.2 * logo,
      false,
      Paint()
        ..color = amber.withValues(alpha: logo)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-24, 46)
        ..lineTo(-15, -19)
        ..lineTo(15, -19)
        ..lineTo(24, 46)
        ..close(),
      fill,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-24, -18)
        ..lineTo(0, -39)
        ..lineTo(24, -18)
        ..close(),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-5, 22, 10, 24),
        const Radius.circular(5),
      ),
      gold,
    );
    canvas.translate(0, -16);
    canvas.rotate(-.5 + t * .7);
    for (var i = 0; i < 4; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 2);
      canvas.drawPath(
        Path()
          ..moveTo(5, -4)
          ..lineTo(48, -12)
          ..lineTo(48, 3)
          ..lineTo(5, 4)
          ..close(),
        gold,
      );
      canvas.restore();
    }
    canvas.drawCircle(Offset.zero, 6, fill);
    canvas.restore();

    final falling = reveal(.32, .15);
    for (var i = 0; i < 7; i++) {
      final progress = ((t - .25) * .7 + i / 7) % 1;
      final x =
          size.width * (.12 + (i * .137) % .76) + math.sin(t * 6 + i) * 16;
      final y = progress * size.height;
      // Leave the central wordmark clear.
      if ((y - size.height / 2).abs() < 125 && (x - size.width / 2).abs() < 145)
        continue;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 3 + i);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: 4 * scale,
          height: 10 * scale,
        ),
        Paint()..color = amber.withValues(alpha: falling * .7),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _MillIntroPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
