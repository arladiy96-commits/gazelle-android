import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/session_service.dart';
import 'app_shell.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final VideoPlayerController _controller;
  Timer? _fallbackTimer;
  bool _navigated = false;
  bool _ready = false;
  bool _videoError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      'assets/videos/tamerlan_intro.mp4',
    );
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      await _controller.initialize();

      if (!mounted) return;

      _controller
        ..setLooping(false)
        ..play();

      _controller.addListener(_handleVideoState);

      setState(() {
        _ready = true;
      });

      _fallbackTimer = Timer(
        const Duration(seconds: 6),
        _goNext,
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _videoError = true;
      });

      _fallbackTimer = Timer(
        const Duration(milliseconds: 700),
        _goNext,
      );
    }
  }

  void _handleVideoState() {
    if (!_controller.value.isInitialized) return;

    final position = _controller.value.position;
    final duration = _controller.value.duration;

    if (duration > Duration.zero &&
        position >= duration - const Duration(milliseconds: 120)) {
      _goNext();
    }
  }

  Future<void> _goNext() async {
    if (!mounted || _navigated) return;
    _navigated = true;

    final session = await SessionService.read();
    if (!mounted) return;

    final Widget next = session == null
        ? const LoginScreen()
        : AppShell(session: session);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, animation, secondaryAnimation) => next,
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _controller.removeListener(_handleVideoState);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_ready && _controller.value.isInitialized)
            Center(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            const _SplashPlaceholder(),
          if (!_ready && !_videoError)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 48,
              child: _LoadingMark(),
            ),
        ],
      ),
    );
  }
}

class _SplashPlaceholder extends StatelessWidget {
  const _SplashPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF15110D),
            Color(0xFF090A0D),
            Color(0xFF040507),
          ],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

class _LoadingMark extends StatelessWidget {
  const _LoadingMark();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: Color(0xFFFF7A1A),
          ),
        ),
        SizedBox(height: 14),
        Text(
          'ТАМЕРЛАН',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 3.0,
          ),
        ),
      ],
    );
  }
}
