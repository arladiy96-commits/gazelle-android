import 'dart:math';

String invoiceEntityId() =>
    '${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';

class LoadingInvoiceItem {
  final String itemId;
  String name;
  double unitWeightKg, totalWeightKg;
  int bagsCount;
  bool isLoaded;
  LoadingInvoiceItem({
    required this.itemId,
    required this.name,
    required this.unitWeightKg,
    required this.bagsCount,
    required this.totalWeightKg,
    this.isLoaded = false,
  });
  double get calculatedWeightKg => unitWeightKg * bagsCount;
  bool get valid =>
      name.trim().isNotEmpty &&
      unitWeightKg.isFinite &&
      unitWeightKg > 0 &&
      bagsCount > 0 &&
      totalWeightKg.isFinite &&
      totalWeightKg > 0;
  bool get mismatch =>
      !valid || (calculatedWeightKg - totalWeightKg).abs() > .001;
  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'name': name,
    'unitWeightKg': unitWeightKg,
    'bagsCount': bagsCount,
    'totalWeightKg': totalWeightKg,
    'isLoaded': isLoaded,
  };
  factory LoadingInvoiceItem.fromJson(Map<String, dynamic> j) =>
      LoadingInvoiceItem(
        itemId: j['itemId'] as String,
        name: j['name'] as String,
        unitWeightKg: (j['unitWeightKg'] as num).toDouble(),
        bagsCount: j['bagsCount'] as int,
        totalWeightKg: (j['totalWeightKg'] as num).toDouble(),
        isLoaded: j['isLoaded'] == true,
      );
}

class LoadingInvoice {
  final String invoiceId;
  final DateTime createdAt;
  List<String> photos;
  List<LoadingInvoiceItem> items;
  double? statedWeightKg;
  String stage; // photos, review, loading, completed
  bool mock;
  DateTime? completedAt;
  LoadingInvoice({
    required this.invoiceId,
    required this.createdAt,
    this.photos = const [],
    this.items = const [],
    this.statedWeightKg,
    this.stage = 'photos',
    this.mock = false,
    this.completedAt,
  });
  factory LoadingInvoice.empty() =>
      LoadingInvoice(invoiceId: invoiceEntityId(), createdAt: DateTime.now());
  int get bags => items.fold(0, (s, i) => s + i.bagsCount);
  double get weight => items.fold(0, (s, i) => s + i.calculatedWeightKg);
  double get recognizedWeight => items.fold(0, (s, i) => s + i.totalWeightKg);
  int get loadedItems => items.where((i) => i.isLoaded).length;
  int get loadedBags =>
      items.where((i) => i.isLoaded).fold(0, (s, i) => s + i.bagsCount);
  double get loadedWeight => items
      .where((i) => i.isLoaded)
      .fold(0, (s, i) => s + i.calculatedWeightKg);
  bool get totalMismatch =>
      statedWeightKg == null ||
      !statedWeightKg!.isFinite ||
      (weight - statedWeightKg!).abs() > .001 ||
      (recognizedWeight - statedWeightKg!).abs() > .001;
  bool get ready =>
      items.isNotEmpty && !totalMismatch && items.every((i) => !i.mismatch);
  Map<String, dynamic> toJson() => {
    'invoiceId': invoiceId,
    'createdAt': createdAt.toIso8601String(),
    'photos': photos,
    'items': items.map((i) => i.toJson()).toList(),
    'statedWeightKg': statedWeightKg,
    'stage': stage,
    'mock': mock,
    'completedAt': completedAt?.toIso8601String(),
  };
  factory LoadingInvoice.fromJson(Map<String, dynamic> j) => LoadingInvoice(
    invoiceId: j['invoiceId'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    photos: (j['photos'] as List).cast<String>(),
    items: [
      for (final i in j['items'] as List)
        LoadingInvoiceItem.fromJson(Map<String, dynamic>.from(i as Map)),
    ],
    statedWeightKg: (j['statedWeightKg'] as num?)?.toDouble(),
    stage: j['stage'] as String,
    mock: j['mock'] == true,
    completedAt: DateTime.tryParse(j['completedAt'] as String? ?? ''),
  );
  LoadingInvoice copy() => LoadingInvoice.fromJson(toJson());
}
