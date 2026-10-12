import 'dart:async';

import 'package:flutter/material.dart';

import '../services/account_scope.dart';
import '../services/employee_sync.dart';

class EmployeeAccessGate extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onLogout;
  const EmployeeAccessGate({
    super.key,
    required this.child,
    required this.onLogout,
  });
  @override
  State<EmployeeAccessGate> createState() => _EmployeeAccessGateState();
}

class _EmployeeAccessGateState extends State<EmployeeAccessGate> {
  Timer? timer;
  bool busy = false;
  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    AccountScope.access.addListener(refresh);
    AccountScope.revoked.addListener(refresh);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (AccountScope.signedIn &&
          AccountScope.access.value.expiredAt(DateTime.now()))
        refresh();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    AccountScope.access.removeListener(refresh);
    AccountScope.revoked.removeListener(refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restricted = AccountScope.restricted;
    final policy = AccountScope.access.value;
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(offstage: restricted, child: widget.child),
        if (restricted)
          Material(
            color: const Color(0xFF0B141B),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 48,
                        color: Color(0xFFCEAD70),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        policy.blocked
                            ? 'Доступ заблокирован'
                            : 'Требуется проверка доступа',
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        policy.reason.isNotEmpty
                            ? policy.reason
                            : AccountScope.revoked.value
                            ? 'Сеанс завершён владельцем. Войдите заново.'
                            : 'Срок автономного доступа истёк. Подключитесь к интернету.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => EmployeeSync.instance.tick(),
                        child: const Text('Проверить доступ'),
                      ),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () async {
                                setState(() => busy = true);
                                try {
                                  await widget.onLogout();
                                } finally {
                                  if (mounted) setState(() => busy = false);
                                }
                              },
                        child: const Text('Выйти'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
