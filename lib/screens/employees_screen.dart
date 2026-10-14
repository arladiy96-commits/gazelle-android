part of 'app_shell.dart';

Future<void> _openAccountMenu(BuildContext context, AppSession supplied) async {
  final session = SessionService.current ?? supplied;
  final shell = context.findAncestorStateOfType<_AppShellState>();
  final exit = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFF101920),
    showDragHandle: true,
    builder: (c) => SafeArea(
      maintainBottomViewPadding: true,
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
            const SizedBox(height: 12),
            Text(
              'Доступ: ${AccountScope.isOwner ? 'Владелец' : AccountScope.access.value.label}',
            ),
            if (EmployeeServerApi.enabled) ...[
              ValueListenableBuilder<String?>(
                valueListenable: EmployeeSync.instance.message,
                builder: (_, text, __) => Text(
                  text ?? 'Ожидание синхронизации',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: () => EmployeeSync.instance.tick(),
                child: const Text('Проверить связь и доступ'),
              ),
              Text(
                AccountScope.access.value.shareLocation
                    ? 'Маршрут смены передаётся владельцу'
                    : 'Передача маршрута выключена',
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ],
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(c, 'update'),
              icon: const Icon(Icons.system_update),
              label: const Text('Обновление приложения'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(c, 'logout'),
              icon: const Icon(Icons.logout),
              label: const Text('Выйти из учётной записи'),
            ),
          ],
        ),
      ),
    ),
  );
  if (!context.mounted) return;
  if (exit == 'logout') await shell?._logout();
  if (exit == 'update') await _showApplicationUpdate(context);
}

