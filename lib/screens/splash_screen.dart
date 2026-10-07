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
      duration: const Duration(milliseconds: 3000),
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
            : const Duration(milliseconds: 180),
        pageBuilder: (_, animation, secondaryAnimation) => next,
        transitionsBuilder: (_, animation, secondaryAnimation, child) =>
            ColoredBox(
              // Opaque backing keeps the old artwork out of the new screen.
              color: const Color(0xFFF5F2EB),
              child: FadeTransition(opacity: animation, child: child),
            ),
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
                      // Corner clusters and the central ear arrive together.
                      for (final top in [true, false])
                        Positioned.fill(
                          child: Transform.translate(
                            offset: Offset(
                              (top ? 55 : -55) *
                                  (1 - phase(top ? .0 : .035, .24)),
                              (top ? -20 : 20) *
                                  (1 - phase(top ? .0 : .035, .24)),
                            ),
                            child: Opacity(
                              opacity: .68 * phase(top ? .0 : .035, .24),
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
                      // Reveal one intact ear with a feathered mask.
                      Positioned(
                        top: earTop,
                        left: (w - earWidth) / 2,
                        width: earWidth,
                        height: earHeight,
                        child: ShaderMask(
                          blendMode: BlendMode.dstIn,
                          shaderCallback: (bounds) {
                            final progress = Curves.easeInOutCubic.transform(
                              ((t - .025) / .54).clamp(0.0, 1.0),
                            );
                            final front =
                                bounds.top +
                                bounds.height * (1.1 - 1.2 * progress);
                            return const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.white],
                              stops: [0, 1],
                            ).createShader(
                              Rect.fromLTRB(
                                bounds.left,
                                front - bounds.height * .08,
                                bounds.right,
                                front + bounds.height * .08,
                              ),
                            );
                          },
                          child: ShaderMask(
                            // One restrained light pass, clipped to the PNG's
                            // alpha. It never lights the surrounding background.
                            blendMode: BlendMode.srcATop,
                            shaderCallback: (bounds) {
                              final sweep = ((t - .61) / .24).clamp(0.0, 1.0);
                              final x = bounds.width * (-.5 + 2 * sweep);
                              final strength = math.sin(math.pi * sweep) * .28;
                              return LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFFFFF1CF)
                                      .withValues(alpha: strength),
                                  Colors.transparent,
                                ],
                                stops: const [0, .5, 1],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(
                                Rect.fromLTWH(
                                  x - bounds.width * .23,
                                  0,
                                  bounds.width * .46,
                                  bounds.height,
                                ),
                              );
                            },
                            child: artwork('mill_intro_ear.png'),
                          ),
                        ),
                      ),
                      // Name begins while the ear is finishing its reveal.
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
                                  opacity: phase(.43 + i * .015, .13),
                                  child: Transform.translate(
                                    offset: Offset(
                                      0,
                                      12 * (1 - phase(.43 + i * .015, .13)),
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
    final opacity = ((progress - .40) / .18).clamp(0.0, 1.0) * .7;
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
