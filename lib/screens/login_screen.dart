import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_role.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import 'app_shell.dart';

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

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _brandOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.45, curve: Curves.easeOutCubic),
    );

    _brandSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.50, curve: Curves.easeOutCubic),
      ),
    );

    _contentOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.18, 1, curve: Curves.easeOutCubic),
    );

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 1, curve: Curves.easeOutCubic),
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

  Future<void> _login() async {
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

    await Future<void>.delayed(
      const Duration(milliseconds: 450),
    );

    final session = await SessionService.createTestSession(
      login: _loginController.text,
    );

    if (!mounted) return;

    setState(() => _busy = false);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, animation, secondaryAnimation) =>
            AppShell(session: session),
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

  AppRole get _previewRole =>
      AppRole.fromTestLogin(_loginController.text);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _LoginBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 50,
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
                        const SizedBox(height: 54),
                        FadeTransition(
                          opacity: _contentOpacity,
                          child: SlideTransition(
                            position: _contentSlide,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Вход в систему',
                                  style: TextStyle(
                                    color: AppColors.text,
                                    fontSize: 31,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Мельница • логистика • рабочие смены',
                                  style: TextStyle(
                                    color: AppColors.textSoft,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                _FormPanel(
                                  loginField: TextField(
                                    controller: _loginController,
                                    focusNode: _loginFocus,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.username,
                                    ],
                                    onChanged: (_) => setState(() {}),
                                    onSubmitted: (_) =>
                                        _passwordFocus.requestFocus(),
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
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    onSubmitted: (_) => _login(),
                                    decoration: InputDecoration(
                                      hintText: 'Пароль',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline_rounded,
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _hidePassword = !_hidePassword;
                                          });
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
                                  busy: _busy,
                                  onPressed: _busy ? null : _login,
                                  role: _previewRole,
                                ),
                                const SizedBox(height: 18),
                                const _TestHint(),
                                const SizedBox(height: 46),
                                const _BottomMeta(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
  final String? error;
  final bool busy;
  final VoidCallback? onPressed;
  final AppRole role;

  const _FormPanel({
    required this.loginField,
    required this.passwordField,
    required this.error,
    required this.busy,
    required this.onPressed,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xF2111317),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.line),
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
          const SizedBox(height: 12),
          loginField,
          const SizedBox(height: 14),
          passwordField,
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: error == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 13),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 17,
                          color: AppColors.red,
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
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _RolePreview(
              key: ValueKey(role),
              role: role,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
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
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 20,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePreview extends StatelessWidget {
  final AppRole role;

  const _RolePreview({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color accent;

    switch (role) {
      case AppRole.admin:
        icon = Icons.admin_panel_settings_outlined;
        accent = AppColors.violet;
        break;
      case AppRole.driver:
        icon = Icons.local_shipping_outlined;
        accent = AppColors.orange;
        break;
      case AppRole.loader:
        icon = Icons.inventory_2_outlined;
        accent = AppColors.blue;
        break;
    }

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF15181D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF252932)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: 10),
          const Text(
            'Режим:',
            style: TextStyle(
              color: AppColors.textDim,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            role.title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
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

class _TestHint extends StatelessWidget {
  const _TestHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x99101216),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF23272E)),
      ),
      child: const Text(
        'Для проверки ролей: login admin → администратор, loader → грузчик, любой другой логин → водитель. Пароль пока тестовый — любой непустой.',
        style: TextStyle(
          color: AppColors.textSoft,
          height: 1.45,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _BottomMeta extends StatelessWidget {
  const _BottomMeta();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
            Color(0xFF171008),
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
