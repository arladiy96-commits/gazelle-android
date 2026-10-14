import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gazelle_android/services/account_scope.dart';
import 'package:gazelle_android/services/employee_server_api.dart';
import 'package:gazelle_android/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('melnitsa/shift_gps');
  String? vault;
  Map<String, dynamic> employee() => {
    'id': '42',
    'name': 'Owner',
    'login': 'owner',
    'role': 'admin',
    'active': true,
    'isOwner': true,
    'access': {
      'status': 'active',
      'validUntil': DateTime.now()
          .add(const Duration(hours: 1))
          .toIso8601String(),
    },
  };
  void seed(Map<String, dynamic> row, {String? server}) {
    vault = jsonEncode({
      'server': server ?? EmployeeServerApi.source,
      'token': 'test-token',
      'employee': row,
    });
  }

  setUp(() {
    SessionService.current = null;
    AccountScope.close();
    EmployeeServerApi.forget();
    SharedPreferences.setMockInitialValues({
      'employee_server_source_v1_42': EmployeeServerApi.source,
      'employee_sync_version_42': 7,
      'employee_sync_pending_42': 'unsent-new-record',
    });
    seed(employee());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'readSession':
              return vault;
            case 'saveSession':
              vault = (call.arguments as Map)['value'] as String;
              return null;
            case 'clearSession':
              vault = null;
              return null;
            default:
              return null;
          }
        });
  });
  tearDown(() {
    SessionService.current = null;
    AccountScope.close();
    EmployeeServerApi.forget();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  group('server session restore', () {
    test('restores offline and preserves pending changes', () async {
      expect((await SessionService.read())?.accountId, '42');
      expect(EmployeeServerApi.dataReadyAccount, '42');
      expect(
        (await SharedPreferences.getInstance()).getString(
          'employee_sync_pending_42',
        ),
        'unsent-new-record',
      );
      final scope = AccountScope.capture();
      await SessionService.read();
      expect(scope.valid, isTrue);
    });
    test('logout removes saved token', () async {
      await SessionService.read();
      await SessionService.clear();
      expect(vault, isNull);
      expect(await SessionService.read(), isNull);
    });
    test('different server cannot restore identity', () async {
      seed(employee(), server: 'https://other.example');
      expect(await SessionService.read(), isNull);
      expect(AccountScope.signedIn, isFalse);
    });
    test('incomplete bootstrap cannot enable uploads', () async {
      await (await SharedPreferences.getInstance()).remove(
        'employee_server_source_v1_42',
      );
      expect(await SessionService.read(), isNull);
      expect(EmployeeServerApi.dataReadyAccount, isNull);
    });
    test('expired offline permission remains restricted', () async {
      final row = employee();
      (row['access'] as Map)['validUntil'] = DateTime.now()
          .subtract(const Duration(hours: 1))
          .toIso8601String();
      seed(row);
      expect(await SessionService.read(), isNotNull);
      expect(AccountScope.restricted, isTrue);
    });
    test('damaged saved session fails closed', () async {
      vault = '{broken';
      expect(await SessionService.read(), isNull);
      expect(AccountScope.signedIn, isFalse);
      expect(EmployeeServerApi.dataReadyAccount, isNull);
    });
  }, skip: !EmployeeServerApi.enabled);
}
