import '../lib/models/employee_access.dart';

void main() {
  var checks = 0;
  void check(bool value, String message) {
    if (!value) throw StateError(message);
    checks++;
  }

  final active = const EmployeeAccess();
  check(active.canRead('work'), 'Default work readable');
  check(active.canWrite('work'), 'Default work writable');
  check(!active.canWrite('settings'), 'Settings opt-in');
  check(!active.canRead('employees'), 'No employee management for employees');
  for (final status in EmployeeAccessStatus.values) {
    final policy = EmployeeAccess(status: status, reason: 'Проверка');
    check(
      EmployeeAccess.fromJson(policy.toJson()).status == status,
      'Status round-trip',
    );
    check(
      policy.canWrite('work') == (status == EmployeeAccessStatus.active),
      'Write status',
    );
    check(
      policy.canRead('work') ==
          (status == EmployeeAccessStatus.active ||
              status == EmployeeAccessStatus.readOnly),
      'Read status',
    );
  }
  final expires = DateTime.utc(2026, 10, 12, 8);
  final lease = EmployeeAccess(
    validUntil: expires,
    sessionEpoch: 4,
    revision: 8,
  );
  check(
    !lease.expiredAt(expires.subtract(const Duration(milliseconds: 1))),
    'Before expiry',
  );
  check(lease.expiredAt(expires), 'Exact expiry is closed');
  check(
    lease.expiredAt(expires.add(const Duration(seconds: 1))),
    'Past expiry',
  );
  check(
    EmployeeAccess.fromJson(lease.toJson()).validUntil == expires,
    'Lease UTC round-trip',
  );
  check(
    EmployeeAccess.fromJson(lease.toJson()).sessionEpoch == 4,
    'Epoch stable',
  );
  check(
    EmployeeAccess.fromJson(lease.toJson()).revision == 8,
    'Revision stable',
  );
  check(
    !const EmployeeAccess(readable: {}, writable: {'work'}).canWrite('work'),
    'Write requires read',
  );
  final unknownKeys = EmployeeAccess.fromJson({
    ...active.toJson(),
    'readable': ['work', 'root'],
    'writable': ['root'],
  });
  check(
    !unknownKeys.canRead('root') && !unknownKeys.canWrite('root'),
    'Unknown permission cannot grant access',
  );
  var failed = false;
  try {
    EmployeeAccess.fromJson({...active.toJson(), 'status': 'future_status'});
  } on FormatException {
    failed = true;
  }
  check(failed, 'Unknown status fails closed');
  print('$checks employee access checks passed');
}
