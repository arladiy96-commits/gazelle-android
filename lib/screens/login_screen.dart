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

  late final AnimationController _entranceController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );

    _fade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.045),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
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

    await Future<void>.delayed(const Duration(milliseconds: 520));

    if (!mounted) return;
    setState(() => _busy = false);

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, animation, __) => const PreviewHomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.025, 0),
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
        children: [
          const _LoginBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    bottomInset > 0 ? 30 : 48,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.sizeOf(context).height -
                          MediaQuery.paddingOf(context).vertical -
                          72,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _MiniBrand(),
                        const SizedBox(height: 72),
                        Text(
                          'Добро пожаловать',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Войдите в рабочую систему',
                          style: TextStyle(
                            color: AppColors.textSoft,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 36),
                        _GlassPanel(
                          child: Column(
                            children: [
                              TextField(
                                controller: _loginController,
                                focusNode: _loginFocus,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.username],
                                onSubmitted: (_) =>
                                    _passwordFocus.requestFocus(),
                                decoration: const InputDecoration(
                                  hintText: 'Логин',
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
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
                              AnimatedSize(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                                child: _error == null
                                    ? const SizedBox(height: 0)
                                    : Padding(
                                        padding:
                                            const EdgeInsets.only(top: 13),
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
                                                _error!,
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
                              _PrimaryButton(
                                busy: _busy,
                                onPressed: _busy ? null : _previewLogin,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Center(
                          child: Text(
                            'Пока это тестовый вход для проверки интерфейса.\n'
                            'Подключение к серверу добавим следующим этапом.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF666A73),
                              height: 1.45,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 34),
                        const _SecurityRow(),
                      ],
                    ),
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

class _MiniBrand extends StatelessWidget {
  const _MiniBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF15171B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF4D290E)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26FF7A1A),
                blurRadius: 18,
              ),
            ],
          ),
          child: const Icon(
            Icons.local_shipping_rounded,
            color: AppColors.orange,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ГАЗЕЛЬ',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.9,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'DRIVER SYSTEM',
              style: TextStyle(
                color: Color(0xFF6D717A),
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;

  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xE6111318),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFF292C33)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
          BoxShadow(
            color: Color(0x15FF7A1A),
            blurRadius: 34,
            spreadRadius: -5,
          ),
        ],
      ),
      child: child,
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
            colors: [Color(0xFFFF8426), Color(0xFFE95B00)],
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

class _SecurityRow extends StatelessWidget {
  const _SecurityRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.shield_outlined,
          color: Color(0xFF555A64),
          size: 15,
        ),
        SizedBox(width: 7),
        Text(
          'Защищённый доступ',
          style: TextStyle(
            color: Color(0xFF666A73),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF14100D),
              AppColors.background,
              Color(0xFF07080A),
            ],
            stops: [0, 0.42, 1],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -110,
              right: -110,
              child: Container(
                width: 280,
                height: 280,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x20FF6A00),
                      blurRadius: 90,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
