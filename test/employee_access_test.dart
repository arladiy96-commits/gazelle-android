import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gazelle_android/models/employee_access.dart';
import 'package:gazelle_android/models/app_role.dart';
import 'package:gazelle_android/services/account_scope.dart';
import 'package:gazelle_android/services/session_service.dart';
import 'package:gazelle_android/services/test_store.dart';

void main() {
  setUp(() {
    AccountScope.close();
    TestPreferences.resetCache();
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() {
    AccountScope.close();
    TestPreferences.resetCache();
  });
  test('admin role alone does not confer ownership', () {
    AccountScope.activate('second-admin', AppRole.admin);
    expect(AccountScope.isAdmin, false);
    expect(AccountScope.requireAdmin, throwsStateError);
  });
  test('owner retains administration, employee cannot escalate', () {
    AccountScope.activate('owner', AppRole.admin, owner: true);
    expect(AccountScope.isAdmin, true);
    final old = AccountScope.capture();
    AccountScope.activate('driver', AppRole.driver);
    expect(old.check, throwsStateError);
    expect(AccountScope.requireAdmin, throwsStateError);
  });
  test('read-only keeps view but forbids saving, history and submission', () {
    AccountScope.activate(
      'a',
      AppRole.driver,
      policy: const EmployeeAccess(status: EmployeeAccessStatus.readOnly),
    );
    expect(AccountScope.canRead('work'), true);
    expect(() => AccountScope.requireWrite('work'), throwsStateError);
    expect(AccountScope.requireHistory, throwsStateError);
    expect(() => AccountScope.requireSubmit('gas'), throwsStateError);
  });
  test(
    'blocked, archived, expired leases, and revoked sessions close access',
    () {
      for (final status in [
        EmployeeAccessStatus.blocked,
        EmployeeAccessStatus.archived,
      ]) {
        AccountScope.activate(
          'a',
          AppRole.driver,
          policy: EmployeeAccess(status: status),
        );
        expect(AccountScope.restricted, true);
        expect(AccountScope.canRead('work'), false);
      }
      AccountScope.activate(
        'a',
        AppRole.driver,
        policy: EmployeeAccess(
          validUntil: DateTime.now().toUtc().subtract(
            const Duration(seconds: 1),
          ),
        ),
      );
      expect(AccountScope.restricted, true);
      AccountScope.activate('a', AppRole.driver);
      AccountScope.revoked.value = true;
      expect(AccountScope.canWrite('work'), false);
    },
  );
  test('unknown server status fails closed and policy round-trips', () {
    final json = const EmployeeAccess(reason: 'Проверка').toJson();
    expect(EmployeeAccess.fromJson(json).toJson(), json);
    expect(
      () => EmployeeAccess.fromJson({...json, 'status': 'unknown'}),
      throwsFormatException,
    );
  });
  test(
    'queued write rechecks permissions and preserves existing journal',
    () async {
      AccountScope.activate('a', AppRole.driver);
      final prefs = await TestPreferences.getInstance();
      await prefs.setString(
        'journal',
        '{"version":1,"shifts":[],"records":[]}',
      );
      AccountScope.access.value = const EmployeeAccess(
        status: EmployeeAccessStatus.readOnly,
      );
      await expectLater(prefs.setString('journal', '{}'), throwsStateError);
      expect(prefs.getString('journal'), contains('records'));
    },
  );
  test('owner is pinned; second owner creation denied; audit survives policy change', () async {
    final owner = await SessionService.createFirstAdmin(
      name: 'Владелец',
      login: 'owner',
      password: 'test1234',
    );
    await expectLater(
      SessionService.saveEmployee(
        name: 'Второй',
        login: 'admin2',
        role: AppRole.admin,
        password: 'test1234',
      ),
      throwsArgumentError,
    );
    await SessionService.saveEmployee(
      name: 'Водитель',
      login: 'driver',
      role: AppRole.driver,
      password: 'test1234',
    );
    var employee = (await SessionService.employees()).firstWhere(
      (e) => e.role == AppRole.driver,
    );
    await SessionService.updateAccess(
      employee,
      const EmployeeAccess(
        status: EmployeeAccessStatus.blocked,
        reason: 'Проверка',
      ),
    );
    employee = (await SessionService.employees()).firstWhere(
      (e) => e.id == employee.id,
    );
    expect(employee.access.revision, 1);
    expect(employee.active, false);
    expect((await SessionService.audit(employee.id)).length, 2);
    final self = (await SessionService.employees()).firstWhere(
      (e) => e.id == owner.accountId,
    );
    await expectLater(
      SessionService.updateAccess(
        self,
        const EmployeeAccess(status: EmployeeAccessStatus.blocked),
      ),
      throwsStateError,
    );
    await expectLater(
      SessionService.signIn(login: 'driver', password: 'test1234'),
      throwsStateError,
    );
    await SessionService.clear();
  });
}
