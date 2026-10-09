import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/session_service.dart';
import 'app_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController(),
      _login = TextEditingController(),
      _password = TextEditingController(),
      _confirmation = TextEditingController();
  bool? _setup;
  bool _busy = false, _hide = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final setup = await SessionService.needsSetup();
      if (mounted) setState(() => _setup = setup);
    } catch (_) {
      if (mounted)
        setState(
          () => _error =
              'Не удалось прочитать учётные записи. Повторите попытку.',
        );
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _login, _password, _confirmation]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || _setup == null) return;
    if (_setup! && _password.text != _confirmation.text) {
      setState(() => _error = 'Пароли не совпадают');
      return;
    }
    if (_login.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Введите логин и пароль');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = _setup!
          ? await SessionService.createFirstAdmin(
              name: _name.text,
              login: _login.text,
              password: _password.text,
            )
          : await SessionService.signIn(
              login: _login.text,
              password: _password.text,
            );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) =>
              AppShell(key: ValueKey(session.accountId), session: session),
        ),
        (_) => false,
      );
    } catch (e) {
      final setup = await SessionService.needsSetup();
      if (mounted)
        setState(() {
          _busy = false;
          _setup = setup;
          _error = e is ArgumentError
              ? '${e.message}'
              : e is StateError
              ? '${e.message}'
              : 'Не удалось выполнить вход. Повторите попытку.';
        });
    }
  }

  Widget field(TextEditingController c, String label, {bool secret = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          controller: c,
          enabled: !_busy,
          obscureText: secret && _hide,
          autocorrect: !secret && c == _name,
          enableSuggestions: !secret && c == _name,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: const Color(0xFF10191F),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: secret
                ? IconButton(
                    tooltip: _hide ? 'Показать пароль' : 'Скрыть пароль',
                    onPressed: () => setState(() => _hide = !_hide),
                    icon: Icon(
                      _hide
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  )
                : null,
          ),
        ),
      );
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
    child: Scaffold(
      backgroundColor: const Color(0xFF091218),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/scenes/employees_reference.png',
            fit: BoxFit.cover,
          ),
          const ColoredBox(color: Color(0x57020A10)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xF20B141B),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFB79254)),
                      boxShadow: const [
                        BoxShadow(color: Colors.black, blurRadius: 24),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.grain,
                          color: Color(0xFFE3B66A),
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'МЕЛЬНИЦА',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFE3B66A),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          _setup == true
                              ? 'Создать администратора'
                              : 'Вход в приложение',
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _setup == true
                              ? 'Создайте свою учётную запись. После входа вы сможете добавить сотрудников и назначить роли.'
                              : 'Введите логин и пароль своей учётной записи.',
                          style: const TextStyle(
                            color: Color(0xFFAFBAC1),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_setup == null && _error == null)
                          const Center(child: CircularProgressIndicator())
                        else if (_setup != null) ...[
                          if (_setup!) field(_name, 'Имя'),
                          field(_login, 'Логин'),
                          field(_password, 'Пароль', secret: true),
                          if (_setup!)
                            field(
                              _confirmation,
                              'Повторите пароль',
                              secret: true,
                            ),
                        ],
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Color(0xFFE6B56A)),
                            ),
                          ),
                        FilledButton(
                          onPressed: _busy
                              ? null
                              : _setup == null
                              ? _check
                              : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFBE944E),
                            foregroundColor: const Color(0xFF071219),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            _busy
                                ? 'Подождите…'
                                : _setup == null
                                ? 'Повторить'
                                : _setup!
                                ? 'Создать и войти'
                                : 'Войти',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
