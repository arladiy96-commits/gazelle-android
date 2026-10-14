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
  bool _detailsOpen = false, _confirmServer = false;
  String? _resolutionError;
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

  void _closeDetails() {
    if (busy) return;
    setState(() {
      _detailsOpen = false;
      _confirmServer = false;
    });
  }

  Future<void> _loadServer() async {
    if (busy) return;
    setState(() {
      busy = true;
      _resolutionError = null;
    });
    try {
      await EmployeeSync.instance.useServerVersion();
      if (mounted) setState(() => _detailsOpen = false);
    } catch (e) {
      if (mounted) setState(() => _resolutionError = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  // This gate is above the root Navigator in MaterialApp.builder. Its context
  // cannot push a dialog route; display details directly in the gate's overlay.
  Widget _conflictDetails() => Stack(
    fit: StackFit.expand,
    children: [
      ModalBarrier(
        color: Colors.black54,
        dismissible: !busy,
        onDismiss: _closeDetails,
      ),
      SafeArea(
        child: Center(
          child: AlertDialog(
            title: Text(
              _confirmServer ? 'Заменить местные данные?' : 'Причина конфликта',
            ),
            content: SingleChildScrollView(
              child: ValueListenableBuilder<String?>(
                valueListenable: EmployeeSync.instance.message,
                builder: (_, message, __) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      message ?? 'Подробности ошибки пока недоступны.',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _confirmServer
                          ? 'Будет сохранена резервная копия местных данных. Текущие несинхронизированные изменения заменятся версией сервера. Серверные записи не изменятся.'
                          : 'Просмотр этого окна не изменяет данные. Можно скопировать текст ошибки или сделать скриншот.',
                    ),
                    if (_resolutionError != null) ...[
                      const SizedBox(height: 12),
                      SelectableText(_resolutionError!),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : _closeDetails,
                child: const Text('Закрыть'),
              ),
              if (_confirmServer)
                TextButton(
                  onPressed: busy ? null : _loadServer,
                  child: Text(busy ? 'Загрузка…' : 'Подтвердить замену'),
                )
              else
                TextButton(
                  onPressed: busy
                      ? null
                      : () => setState(() => _confirmServer = true),
                  child: const Text('Версия сервера…'),
                ),
            ],
          ),
        ),
      ),
    ],
  );

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
                onTap: () => setState(() {
                  _detailsOpen = true;
                  _confirmServer = false;
                  _resolutionError = null;
                }),
              ),
            ),
          ),
        if (!restricted && _detailsOpen)
          Positioned.fill(child: _conflictDetails()),
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
