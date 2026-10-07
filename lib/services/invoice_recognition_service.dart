import '../models/loading_invoice.dart';

class InvoiceRecognitionResult {
  final List<LoadingInvoiceItem> items;
  final double? statedWeightKg;
  final bool isMock;
  const InvoiceRecognitionResult({
    required this.items,
    this.statedWeightKg,
    this.isMock = false,
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
