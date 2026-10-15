import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'employee_server_api.dart';
import 'account_scope.dart';
import '../models/loading_invoice.dart';

class InvoiceRecognitionResult {
  final List<LoadingInvoiceItem> items;
  final double? statedWeightKg;
  final bool isMock;
  final List<String> warnings;
  const InvoiceRecognitionResult({
    required this.items,
    this.statedWeightKg,
    this.isMock = false,
    this.warnings = const [],
  });
}

/// Replace the injected implementation with a server client. The client sends
/// these local pages to OUR authenticated server; AI credentials stay there.
/// Server response: items[{itemId,name,unitWeightKg,bagsCount,totalWeightKg}],
/// statedWeightKg. Missing/uncertain weights must not be silently corrected.
abstract class InvoiceRecognitionService {
  Future<InvoiceRecognitionResult> recognize({
    required String invoiceId,
    required List<String> photoPaths,
  });
}

class MockInvoiceRecognitionService implements InvoiceRecognitionService {
  @override
  Future<InvoiceRecognitionResult> recognize({
    required String invoiceId,
    required List<String> photoPaths,
  }) async {
    if (photoPaths.isEmpty) throw ArgumentError('Добавьте фото накладной');
    await Future<void>.delayed(const Duration(milliseconds: 650));
    // Deliberate mismatch demonstrates review; these are NOT extracted values.
    return InvoiceRecognitionResult(
      isMock: true,
      statedWeightKg: 875,
      items: [
        LoadingInvoiceItem(
          itemId: invoiceEntityId(),
          name: 'Пример: мука высший сорт',
          unitWeightKg: 25,
          bagsCount: 15,
          totalWeightKg: 375,
        ),
        LoadingInvoiceItem(
          itemId: invoiceEntityId(),
          name: 'Пример: мука первый сорт',
          unitWeightKg: 50,
          bagsCount: 10,
          totalWeightKg: 480,
        ),
      ],
    );
  }
}

class ServerInvoiceRecognitionService implements InvoiceRecognitionService {
  @override
  Future<InvoiceRecognitionResult> recognize({
    required String invoiceId,
    required List<String> photoPaths,
  }) async {
    final scope = AccountScope.capture();
    AccountScope.requireWrite('invoices');
    if (!EmployeeServerApi.enabled)
      throw StateError('Для распознавания подключите сервер');
    if (photoPaths.isEmpty || photoPaths.length > 6)
      throw ArgumentError('Добавьте от 1 до 6 фотографий');
    final items = <LoadingInvoiceItem>[];
    final warnings = <String>[];
    double? stated;
    for (final path in photoPaths) {
      scope.check();
      final file = File(path);
      if (await file.length() > 8 * 1024 * 1024)
        throw ArgumentError('Фото больше 8 МБ. Выберите уменьшенный снимок');
      final bytes = await file.readAsBytes();
      final mime = bytes.length > 12 && bytes[0] == 0x89 && bytes[1] == 0x50
          ? 'image/png'
          : bytes.length > 12 &&
                ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF'
          ? 'image/webp'
          : 'image/jpeg';
      final encoded = await compute(_encodeInvoicePhoto, bytes);
      scope.check();
      final response = await EmployeeServerApi.request(
        'POST',
        '/invoices/recognize',
        body: {'image_base64': encoded, 'mime_type': mime},
        timeout: const Duration(minutes: 4),
      );
      scope.check();
      final rows = response['items'];
      if (rows is! List || rows.isEmpty)
        throw const FormatException('Сервер не вернул товары');
      items.addAll(
        rows.map(
          (r) =>
              LoadingInvoiceItem.fromJson(Map<String, dynamic>.from(r as Map)),
        ),
      );
      stated = (response['statedWeightKg'] as num?)?.toDouble();
      warnings.addAll((response['warnings'] as List? ?? []).map((w) => '$w'));
    }
    if (photoPaths.length > 1) {
      stated = null;
      warnings.add(
        'Несколько фото: проверьте повторы товаров и введите общий вес всей накладной.',
      );
    }
    return InvoiceRecognitionResult(
      items: items,
      statedWeightKg: stated,
      warnings: warnings,
    );
  }
}

String _encodeInvoicePhoto(List<int> bytes) => base64Encode(bytes);
