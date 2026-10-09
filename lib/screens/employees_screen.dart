part of 'app_shell.dart';

Future<void> _openAccountMenu(BuildContext context, AppSession supplied) async {
  final session = SessionService.current ?? supplied;
  final shell = context.findAncestorStateOfType<_AppShellState>();
  final exit = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: const Color(0xFF101920),
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              session.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${session.role.title} · ${session.login}',
              style: const TextStyle(color: Color(0xFFB4BDC3)),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(c, true),
              icon: const Icon(Icons.logout),
              label: const Text('Выйти из учётной записи'),
            ),
          ],
        ),
      ),
    ),
  );
  if (exit == true && context.mounted) await shell?._logout();
}

class _LoaderPendingScreen extends StatelessWidget {
  final AppSession session;
  const _LoaderPendingScreen({required this.session});
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
    child: Scaffold(
      backgroundColor: const Color(0xFF0A141B),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/scenes/employees_reference.png',
            fit: BoxFit.cover,
          ),
          const ColoredBox(color: Color(0x66040B10)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => _openAccountMenu(context, session),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF232C31),
                            foregroundColor: _amber,
                            child: Text(
                              session.displayName.characters.first
                                  .toUpperCase(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                                Text(
                                  session.role.title,
                                  style: const TextStyle(
                                    color: Color(0xFFBEC6CB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.expand_more, color: _amber),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: const Color(0xEA0D171F),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: _amber),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.construction, color: _amber, size: 52),
                            SizedBox(height: 20),
                            Text(
                              'На стадии разработки',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Раздел грузчика появится позже.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFBBC4CA),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmployeesScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  const _EmployeesScreen({this.onNavigate});
  @override
  State<_EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<_EmployeesScreen> {
  static const gold = Color(0xFFE1B366);
  List<EmployeeAccount>? _accounts;
  AppRole _role = AppRole.driver;
  String? _error;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    SessionService.revision.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _request++;
    SessionService.revision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    try {
      final rows = await SessionService.employees();
      if (mounted && request == _request)
        setState(() {
          _accounts = rows;
          _error = null;
        });
    } catch (_) {
      if (mounted && request == _request)
        setState(() => _error = 'Не удалось загрузить сотрудников');
    }
  }

  Future<void> _edit([EmployeeAccount? account]) async {
    if (!AccountScope.isAdmin) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _EmployeeEditor(account: account, initialRole: _role),
    );
    if (mounted) _load();
  }

  void _navigate(int index) {
    Navigator.pop(context);
    widget.onNavigate?.call(index);
  }

  Widget _circle(IconData icon, VoidCallback action, String label) => Container(
    width: 46,
    height: 46,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        colors: [Color(0xFF263036), Color(0xFF0A1218)],
      ),
      border: Border.all(color: gold, width: 1.2),
      boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 8)],
    ),
    child: IconButton(
      tooltip: label,
      onPressed: action,
      icon: Icon(icon, color: gold, size: 27),
    ),
  );
  Widget _card(EmployeeAccount account) => LayoutBuilder(
    builder: (context, box) {
      final scale = box.maxWidth / 790;
      // A reusable crop of the empty reference frame; text and initials stay live.
      return SizedBox(
        height: box.maxWidth * 210 / 881,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(
              child: LayoutBuilder(
                builder: (context, b) => Stack(
                  children: [
                    Positioned(
                      left: -31 * b.maxWidth / 881,
                      top: -490 * b.maxHeight / 210,
                      width: 941 * b.maxWidth / 881,
                      height: 1672 * b.maxHeight / 210,
                      child: Image.asset(
                        'assets/images/scenes/employees_panels.png',
                        fit: BoxFit.fill,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _edit(account),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20 * scale, 7, 12, 7),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 180 * scale,
                        child: Center(
                          child: Text(
                            account.name
                                .trim()
                                .split(RegExp(r'\s+'))
                                .take(2)
                                .map((n) => n.characters.first)
                                .join()
                                .toUpperCase(),
                            style: TextStyle(
                              color: gold,
                              fontSize: 28 * math.min(1.0, scale * 2),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 14 * scale),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(
                                  account.role == AppRole.loader
                                      ? Icons.inventory_2_outlined
                                      : account.role == AppRole.admin
                                      ? Icons.admin_panel_settings_outlined
                                      : Icons.local_shipping_outlined,
                                  color: gold,
                                  size: 17,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    account.role.title,
                                    style: const TextStyle(
                                      color: Color(0xFFADB7BE),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Логин: ${account.login}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFC4CBD0),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8 * scale),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: account.active
                                  ? const Color(0x99102722)
                                  : const Color(0x99262B30),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: account.active
                                    ? const Color(0xFF328B66)
                                    : const Color(0xFF73808A),
                              ),
                            ),
                            child: Text(
                              account.active ? 'Активен' : 'Отключён',
                              style: TextStyle(
                                fontSize: 10,
                                color: account.active
                                    ? const Color(0xFF71C899)
                                    : const Color(0xFFB6BFC5),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Изменить сотрудника',
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: () => _edit(account),
                            icon: const Icon(
                              Icons.more_vert,
                              color: gold,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
  @override
  Widget build(BuildContext context) {
    if (!AccountScope.isAdmin)
      return const Scaffold(
        body: Center(child: Text('Доступно только администратору')),
      );
    final rows = (_accounts ?? []).where((a) => a.role == _role).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF071219),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/scenes/employees_reference.png',
              fit: BoxFit.cover,
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 6),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _circle(
                          Icons.chevron_left,
                          () => Navigator.pop(context),
                          'Назад',
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Сотрудники',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 29,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _circle(Icons.refresh, _load, 'Обновить'),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xF00C151D),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: gold),
                      ),
                      child: Row(
                        children: [
                          for (final role in [AppRole.driver, AppRole.loader])
                            Expanded(child: _tab(role)),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => setState(() => _role = AppRole.admin),
                        icon: Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 18,
                          color: _role == AppRole.admin
                              ? gold
                              : const Color(0xFFBAC3C9),
                        ),
                        label: Text(
                          'Администраторы · ${(_accounts ?? []).where((a) => a.role == AppRole.admin).length}',
                          style: TextStyle(
                            color: _role == AppRole.admin
                                ? gold
                                : const Color(0xFFBAC3C9),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _error != null
                          ? Center(
                              child: TextButton(
                                onPressed: _load,
                                child: Text('$_error\nПовторить'),
                              ),
                            )
                          : _accounts == null
                          ? const Center(child: CircularProgressIndicator())
                          : rows.isEmpty
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xDE0B141C),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  'Сотрудников пока нет.\nНажмите «Добавить сотрудника».',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.only(bottom: 10),
                              itemCount: rows.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 9),
                              itemBuilder: (_, i) => _card(rows[i]),
                            ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF3B3020),
                            Color(0xFF10191F),
                            Color(0xFF29251D),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: gold),
                        boxShadow: const [
                          BoxShadow(color: Colors.black, blurRadius: 10),
                        ],
                      ),
                      child: TextButton.icon(
                        onPressed: _edit,
                        icon: const Icon(Icons.person_add_alt_1, color: gold),
                        label: const Text(
                          'Добавить сотрудника',
                          style: TextStyle(
                            color: gold,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 17),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _MillDock(index: 4, onChanged: _navigate),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(AppRole role) {
    final selected = _role == role;
    final count = (_accounts ?? []).where((a) => a.role == role).length;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _role = role),
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFFB28340), Color(0xFF493823)],
                  )
                : null,
            border: selected ? Border.all(color: gold) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                role == AppRole.driver
                    ? Icons.local_shipping_outlined
                    : Icons.inventory_2_outlined,
                color: selected ? gold : const Color(0xFF84929B),
                size: 24,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  '${role == AppRole.driver ? 'Водители' : 'Грузчики'}  $count',
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF84929B),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeeEditor extends StatefulWidget {
  final EmployeeAccount? account;
  final AppRole initialRole;
  const _EmployeeEditor({this.account, required this.initialRole});
  @override
  State<_EmployeeEditor> createState() => _EmployeeEditorState();
}

class _EmployeeEditorState extends State<_EmployeeEditor> {
  late final _name = TextEditingController(text: widget.account?.name ?? ''),
      _login = TextEditingController(text: widget.account?.login ?? '');
  final _password = TextEditingController(),
      _confirmation = TextEditingController();
  late AppRole _role = widget.account?.role ?? widget.initialRole;
  late bool _active = widget.account?.active ?? true;
  bool _busy = false, _hide = true;
  String? _error;
  bool get _self => widget.account?.id == SessionService.current?.accountId;
  @override
  void dispose() {
    for (final c in [_name, _login, _password, _confirmation]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    if (_password.text != _confirmation.text) {
      setState(() => _error = 'Пароли не совпадают');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await SessionService.saveEmployee(
        id: widget.account?.id,
        name: _name.text,
        login: _login.text,
        role: _role,
        password: widget.account != null && _password.text.isEmpty
            ? null
            : _password.text,
        active: _active,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        setState(() {
          _busy = false;
          _error = e is ArgumentError
              ? '${e.message}'
              : e is StateError
              ? '${e.message}'
              : 'Не удалось сохранить сотрудника';
        });
    }
  }

  Widget field(
    TextEditingController controller,
    String label, {
    bool secret = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: controller,
      enabled: !_busy,
      obscureText: secret && _hide,
      autocorrect: !secret && controller == _name,
      enableSuggestions: !secret && controller == _name,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: secret
            ? IconButton(
                onPressed: () => setState(() => _hide = !_hide),
                icon: Icon(
                  _hide
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              )
            : null,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      backgroundColor: const Color(0xFF101A21),
      title: Text(
        widget.account == null ? 'Новый сотрудник' : 'Учётная запись',
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(_name, 'Имя и фамилия'),
              field(_login, 'Логин'),
              DropdownButtonFormField<AppRole>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Роль'),
                items: [
                  for (final role in AppRole.values)
                    DropdownMenuItem(value: role, child: Text(role.title)),
                ],
                onChanged: _busy || _self
                    ? null
                    : (role) => setState(() => _role = role!),
              ),
              const SizedBox(height: 16),
              field(
                _password,
                widget.account == null
                    ? 'Пароль'
                    : 'Новый пароль (необязательно)',
                secret: true,
              ),
              field(_confirmation, 'Повторите пароль', secret: true),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Доступ включён'),
                value: _active,
                onChanged: _busy || _self
                    ? null
                    : (v) => setState(() => _active = v),
              ),
              if (widget.account != null)
                const Text(
                  'Пустое поле пароля сохраняет прежний пароль. Отключение доступа сохраняет рабочие данные.',
                  style: TextStyle(color: Color(0xFFAEBAC2), fontSize: 12),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFE6B66D)),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? 'Сохранение…' : 'Сохранить'),
        ),
      ],
    ),
  );
}
