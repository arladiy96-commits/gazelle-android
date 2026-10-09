import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_update_manifest.dart';
import '../services/app_update_service.dart';

Future<void> showAppUpdate(
  BuildContext context, {
  bool automatic = false,
  Future<void> Function()? beforeInstall,
}) async {
  if (!Platform.isAndroid || AppUpdateService.dialogOpen) return;
  if (automatic) {
    if (AppUpdateService.checkedAtStartup) return;
    AppUpdateService.checkedAtStartup = true;
  }
  AppUpdateService.dialogOpen = true;
  final service = AppUpdateService();
  try {
    AppUpdateManifest? initial;
    if (automatic) {
      try {
        initial = await service.check();
        final info = await service.info();
        if (initial.code <= (info['versionCode'] as num).toInt()) return;
      } catch (_) {
        return;
      }
      if (!context.mounted || ModalRoute.of(context)?.isCurrent != true) return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UpdateDialog(
        service: service,
        initial: initial,
        beforeInstall: beforeInstall,
      ),
    );
  } finally {
    await service.close();
    AppUpdateService.dialogOpen = false;
  }
}

class _UpdateDialog extends StatefulWidget {
  final AppUpdateService service;
  final AppUpdateManifest? initial;
  final Future<void> Function()? beforeInstall;
  const _UpdateDialog({
    required this.service,
    this.initial,
    this.beforeInstall,
  });
  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  AppUpdateManifest? _update;
  bool _busy = true, _ready = false, _permission = false;
  bool _installing = false;
  double? _progress;
  String _message = 'Проверяем обновления…';
  @override
  void initState() {
    super.initState();
    _check();
  }

  void _change(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  String _error(Object e) => e is FormatException
      ? e.message
      : e is PlatformException
      ? (e.message ?? 'Ошибка Android.')
      : 'Не удалось выполнить действие. Проверьте интернет и повторите попытку.';
  Future<void> _check() async {
    _change(() {
      _busy = true;
      _update = null;
    });
    try {
      final info = await widget.service.info();
      final update = widget.initial ?? await widget.service.check();
      _change(() {
        if (update.code > (info['versionCode'] as num).toInt()) {
          _update = update;
          _message =
              'Доступна версия ${update.version} (${update.code}).\n'
              'Установлена ${info['versionName']} (${info['versionCode']}).\n\n'
              'Размер: ${(update.size / 1048576).toStringAsFixed(1)} МБ. '
              'Обновление устанавливается поверх приложения. Завершите ввод данных перед установкой.';
        } else {
          _message =
              'Установлена актуальная версия ${info['versionName']} (${info['versionCode']}).';
        }
      });
    } catch (e) {
      _change(() => _message = _error(e));
    } finally {
      _change(() => _busy = false);
    }
  }

  Future<void> _run() async {
    final update = _update;
    if (update == null || _busy) return;
    _change(() => _busy = true);
    try {
      if (!_ready) {
        _change(() {
          _message = 'Загружаем и проверяем APK…';
          _progress = 0;
        });
        await widget.service.download(
          update,
          (v) => _change(() => _progress = v),
        );
        if (!mounted) return;
        _ready = true;
      }
      if (!mounted) return;
      _change(() => _installing = true);
      await widget.beforeInstall?.call();
      if (!mounted) return;
      final result = await widget.service.install(update);
      _change(() {
        _permission = result == 'permission';
        _message = _permission
            ? 'Разрешите «Мельнице» установку приложений в настройках Android. Затем вернитесь сюда и нажмите «Установить».'
            : 'Открылся установщик Android. Подтвердите обновление. Если вы отменили установку, её можно запустить повторно.';
      });
    } catch (e) {
      _change(() {
        _message = _error(e);
        _ready = false;
        _permission = false;
      });
    } finally {
      _change(() {
        _busy = false;
        _installing = false;
        _progress = null;
      });
    }
  }

  Future<void> _settings() async {
    try {
      await widget.service.openPermission();
    } catch (e) {
      _change(() => _message = _error(e));
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_installing,
    child: AlertDialog(
      backgroundColor: const Color(0xFF0D171E),
      title: const Text(
        'Обновление приложения',
        style: TextStyle(color: Color(0xFFE0B566)),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_message, style: const TextStyle(color: Color(0xFFCED3D6))),
            if (_busy) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(value: _progress),
            ],
            if (_progress != null)
              Text('${(_progress! * 100).toStringAsFixed(0)}%'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _installing ? null : () => Navigator.pop(context),
          child: Text(_busy ? 'Отмена' : 'Закрыть'),
        ),
        if (!_busy && _permission)
          TextButton(
            onPressed: _settings,
            child: const Text('Настройки Android'),
          ),
        if (!_busy && _update != null)
          FilledButton(
            onPressed: _run,
            child: Text(_ready ? 'Установить' : 'Скачать обновление'),
          ),
        if (!_busy && _update == null)
          TextButton(onPressed: _check, child: const Text('Проверить ещё раз')),
      ],
    ),
  );
}
