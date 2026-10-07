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
      duration: const Duration(milliseconds: 4400),
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
    await Future.wait([
      for (final name in ['mill_intro_ear.png', 'mill_intro_corners.png'])
        precacheImage(
          AssetImage('assets/images/scenes/$name'),
          context,
          onError: (error, stack) {},
        ),
    ]);
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth, h = constraints.maxHeight;
            final earHeight = math.min(h * .58, w * 1.25);
            final earWidth = earHeight * .565;
            final earTop = h * .13;
            return ClipRect(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final t = _animation.value;
                  double phase(double start, double duration) => Curves
                      .easeOutCubic
                      .transform(((t - start) / duration).clamp(0.0, 1.0));
                  Widget artwork(String name) => Image.asset(
                    'assets/images/scenes/$name',
                    fit: BoxFit.fill,
                    excludeFromSemantics: true,
                    errorBuilder: (_, error, stack) => const SizedBox.shrink(),
                  );
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Independent corner clusters slide inward first.
                      for (final top in [true, false])
                        Positioned.fill(
                          child: Transform.translate(
                            offset: Offset(
                              (top ? 55 : -55) *
                                  (1 - phase(top ? .02 : .08, .22)),
                              (top ? -20 : 20) *
                                  (1 - phase(top ? .02 : .08, .22)),
                            ),
                            child: Opacity(
                              opacity: phase(top ? .02 : .08, .22),
                              child: ClipRect(
                                clipper: _IntroBandClipper(
                                  top ? 0 : .5,
                                  top ? .5 : 1,
                                ),
                                child: artwork('mill_intro_corners.png'),
                              ),
                            ),
                          ),
                        ),
                      // The ear is genuinely composed from staggered image strips:
                      // lower grains arrive first, upper grains follow from each side.
                      Positioned(
                        top: earTop,
                        left: (w - earWidth) / 2,
                        width: earWidth,
                        height: earHeight,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            for (var i = 0; i < 18; i++)
                              Transform.translate(
                                offset: Offset(
                                  (i.isEven ? -32 : 32) *
                                      (1 - phase(.19 + (17 - i) * .019, .16)),
                                  14 * (1 - phase(.19 + (17 - i) * .019, .16)),
                                ),
                                child: Opacity(
                                  opacity: phase(.19 + (17 - i) * .019, .16),
                                  child: ClipRect(
                                    clipper: _IntroBandClipper(
                                      i / 18,
                                      (i + 1) / 18,
                                    ),
                                    child: artwork('mill_intro_ear.png'),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Name follows the assembled ear; letters appear in sequence.
                      Positioned(
                        top: earTop + earHeight + 18,
                        left: 22,
                        right: 22,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 0; i < 'МЕЛЬНИЦА'.length; i++)
                                Opacity(
                                  opacity: phase(.65 + i * .018, .12),
                                  child: Transform.translate(
                                    offset: Offset(
                                      0,
                                      12 * (1 - phase(.65 + i * .018, .12)),
                                    ),
                                    child: Text(
                                      'МЕЛЬНИЦА'[i],
                                      style: const TextStyle(
                                        fontFamily: 'serif',
                                        fontSize: 32,
                                        letterSpacing: 5,
                                        color: Color(0xFF765125),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: CustomPaint(painter: _WheatGrainsPainter(t)),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _IntroBandClipper extends CustomClipper<Rect> {
  final double start, end;
  const _IntroBandClipper(this.start, this.end);
  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, size.height * start, size.width, size.height * end);
  @override
  bool shouldReclip(covariant _IntroBandClipper oldClipper) =>
      start != oldClipper.start || end != oldClipper.end;
}

class _WheatGrainsPainter extends CustomPainter {
  final double progress;
  const _WheatGrainsPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = ((progress - .48) / .18).clamp(0.0, 1.0) * .7;
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
