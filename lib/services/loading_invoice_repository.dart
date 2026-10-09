import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/loading_invoice.dart';
import 'test_store.dart';
import 'account_scope.dart';

class LoadingInvoiceRepository {
  final _scope = AccountScope.capture();
  Future<TestPreferences> _preferences() =>
      _scope.bind(TestPreferences.getInstance);
  final String owner;
  LoadingInvoiceRepository(this.owner);
  String get key =>
      'loading_invoices_v1_${base64Url.encode(utf8.encode(owner))}';
  static Future<void> _queue = Future<void>.value();
  static Future<void> flush() => _queue;
  Future<List<LoadingInvoice>> load() async {
    final raw = (await _preferences()).getString(key);
    if (raw == null) return [];
    return [
      for (final j in jsonDecode(raw) as List)
        LoadingInvoice.fromJson(Map<String, dynamic>.from(j as Map)),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> save(LoadingInvoice invoice) {
    final snapshot = invoice.copy();
    final task = _queue.then((_) async {
      final all = await load();
      all.removeWhere((i) => i.invoiceId == snapshot.invoiceId);
      all.add(snapshot);
      await (await _preferences()).setString(
        key,
        jsonEncode(all.map((i) => i.toJson()).toList()),
      );
    });
    _queue = task.then<void>((_) {}, onError: (Object e, StackTrace s) {});
    return task;
  }

  Future<String> keepPhoto(String source, String invoiceId) async {
    final root = await getApplicationDocumentsDirectory();
    final folder = Directory(
      '${root.path}/loading_invoices/${base64Url.encode(utf8.encode(owner))}/$invoiceId',
    );
    await folder.create(recursive: true);
    final path = '${folder.path}/${invoiceEntityId()}.jpg';
    await File(source).copy(path);
    return path;
  }

  Future<void> setPending(String? id) async {
    final p = await _preferences();
    if (id == null) {
      await p.remove('${key}_pending');
    } else {
      await p.setString('${key}_pending', id);
    }
  }

  Future<String?> pending() async =>
      (await _preferences()).getString('${key}_pending');
}