class _EmployeesScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  const _EmployeesScreen({this.onNavigate});
  @override
  State<_EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<_EmployeesScreen> {
  static const gold = Color(0xFFC7A568);
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
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        colors: [Color(0xFF263036), Color(0xFF0A1218)],
      ),
      border: Border.all(color: const Color(0xFF776547), width: 1),
      boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 8)],
    ),
    child: IconButton(
      tooltip: label,
      onPressed: action,
      icon: Icon(icon, color: gold, size: 23),
    ),
  );
  Widget _card(EmployeeAccount account) => LayoutBuilder(
    builder: (context, box) {
      final scale = box.maxWidth / 790;
      // A reusable crop of the empty reference frame; text and initials stay live.
      return SizedBox(
        height: math.max(
          88.0,
          80.0 * MediaQuery.textScalerOf(context).scale(1),
        ),
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
            const ColoredBox(color: Color(0x42071118)),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    _SceneRoute<void>(
                      builder: (_) => _EmployeeDetails(employee: account),
                    ),
                  );
                  if (mounted) _load();
                },
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
                              fontSize: 23 * math.min(1.0, scale * 2),
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
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
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
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Логин: ${account.login}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFC4CBD0),
                                fontSize: 11,
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
                              account.isOwner
                                  ? 'Владелец'
                                  : account.access.label,
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
        resizeToAvoidBottomInset: false,
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
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFF071219),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/scenes/employees_reference.png',
              fit: BoxFit.cover,
            ),
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x66061119),
                      Color(0x8A061119),
                      Color(0xA6061119),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              maintainBottomViewPadding: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
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
                              fontSize: 23,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _circle(Icons.refresh, _load, 'Обновить'),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xF00C151D),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF716046)),
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
                          size: 16,
                          color: _role == AppRole.admin
                              ? gold
                              : const Color(0xFFBAC3C9),
                        ),
                        label: Text(
                          'Администраторы · ${(_accounts ?? []).where((a) => a.role == AppRole.admin).length}',
                          style: TextStyle(
                            fontSize: 12,
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
                                    fontSize: 13,
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
                            Color(0xFF25251F),
                            Color(0xFF10191F),
                            Color(0xFF191F20),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF716046)),
                        boxShadow: const [
                          BoxShadow(color: Colors.black, blurRadius: 10),
                        ],
                      ),
                      child: TextButton.icon(
                        onPressed: _edit,
                        icon: const Icon(
                          Icons.person_add_alt_1,
                          color: gold,
                          size: 20,
                        ),
                        label: const Text(
                          'Добавить сотрудника',
                          style: TextStyle(
                            color: gold,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF343126), Color(0xFF1C2428)],
                  )
                : null,
            border: selected
                ? Border.all(color: const Color(0xFF716046))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                role == AppRole.driver
                    ? Icons.local_shipping_outlined
                    : Icons.inventory_2_outlined,
                color: selected ? gold : const Color(0xFF84929B),
                size: 19,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  '${role == AppRole.driver ? 'Водители' : 'Грузчики'}  $count',
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF84929B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
  final _telegramId = TextEditingController();
  final _password = TextEditingController(),
      _confirmation = TextEditingController();
  late AppRole _role = widget.account?.role ?? widget.initialRole;
  late bool _active = widget.account?.active ?? true;
  late final _rate = TextEditingController(
    text: ((widget.account?.hourlyRateMinor ?? 0) / 100).toStringAsFixed(2),
  );
  late DateTime _payMonth = DateTime(DateTime.now().year, DateTime.now().month);
  late final _deduction = TextEditingController(
    text:
        ((widget.account?.deductions[LoaderService.monthKey(_payMonth)] ?? 0) /
                100)
            .toStringAsFixed(2),
  );
  bool _busy = false, _hide = true;
  String? _error;
  bool get _self => widget.account?.id == SessionService.current?.accountId;
  @override
  void dispose() {
    for (final c in [
      _name,
      _login,
      _password,
      _confirmation,
      _telegramId,
      _rate,
      _deduction,
    ]) {
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
        telegramId: EmployeeServerApi.enabled && widget.account == null ? _telegramId.text : null,
        name: _name.text,
        login: _login.text,
        role: _role,
        password: widget.account != null && _password.text.isEmpty
            ? null
            : _password.text,
        active: _active,
        hourlyRateMinor: _role == AppRole.loader
            ? LoaderService.parseMoney(_rate.text)
            : null,
        deductionMonth: _role == AppRole.loader
            ? LoaderService.monthKey(_payMonth)
            : null,
        deductionMinor: _role == AppRole.loader
            ? LoaderService.parseMoney(_deduction.text)
            : null,
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

  void _changePayMonth(int delta) {
    final current = LoaderService.monthKey(_payMonth);
    try {
      if (LoaderService.parseMoney(_deduction.text) !=
          (widget.account?.deductions[current] ?? 0)) {
        setState(
          () => _error = 'Сначала сохраните удержание за выбранный месяц, затем откройте карточку снова.',
        );
        return;
      }
    } catch (e) {
      setState(() => _error = 'Проверьте сумму удержания');
      return;
    }
    setState(() {
      _payMonth = DateTime(_payMonth.year, _payMonth.month + delta);
      _deduction.text =
          ((widget.account?.deductions[LoaderService.monthKey(_payMonth)] ??
                      0) /
                  100)
              .toStringAsFixed(2);
    });
  }

  Widget field(
    TextEditingController controller,
    String label, {
    bool secret = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: KeyboardInput(
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
    child: _KeyboardAlertDialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      scrollable: true,
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
              if (EmployeeServerApi.enabled && widget.account == null)
                field(_telegramId, 'Telegram ID сотрудника'),
              if (EmployeeServerApi.enabled && widget.account != null)
                Text('Telegram ID: ${widget.account!.id}'),
              field(_name, 'Имя и фамилия'),
              field(_login, 'Логин'),
              DropdownButtonFormField<AppRole>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Роль'),
                items: [
                  for (final role in AppRole.values.where(
                    (r) =>
                        r != AppRole.admin || widget.account?.isOwner == true,
                  ))
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
              if (_role == AppRole.loader) ...[
                const Divider(),
                const Text(
                  'Оплата грузчика',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                field(_rate, 'Часовая ставка, ₸'),
                const Text(
                  'Новая ставка применяется к новым сменам. Ставка сохранённых смен остаётся прежней.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFAEBAC2)),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _busy ? null : () => _changePayMonth(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        'Удержание за ${_payMonth.month.toString().padLeft(2, '0')}.${_payMonth.year}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      onPressed: _busy ? null : () => _changePayMonth(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                field(_deduction, 'Сумма удержания за месяц, ₸'),
                const Text(
                  'Сохраните изменения перед переходом к другому месяцу.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFAEBAC2)),
                ),
              ],
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
