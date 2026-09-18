import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'preview_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _loginFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _hidePassword = true;
  bool _busy = false;
  String? _error;

  late final AnimationController _controller;
  late final Animation<double> _brandOpacity;
  late final Animation<Offset> _brandSlide;
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _panelOpacity;
  late final Animation<double> _panelScale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _brandOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.00, 0.36, curve: Curves.easeOutCubic),
    );

    _brandSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.42, curve: Curves.easeOutCubic),
      ),
    );

    _contentOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.16, 0.62, curve: Curves.easeOutCubic),
    );

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.16, 0.62, curve: Curves.easeOutCubic),
      ),
    );

    _panelOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.28, 0.90, curve: Curves.easeOutCubic),
    );

    _panelScale = Tween<double>(
      begin: 0.975,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.28, 0.90, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    _loginFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _previewLogin() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    if (_loginController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      HapticFeedback.lightImpact();
      setState(() => _error = 'Введите логин и пароль');
      return;
    }

    setState(() => _busy = true);
    HapticFeedback.selectionClick();

    await Future<void>.delayed(const Duration(milliseconds: 550));

    if (!mounted) return;
    setState(() => _busy = false);

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, animation, secondaryAnimation) =>
            const PreviewHomeScreen(),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.02, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _LoginBackground(),
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                24,
                22,
                24,
                bottomInset > 0 ? 28 : 38,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.sizeOf(context).height -
                      MediaQuery.paddingOf(context).vertical -
                      60,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeTransition(
                      opacity: _brandOpacity,
                      child: SlideTransition(
                        position: _brandSlide,
                        child: const _BrandBlock(),
                      ),
                    ),
                    const SizedBox(height: 58),
                    FadeTransition(
                      opacity: _contentOpacity,
                      child: SlideTransition(
                        position: _contentSlide,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Вход в систему',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                    fontSize: 31,
                                    letterSpacing: -1,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Рабочая система мельницы и логистики',
                              style: TextStyle(
                                color: AppColors.textSoft,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeTransition(
                      opacity: _panelOpacity,
                      child: ScaleTransition(
                        scale: _panelScale,
                        child: _FormPanel(
                          loginField: TextField(
                            controller: _loginController,
                            focusNode: _loginFocus,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username],
                            onSubmitted: (_) => _passwordFocus.requestFocus(),
                            decoration: const InputDecoration(
                              hintText: 'Логин',
                              prefixIcon:
                                  Icon(Icons.person_outline_rounded),
                            ),
                          ),
                          passwordField: TextField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            obscureText: _hidePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onSubmitted: (_) => _previewLogin(),
                            decoration: InputDecoration(
                              hintText: 'Пароль',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(
                                    () => _hidePassword = !_hidePassword,
                                  );
                                },
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                          ),
                          error: _error,
                          actionButton: _PrimaryButton(
                            busy: _busy,
                            onPressed: _busy ? null : _previewLogin,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeTransition(
                      opacity: _panelOpacity,
                      child: const Center(
                        child: Text(
                          'Тестовый вход для проверки интерфейса',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF6C7079),
                            fontSize: 11,
                            letterSpacing: 0.15,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    FadeTransition(
                      opacity: _panelOpacity,
                      child: const _BottomMeta(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF15171B),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF3F2A18)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26FF7A1A),
                blurRadius: 18,
              ),
            ],
          ),
          child: const Icon(
            Icons.grain_rounded,
            color: AppColors.orange,
            size: 26,
          ),
        ),
        const SizedBox(width: 13),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ТАМЕРЛАН',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'MILLING SYSTEM',
              style: TextStyle(
                color: Color(0xFF737780),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.7,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FormPanel extends StatelessWidget {
  final Widget loginField;
  final Widget passwordField;
  final Widget actionButton;
  final String? error;

  const _FormPanel({
    required this.loginField,
    required this.passwordField,
    required this.actionButton,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xED101317),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF292D34)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            blurRadius: 34,
            offset: Offset(0, 18),
          ),
          BoxShadow(
            color: Color(0x1AFF7418),
            blurRadius: 44,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        children: [
          const _TopLineGlow(),
          const SizedBox(height: 10),
          loginField,
          const SizedBox(height: 14),
          passwordField,
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: error == null
                ? const SizedBox(height: 0)
                : Padding(
                    padding: const EdgeInsets.only(top: 13),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 17,
                          color: Color(0xFFE47B6E),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error!,
                            style: const TextStyle(
                              color: Color(0xFFE7A39B),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          actionButton,
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(child: _MiniInfoChip(text: 'Смена')),
              SizedBox(width: 8),
              Expanded(child: _MiniInfoChip(text: 'Логистика')),
              SizedBox(width: 8),
              Expanded(child: _MiniInfoChip(text: 'Учёт')),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopLineGlow extends StatelessWidget {
  const _TopLineGlow();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        gradient: const LinearGradient(
          colors: [
            Color(0x00FF7A1A),
            Color(0xFFFF7A1A),
            Color(0x00FF7A1A),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x88FF6A00),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  final String text;

  const _MiniInfoChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF15181D),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF252932)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSoft,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final bool busy;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF882C),
              Color(0xFFE65A00),
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x45FF6A00),
              blurRadius: 22,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: busy
                ? const SizedBox(
                    key: ValueKey('loader'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    key: ValueKey('label'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ВОЙТИ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(width: 9),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _BottomMeta extends StatelessWidget {
  const _BottomMeta();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 26),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shield_outlined,
            color: Color(0xFF595E68),
            size: 15,
          ),
          SizedBox(width: 7),
          Text(
            'Защищённый доступ',
            style: TextStyle(
              color: Color(0xFF676B74),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF15100B),
            AppColors.background,
            Color(0xFF050608),
          ],
          stops: [0, 0.42, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -110,
            right: -110,
            child: _GlowBall(
              size: 300,
              color: Color(0x20FF6A00),
            ),
          ),
          Positioned(
            left: -80,
            bottom: 120,
            child: _GlowBall(
              size: 220,
              color: Color(0x11FFB46B),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBall extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBall({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 95,
            spreadRadius: 36,
          ),
        ],
      ),
    );
  }
}
