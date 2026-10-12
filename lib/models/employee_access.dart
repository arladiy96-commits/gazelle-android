enum EmployeeAccessStatus { active, readOnly, blocked, archived }

class EmployeeAccess {
  static const sections = <String, String>{
    'work': 'Смены, рейсы и топливо',
    'statistics': 'Статистика',
    'salary': 'Зарплата',
    'gas': 'Отчёт и расчёт газа',
    'advance': 'Авансовый отчёт',
    'maintenance': 'ТО и обслуживание',
    'invoices': 'Накладные',
    'money': 'Деньги',
    'directions': 'Направления',
    'settings': 'Параметры расчёта',
  };
  final EmployeeAccessStatus status;
  final Set<String> readable, writable;
  final bool editHistory, submitReports, shareLocation;
  final String reason;
  final int revision, sessionEpoch;
  final DateTime? validUntil;
  const EmployeeAccess({
    this.status = EmployeeAccessStatus.active,
    this.readable = const {
      'work',
      'statistics',
      'salary',
      'gas',
      'advance',
      'maintenance',
      'invoices',
      'money',
      'directions',
      'settings',
    },
    this.writable = const {
      'work',
      'gas',
      'advance',
      'maintenance',
      'invoices',
      'money',
      'directions',
    },
    this.editHistory = false,
    this.submitReports = true,
    this.shareLocation = true,
    this.reason = '',
    this.revision = 0,
    this.sessionEpoch = 0,
    this.validUntil,
  });
  bool get blocked =>
      status == EmployeeAccessStatus.blocked ||
      status == EmployeeAccessStatus.archived;
  bool expiredAt(DateTime now) =>
      validUntil != null && !now.toUtc().isBefore(validUntil!);
  bool canRead(String section) => !blocked && readable.contains(section);
  bool canWrite(String section) =>
      status == EmployeeAccessStatus.active &&
      readable.contains(section) &&
      writable.contains(section);
  String get label => switch (status) {
    EmployeeAccessStatus.active => 'Активен',
    EmployeeAccessStatus.readOnly => 'Только просмотр',
    EmployeeAccessStatus.blocked => 'Заблокирован',
    EmployeeAccessStatus.archived => 'В архиве',
  };
  Map<String, dynamic> toJson() => {
    'status': status.name,
    'readable': readable.toList()..sort(),
    'writable': writable.toList()..sort(),
    'editHistory': editHistory,
    'submitReports': submitReports,
    'shareLocation': shareLocation,
    'reason': reason,
    'revision': revision,
    'sessionEpoch': sessionEpoch,
    'validUntil': validUntil?.toUtc().toIso8601String(),
  };
  factory EmployeeAccess.fromJson(Map<String, dynamic> json) {
    final status = EmployeeAccessStatus.values
        .where((s) => s.name == json['status'])
        .firstOrNull;
    if (status == null)
      throw const FormatException('Неизвестный статус доступа');
    Set<String> keys(String key) =>
        (json[key] as List).cast<String>().toSet()..retainAll(sections.keys);
    return EmployeeAccess(
      status: status,
      readable: keys('readable'),
      writable: keys('writable'),
      editHistory: json['editHistory'] == true,
      submitReports: json['submitReports'] == true,
      shareLocation: json['shareLocation'] == true,
      reason: json['reason'] as String? ?? '',
      revision: (json['revision'] as num).toInt(),
      sessionEpoch: (json['sessionEpoch'] as num).toInt(),
      validUntil: json['validUntil'] == null
          ? null
          : DateTime.parse(json['validUntil'] as String).toUtc(),
    );
  }
}
