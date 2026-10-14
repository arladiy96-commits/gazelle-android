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
  String? _lastView;
  void refresh() {
    final policy = AccountScope.access.value;
    final view =
        '${AccountScope.restricted}|${AccountScope.revoked.value}|'
        '${policy.blocked}|${policy.reason}|${EmployeeSync.instance.conflict.value}';
    if (_lastView == view) return;
    _lastView = view;
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    AccountScope.access.addListener(refresh);
    AccountScope.revoked.addListener(refresh);
    EmployeeSync.instance.conflict.addListener(refresh);
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
    EmployeeSync.instance.conflict.removeListener(refresh);
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
        if (!restricted && EmployeeSync.instance.conflict.value)
          Positioned(
            left: 12,
            right: 12,
            top: MediaQuery.paddingOf(context).top + 8,
            child: Material(
              color: const Color(0xFF17212B),
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                leading: const Icon(
                  Icons.sync_problem,
                  color: Color(0xFFCEAD70),
                ),
                title: const Text('Есть конфликт данных'),
                subtitle: const Text(
                  'Местные изменения сохранены. Нажмите для проверки.',
                ),
                onTap: busy
                    ? null
                    : () async {
                        final accept = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Загрузить данные сервера?'),
                            content: Text(
                              '${EmployeeSync.instance.message.value ?? "Запись изменена на другом устройстве."}\n\nБудет сохранена резервная копия местных данных. Текущие несинхронизированные изменения заменятся версией сервера. Серверные записи не изменятся.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Оставить пока'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Загрузить с сервера'),
                              ),
                            ],
                          ),
                        );
                        if (accept != true || !mounted) return;
                        setState(() => busy = true);
                        try {
                          await EmployeeSync.instance.useServerVersion();
                        } catch (e) {
                          if (mounted)
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('$e')));
                        } finally {
                          if (mounted) setState(() => busy = false);
                        }
                      },
              ),
            ),
          ),
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
