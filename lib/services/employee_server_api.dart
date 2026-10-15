import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../models/employee_access.dart';

class EmployeeApiError implements Exception {
  final int status;
  final String message;
  const EmployeeApiError(this.status, this.message);
  @override
  String toString() => message;
}

/// No endpoint means local mode. Never silently fall back after a server error.
class EmployeeServerApi {
  static const baseUrl = String.fromEnvironment('MELNITSA_API_URL');
  static bool get enabled => baseUrl.isNotEmpty;
  static String? _token;
  static String? dataReadyAccount;
  static void authenticate(String token) {
    if (token.isEmpty) throw const FormatException('Пустой токен');
    dataReadyAccount = null;
    _token = token;
  }

  static void forget() {
    _token = null;
    dataReadyAccount = null;
  }

  static String get source => baseUrl.replaceFirst(RegExp(r'/+$'), '');
  static const _sessionChannel = MethodChannel('melnitsa/shift_gps');
  static Future<Map<String, dynamic>?> savedSession() async {
    final raw = await _sessionChannel.invokeMethod<String>('readSession', {});
    if (raw == null) return null;
    final saved = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return saved['server'] == source ? saved : null;
  }

  static Future<void> saveSession(Map<String, dynamic> employee) async {
    if (!enabled || _token == null) return;
    await _sessionChannel.invokeMethod<void>('saveSession', {
      'value': jsonEncode({
        'server': source,
        'token': _token,
        'employee': employee,
      }),
    });
  }

  static Future<void> clearSavedSession() async {
    if (enabled) await _sessionChannel.invokeMethod<void>('clearSession', {});
  }

  static Future<void> pauseGps(String accountId) async {
    if (!Platform.isAndroid || !enabled) return;
    await const MethodChannel('melnitsa/shift_gps').invokeMethod<void>(
      'configureServer',
      {'account': accountId, 'paused': true},
    );
  }

  static Future<void> resetLocalRoutes(String accountId) async {
    if (!Platform.isAndroid) return;
    await const MethodChannel('melnitsa/shift_gps')
        .invokeMethod<void>('resetServerRoutes', {'account': accountId});
  }

  static Future<void> configureGps(
    String accountId,
    EmployeeAccess access,
    bool owner,
  ) async {
    if (!Platform.isAndroid) return;
    if (enabled && dataReadyAccount != accountId) {
      await pauseGps(accountId);
      return;
    }
    await const MethodChannel('melnitsa/shift_gps')
        .invokeMethod<void>('configureServer', {
          'account': accountId,
          'url': enabled ? baseUrl : '',
          'token': _token,
          'access': {
            ...access.toJson(),
            if (access.validUntil != null)
              'validUntil': DateTime.fromMillisecondsSinceEpoch(
                access.validUntil!.millisecondsSinceEpoch,
                isUtc: true,
              ).toIso8601String(),
          },
          'owner': owner,
        });
  }

  static Future<void> clearGps(String accountId) async {
    if (!Platform.isAndroid) return;
    await const MethodChannel(
      'melnitsa/shift_gps',
    ).invokeMethod<void>('configureServer', {'account': accountId, 'url': ''});
  }

  static bool get authenticated => _token != null;
  static Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool anonymous = false,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final base = Uri.parse(baseUrl);
    if (base.scheme != 'https' ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment) {
      throw StateError('Для сервера нужен HTTPS-адрес без пароля и параметров');
    }
    if (!anonymous && _token == null)
      throw const EmployeeApiError(401, 'Войдите заново');
    final uri = Uri.parse(
      '${baseUrl.replaceFirst(RegExp(r"/+$"), "")}/v1$path',
    );
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      return await (() async {
        final request = await client.openUrl(method, uri);
        request.followRedirects = false;
        request.headers.contentType = ContentType.json;
        if (!anonymous)
          request.headers.set(
            HttpHeaders.authorizationHeader,
            'Bearer $_token',
          );
        if (body != null) {
          final payload =
              path == '/me/sync' ||
                  path.contains('/routes/') ||
                  path == '/invoices/recognize'
              ? await compute(_encodeApiBody, body)
              : _encodeApiBody(body);
          // The Python server reads Content-Length, not chunked request bodies.
          request.contentLength = payload.length;
          request.add(payload);
        }
        final response = await request.close();
        final bytes = <int>[];
        await for (final chunk in response) {
          if (bytes.length + chunk.length > 16 * 1024 * 1024)
            throw const FormatException('Ответ слишком большой');
          bytes.addAll(chunk);
        }
        final data = bytes.isEmpty
            ? <String, dynamic>{}
            : bytes.length > 64 * 1024
            ? await compute(_decodeApiResponse, bytes)
            : _decodeApiResponse(bytes);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw EmployeeApiError(
            response.statusCode,
            data['message'] as String? ??
                data['error'] as String? ??
                'Ошибка сервера ${response.statusCode}',
          );
        }
        return data;
      })().timeout(timeout);
    } finally {
      client.close(force: true);
    }
  }
}

List<int> _encodeApiBody(Map<String, dynamic> body) =>
    utf8.encode(jsonEncode(body));
Map<String, dynamic> _decodeApiResponse(List<int> bytes) =>
    Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map);
