import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';

import 'account_scope.dart';
import 'employee_server_api.dart';
import 'test_store.dart';

/// Explicit owner reads, never impersonate the employee or switch AccountScope.
class EmployeeDataService {
  static const channel = MethodChannel('melnitsa/shift_gps');
  static Future<Map<String, dynamic>> localData(String id) async {
    final scope = AccountScope.capture();
    if (id != scope.id) AccountScope.requireAdmin();
    final disk = await SharedPreferences.getInstance();
    scope.check();
    final raw = disk.getString('${TestPreferences.storageKey}_account_$id');
    return {
      'accountId': id,
      'receivedAt': null,
      'preferences': raw == null ? <String, dynamic>{} : jsonDecode(raw),
      'loaderShifts': jsonDecode(
        disk.getString('melnitsa_loader_shifts_v1_$id') ?? '[]',
      ),
    };
  }

  static Future<Map<String, dynamic>> read(String id) async {
    AccountScope.requireAdmin();
    final scope = AccountScope.capture();
    final result = EmployeeServerApi.enabled
        ? await EmployeeServerApi.request(
            'GET',
            '/employees/${Uri.encodeComponent(id)}/data',
          )
        : await localData(id);
    scope.check();
    AccountScope.requireAdmin();
    if (result['accountId'] != id)
      throw const FormatException('Данные другого сотрудника');
    return result;
  }

  static Future<List<Map<String, dynamic>>> route(
    String id,
    String shiftId,
  ) async {
    AccountScope.requireAdmin();
    final scope = AccountScope.capture();
    final result = EmployeeServerApi.enabled
        ? await EmployeeServerApi.request(
            'GET',
            '/employees/${Uri.encodeComponent(id)}/routes/${Uri.encodeComponent(shiftId)}',
          )
        : await localRoute(id, shiftId);
    scope.check();
    AccountScope.requireAdmin();
    return (result['points'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static Future<Map<String, dynamic>> localRoute(
    String id,
    String shiftId,
  ) async {
    final scope = AccountScope.capture();
    if (id != scope.id) AccountScope.requireAdmin();
    final data = await localData(id);
    final preferences = data['preferences'] as Map;
    final raw = preferences['gazelle_real_gps_routes_v1'];
    final legacy = raw is String ? jsonDecode(raw) as Map : {};
    final old = legacy[shiftId] as Map? ?? {};
    final native = Platform.isAndroid
        ? await channel.invokeMapMethod<String, dynamic>(
                id == scope.id ? 'route' : 'ownerRoute',
                {'account': id, 'actor': scope.id, 'shift': shiftId},
              ) ??
              {}
        : <String, dynamic>{};
    scope.check();
    return {
      'points': [
        ...old['points'] as List? ?? [],
        ...native['points'] as List? ?? [],
      ],
    };
  }
}
