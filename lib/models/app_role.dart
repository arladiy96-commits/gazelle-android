enum AppRole {
  admin,
  driver,
  loader;

  String get storageValue => name;

  String get title {
    switch (this) {
      case AppRole.admin:
        return 'Администратор';
      case AppRole.driver:
        return 'Водитель';
      case AppRole.loader:
        return 'Грузчик';
    }
  }

  static AppRole fromStorage(String? value) {
    return AppRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => AppRole.driver,
    );
  }

  static AppRole fromTestLogin(String login) {
    final value = login.trim().toLowerCase();

    if (value == 'admin' || value == 'админ') {
      return AppRole.admin;
    }

    if (value == 'loader' || value == 'грузчик') {
      return AppRole.loader;
    }

    return AppRole.driver;
  }
}
