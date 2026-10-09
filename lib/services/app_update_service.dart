import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';

import 'app_update_manifest.dart';

class AppUpdateService {
  static const repository = String.fromEnvironment('UPDATE_REPOSITORY');
  static const channel = MethodChannel('melnitsa/app_update');
  static bool checkedAtStartup = false;
  static bool dialogOpen = false;
  HttpClient? _client;
  Future<void>? _download;
  bool _cancelled = false;

  Future<Map<dynamic, dynamic>> info() async =>
      (await channel.invokeMapMethod<dynamic, dynamic>('info'))!;

  HttpClient _newClient() {
    if (_cancelled) throw const FormatException('Загрузка отменена.');
    return _client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
  }

  Future<AppUpdateManifest> check() async {
    if (!RegExp(r'^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$').hasMatch(repository)) {
      throw const FormatException(
        'Источник обновлений не настроен в этой сборке.',
      );
    }
    final client = _newClient();
    try {
      final req = await client.getUrl(
        Uri.https(
          'github.com',
          '/$repository/releases/latest/download/update.json',
        ),
      );
      final response = await req.close().timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) {
        throw const FormatException(
          'Обновление недоступно. Проверьте интернет и наличие опубликованного релиза.',
        );
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 25))) {
        bytes.addAll(chunk);
        if (bytes.length > 65536)
          throw const FormatException('Файл обновления слишком большой.');
      }
      return AppUpdateManifest.parse(
        jsonDecode(utf8.decode(bytes)),
        repository,
      );
    } finally {
      client.close(force: true);
      if (identical(_client, client)) _client = null;
    }
  }

  Future<void> download(
    AppUpdateManifest update,
    void Function(double) progress,
  ) {
    return _download = _performDownload(update, progress);
  }

  Future<void> _performDownload(
    AppUpdateManifest update,
    void Function(double) progress,
  ) async {
    final device = await info();
    final file = File(device['apkPath'] as String);
    final part = File('${file.path}.part');
    final client = _newClient();
    IOSink? sink;
    try {
      if (await file.exists()) await file.delete();
      final req = await client.getUrl(update.url);
      final response = await req.close().timeout(const Duration(seconds: 30));
      if (response.statusCode != 200 ||
          (response.contentLength >= 0 &&
              response.contentLength != update.size)) {
        throw const FormatException(
          'Не удалось загрузить APK. Повторите попытку.',
        );
      }
      sink = part.openWrite();
      var received = 0;
      await for (final chunk in response.timeout(const Duration(seconds: 45))) {
        if (_cancelled) throw const FormatException('Загрузка отменена.');
        received += chunk.length;
        if (received > update.size)
          throw const FormatException('Размер APK не совпадает.');
        sink.add(chunk);
        await sink.flush();
        progress(received / update.size);
      }
      await sink.close();
      sink = null;
      if (_cancelled || received != update.size)
        throw const FormatException('APK загружен не полностью.');
      final hashSink = Sha256().newHashSink();
      await for (final chunk in part.openRead()) {
        if (_cancelled) throw const FormatException('Загрузка отменена.');
        hashSink.add(chunk);
      }
      hashSink.close();
      final digest = await hashSink.hash();
      final hash = digest.bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      if (hash != update.sha256)
        throw const FormatException(
          'Проверка APK не пройдена. Загрузите заново.',
        );
      if (_cancelled) throw const FormatException('Загрузка отменена.');
      await part.rename(file.path);
    } finally {
      await sink?.close();
      client.close(force: true);
      if (identical(_client, client)) _client = null;
      if (await part.exists()) await part.delete();
    }
  }

  Future<String?> install(AppUpdateManifest update) =>
      channel.invokeMethod<String>('install', {
        'sha256': update.sha256,
        'versionCode': update.code,
      });
  Future<void> openPermission() => channel.invokeMethod<void>('permission');
  Future<void> close() async {
    cancel();
    try {
      await _download;
    } catch (_) {}
  }

  void cancel() {
    _cancelled = true;
    _client?.close(force: true);
  }
}
