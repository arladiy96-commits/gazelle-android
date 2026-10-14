part of 'app_shell.dart';

class _EmployeeDetails extends StatefulWidget {
  final EmployeeAccount employee;
  const _EmployeeDetails({required this.employee});
  @override
  State<_EmployeeDetails> createState() => _EmployeeDetailsState();
}

class _EmployeeDetailsState extends State<_EmployeeDetails> {
  late EmployeeAccount employee = widget.employee;
  Map<String, dynamic>? snapshot;
  List<Map<String, dynamic>> events = [], points = [];
  String? error, selectedShift;
  bool busy = false;
  int request = 0, tab = 0;
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  Timer? timer;
  @override
  void initState() {
    super.initState();
    load();
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) load();
    });
  }

  @override
  void dispose() {
    request++;
    timer?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    final id = ++request;
    try {
      final accounts = await SessionService.employees();
      final data = await EmployeeDataService.read(employee.id);
      final audit = await SessionService.audit(employee.id);
      if (!mounted || id != request) return;
      setState(() {
        employee = accounts.firstWhere((e) => e.id == employee.id);
        snapshot = data;
        events = audit.reversed.toList();
        error = null;
        selectedShift ??= book.shifts.lastOrNull?['id'] as String?;
        if (!book.shifts.any((s) => s['id'] == selectedShift))
          selectedShift = null;
      });
      await loadPoints();
    } catch (e) {
      if (mounted && id == request) setState(() => error = '$e');
    }
  }

  Map<String, dynamic> get preferences =>
      Map<String, dynamic>.from(snapshot?['preferences'] as Map? ?? {});
  TestState get book {
    final state = TestState.decode(preferences['journal'] as String?);
    final live = snapshot?['liveShift'];
    if (live is Map) {
      final shift = Map<String, dynamic>.from(live);
      if (!state.shifts.any((s) => s['id'] == shift['id']))
        state.shifts.add(shift);
    }
    return state;
  }

  Future<void> loadPoints() async {
    final shift = selectedShift;
    if (shift == null) {
      if (mounted) setState(() => points = []);
      return;
    }
    try {
      final result = await EmployeeDataService.route(employee.id, shift);
      if (mounted && shift == selectedShift) setState(() => points = result);
    } catch (e) {
      if (mounted)
        setState(() {
          points = [];
          error = '$e';
        });
    }
  }

  String stamp(Object? value) {
    final d = DateTime.tryParse('$value')?.toLocal();
    return d == null
        ? 'Нет данных'
        : '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Widget line(String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(title, style: const TextStyle(color: Colors.white60)),
        ),
        const SizedBox(width: 12),
        Flexible(child: Text(value, textAlign: TextAlign.right)),
      ],
    ),
  );
  Widget panel(List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xF0141D23),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF65543D)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
  Widget overview() => panel([
    line('Доступ', employee.access.label),
    line('Роль', employee.role.title),
    line(
      'Смена',
      book.active == null
          ? 'Закрыта'
          : 'Открыта с ${stamp(book.active!['start'])}',
    ),
    line(
      'Последнее получение данных',
      EmployeeServerApi.enabled
          ? stamp(snapshot?['receivedAt'])
          : 'Местные данные этого телефона',
    ),
    if (book.active != null && employee.access.blocked)
      const Text(
        'Смена не завершена. Записи сохранены; автоматического закрытия нет.',
      ),
    line(
      'Геоданные во время смены',
      employee.access.shareLocation
          ? 'Передача разрешена'
          : 'Передача выключена',
    ),
    OutlinedButton.icon(
      onPressed: () async {
        await showDialog<void>(
          context: context,
          builder: (_) =>
              _EmployeeEditor(account: employee, initialRole: employee.role),
        );
        if (mounted) load();
      },
      icon: const Icon(Icons.edit_outlined),
      label: const Text('Имя, логин и оплата'),
    ),
  ]);
  Widget work() {
    final b = book, totals = book.statistics(month);
    final shifts =
        b.shifts.where((s) {
          final d = DateTime.parse(s['start'] as String);
          return d.year == month.year && d.month == month.month;
        }).toList()..sort(
          (a, b) => (b['start'] as String).compareTo(a['start'] as String),
        );
    return Column(
      children: [
        panel([
          Row(
            children: [
              IconButton(
                onPressed: () => setState(
                  () => month = DateTime(month.year, month.month - 1),
                ),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${_garageMonths[month.month - 1]} ${month.year}',
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: () => setState(
                  () => month = DateTime(month.year, month.month + 1),
                ),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          if (employee.role != AppRole.loader) ...[
            line(
              'Город / район',
              '${_fmt1(totals['city_kg'] ?? 0)} / ${_fmt1(totals['region_kg'] ?? 0)} кг',
            ),
            line('Пробег', '${_fmt1(totals['mileage'] ?? 0)} км'),
            line(
              'Газ / бензин',
              '${_fmt1(totals['gas'] ?? 0)} / ${_fmt1(totals['petrol'] ?? 0)} л',
            ),
            line('Зарплата', '${_fmt1(totals['salary'] ?? 0)} ₸'),
          ],
          if (employee.role == AppRole.loader)
            for (final row
                in (snapshot?['loaderShifts'] as List? ?? []).cast<Map>().where(
                  (r) => '${r['day']}'.startsWith(
                    '${month.year}-${month.month.toString().padLeft(2, '0')}',
                  ),
                ))
              line(
                '${row['day']}',
                '${row['minutes']} мин · ${_fmt1((row['minutes'] as num) * (row['rateMinor'] as num) / 6000)} ₸',
              ),
        ]),
        for (final shift in shifts)
          panel([
            Text(
              stamp(shift['start']),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            line(
              'Завершение',
              shift['end'] == null ? 'Открыта' : stamp(shift['end']),
            ),
            line(
              'Пробег / часы',
              '${_fmt1(b.mileage(shift))} км / ${_fmt1(b.hours(shift))} ч',
            ),
            for (final e in b.records.where((e) => e['shiftId'] == shift['id']))
              line(
                '${e['type'] ?? e['kind']} ${e['direction'] ?? ''}',
                '${e['amount'] ?? ''} ${e['kind'] == 'trip'
                    ? 'кг'
                    : e['kind'] == 'fuel'
                    ? 'л'
                    : ''}',
              ),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedShift = shift['id'] as String;
                  tab = 2;
                  points = [];
                });
                loadPoints();
              },
              child: const Text('Маршрут смены'),
            ),
          ]),
        if (shifts.isEmpty && employee.role != AppRole.loader)
          panel([const Text('Смен за этот месяц нет')]),
        reports(b),
        ...documents(b),
      ],
    );
  }

  Widget reports(TestState b) {
    final raw = preferences['gas_reports_v1'];
    final root = raw is String ? jsonDecode(raw) as Map : <String, dynamic>{};
    final report = GasReportRepository.derive(
      b,
      month,
      Map<String, dynamic>.from(root['months'] as Map? ?? {}),
    );
    return panel([
      const Text('Отчёт за газ', style: TextStyle(fontWeight: FontWeight.w600)),
      line('Получено', '${_fmt1(report.gas)} л'),
      line(
        'Входящий остаток',
        report.opening == null ? 'Не указан' : '${_fmt1(report.opening!)} л',
      ),
      line(
        'Расчётный остаток',
        report.closing == null ? 'Не рассчитан' : '${_fmt1(report.closing!)} л',
      ),
    ]);
  }

  List<Widget> documents(TestState b) {
    final out = <Widget>[];
    for (final entry in preferences.entries) {
      if (entry.value is! String) continue;
      try {
        if (entry.key.startsWith('advance_report_v1_')) {
          final ledger = AdvanceLedger.decode(entry.value as String);
          final current = ledger.current([
            for (final r in b.records)
              {...r, 'calculationSettings': b.settingsFor(r)},
          ]);
          out.add(
            panel([
              const Text('Текущий авансовый отчёт · все даты'),
              line(
                'Получено / расходы',
                '${_fmt1(current.received / 100)} / ${_fmt1(current.expenses / 100)} ₸',
              ),
              for (final row in current.rows)
                line(
                  '${stamp(row.date.toIso8601String())} · ${row.name}',
                  '${_fmt1(row.total / 100)} ₸',
                ),
              for (final report in ledger.history)
                ExpansionTile(
                  title: Text('Сданный отчёт №${report.number}'),
                  subtitle: Text(stamp(report.submittedAt?.toIso8601String())),
                  children: [
                    for (final row in report.rows)
                      line(row.name, '${_fmt1(row.total / 100)} ₸'),
                  ],
                ),
            ]),
          );
        } else if (entry.key.startsWith('maintenance_v1_')) {
          final saved = MaintenanceBook.fromJson(
            Map<String, dynamic>.from(jsonDecode(entry.value as String) as Map),
          );
          out.add(
            panel([
              const Text('ТО и документы'),
              for (final record in saved.entries.where(
                (e) => e.date.year == month.year && e.date.month == month.month,
              ))
                line(
                  '${stamp(record.date.toIso8601String())} · ${MaintenanceCatalog.byId(record.itemId).title}',
                  '${record.odometer} км · ${record.cost == null ? '—' : _fmt1(record.cost!)} ₸\n${record.note}',
                ),
            ]),
          );
        } else if (entry.key.startsWith('loading_invoices_v1_')) {
          final invoices = (jsonDecode(entry.value as String) as List).map(
            (r) => LoadingInvoice.fromJson(Map<String, dynamic>.from(r as Map)),
          );
          out.add(
            panel([
              const Text('Загрузка по накладным'),
              for (final invoice in invoices.where(
                (e) =>
                    e.createdAt.year == month.year &&
                    e.createdAt.month == month.month,
              ))
                ExpansionTile(
                  title: Text(stamp(invoice.createdAt.toIso8601String())),
                  subtitle: Text(
                    'Загружено ${invoice.loadedItems} / ${invoice.items.length} позиций',
                  ),
                  children: [
                    for (final item in invoice.items)
                      line(
                        '${item.isLoaded ? '✓ ' : ''}${item.name}',
                        '${item.bagsCount} меш. · ${_fmt1(item.totalWeightKg)} кг',
                      ),
                  ],
                ),
            ]),
          );
        } else if (entry.key.startsWith('melnitsa_money_v1_')) {
          final data = Map<String, dynamic>.from(
            jsonDecode(entry.value as String) as Map,
          );
          final counts = [
            if (data['draft'] is Map)
              MoneyCount.fromJson(
                Map<String, dynamic>.from(data['draft'] as Map),
              ),
            for (final row in data['history'] as List? ?? [])
              MoneyCount.fromJson(Map<String, dynamic>.from(row as Map)),
          ];
          out.add(
            panel([
              const Text('Деньги · подсчёты'),
              for (final count in counts.where(
                (c) => c.date.year == month.year && c.date.month == month.month,
              ))
                line(
                  stamp(count.date.toIso8601String()),
                  'Ожидается ${_fmt1(count.expected / 100)} ₸\nНаличные ${_fmt1(count.counted / 100)} ₸\nРазница ${_fmt1(count.difference / 100)} ₸',
                ),
            ]),
          );
        }
      } catch (_) {
        out.add(
          panel([
            const Text(
              'Один из документов не удалось прочитать. Обновите данные сотрудника.',
            ),
          ]),
        );
      }
    }
    return out;
  }

  Widget map() {
    final last = points.lastOrNull;
    final time = DateTime.tryParse('${last?['time']}');
    final age = time == null
        ? null
        : DateTime.now().toUtc().difference(time.toUtc());
    return panel([
      DropdownButtonFormField<String>(
        key: ValueKey(selectedShift),
        initialValue: selectedShift,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Смена'),
        items: [
          for (final s in book.shifts)
            DropdownMenuItem(
              value: s['id'] as String,
              child: Text(stamp(s['start'])),
            ),
        ],
        onChanged: (v) {
          setState(() {
            selectedShift = v;
            points = [];
          });
          loadPoints();
        },
      ),
      const SizedBox(height: 12),
      if (selectedShift != null)
        SizedBox(
          height: 300,
          child: ShiftRouteMap(
            key: ValueKey('${employee.id}:$selectedShift'),
            shiftId: selectedShift,
            routeLoader: (id) => EmployeeDataService.route(employee.id, id),
          ),
        ),
      line('Последняя точка', stamp(last?['time'])),
      if (last != null)
        line(
          'Точность',
          last['accuracy'] is num
              ? '±${_fmt1((last['accuracy'] as num).toDouble())} м'
              : 'Не указана',
        ),
      Text(
        age == null
            ? 'Геоданных нет'
            : age.isNegative || age.inSeconds > 120
            ? 'Точка устарела — текущее положение неизвестно.'
            : 'Точка получена ${age.inSeconds} с назад.',
      ),
      const SizedBox(height: 8),
      const Text(
        'На карте маршрут выбранной смены. Старая точка не означает, что машина сейчас здесь.',
        style: TextStyle(color: Colors.white60, fontSize: 12),
      ),
    ]);
  }

  Future<void> accessEditor() async {
    final result = await showDialog<EmployeeAccess>(
      context: context,
      builder: (_) => _EmployeeAccessEditor(employee: employee),
    );
    if (result == null || !mounted) return;
    await change(result);
  }

  Future<void> change(EmployeeAccess next, {bool revoke = false}) async {
    setState(() => busy = true);
    try {
      await SessionService.updateAccess(employee, next, revoke: revoke);
      await load();
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget access() => panel([
    line('Режим', employee.access.label),
    if (employee.access.reason.isNotEmpty) Text(employee.access.reason),
    if (employee.isOwner)
      const Text('Единственный владелец. Ограничение доступа недоступно.')
    else ...[
      OutlinedButton(
        onPressed: busy ? null : accessEditor,
        child: const Text('Разрешения и блокировка'),
      ),
      OutlinedButton(
        onPressed: busy
            ? null
            : () async {
                final yes = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Завершить все сеансы?'),
                    content: const Text(
                      'Сотрудник должен будет войти заново. Данные сохранятся.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Отмена'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Завершить'),
                      ),
                    ],
                  ),
                );
                if (yes == true && mounted)
                  change(employee.access, revoke: true);
              },
        child: const Text('Завершить все сеансы'),
      ),
    ],
    const Divider(),
    const Text('Журнал изменений'),
    if (events.isEmpty) const Text('Изменений пока нет'),
    for (final event in events)
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(switch (event['action']) {
          'revoke_sessions' => 'Завершены сеансы',
          'employee_created' => 'Создан сотрудник',
          'profile_changed' => 'Изменены данные сотрудника',
          _ => 'Изменены права',
        }),
        subtitle: Text(
          '${stamp(event['at'])}\nВладелец: ${event['actorId']}\n${(event['after'] as Map?)?['reason'] ?? ''}',
        ),
      ),
  ]);
  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: false,
    backgroundColor: const Color(0xFF0B131A),
    appBar: AppBar(
      title: Text(employee.name),
      actions: [
        IconButton(
          onPressed: busy ? null : load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: !AccountScope.isAdmin
        ? const Center(child: Text('Доступно владельцу'))
        : Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < 4; i++)
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: ChoiceChip(
                          label: Text(
                            const ['Обзор', 'Работа', 'Карта', 'Доступ'][i],
                          ),
                          selected: tab == i,
                          onSelected: (_) => setState(() => tab = i),
                        ),
                      ),
                  ],
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.orangeAccent),
                  ),
                ),
              Expanded(
                child: snapshot == null
                    ? const Center(child: Text('Загрузка данных…'))
                    : ListView(
                        padding: const EdgeInsets.all(14),
                        children: [
                          switch (tab) {
                            0 => overview(),
                            1 => work(),
                            2 => map(),
                            _ => access(),
                          },
                        ],
                      ),
              ),
            ],
          ),
  );
}

class _EmployeeAccessEditor extends StatefulWidget {
  final EmployeeAccount employee;
  const _EmployeeAccessEditor({required this.employee});
  @override
  State<_EmployeeAccessEditor> createState() => _EmployeeAccessEditorState();
}

class _EmployeeAccessEditorState extends State<_EmployeeAccessEditor> {
  late EmployeeAccessStatus status = widget.employee.access.status;
  late final readable = {...widget.employee.access.readable},
      writable = {...widget.employee.access.writable};
  late bool history = widget.employee.access.editHistory,
      submit = widget.employee.access.submitReports,
      geo = widget.employee.access.shareLocation;
  late final reason = TextEditingController(
    text: widget.employee.access.reason,
  );
  String? error;
  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _KeyboardAlertDialog(
    title: const Text('Доступ сотрудника'),
    content: SizedBox(
      width: 460,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<EmployeeAccessStatus>(
            initialValue: status,
            items: [
              for (final s in EmployeeAccessStatus.values)
                DropdownMenuItem(
                  value: s,
                  child: Text(EmployeeAccess(status: s).label),
                ),
            ],
            onChanged: (v) => setState(() => status = v!),
          ),
          KeyboardInput(
            controller: reason,
            maxLength: 240,
            decoration: InputDecoration(
              labelText: 'Причина / пояснение сотруднику',
              errorText: error,
            ),
          ),
          const Text(
            'Раздел · просмотр · изменение',
            style: TextStyle(color: Colors.white60),
          ),
          const Text(
            'Статистика содержит зарплату: без доступа к зарплате она тоже закрыта.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          for (final entry in EmployeeAccess.sections.entries)
            Row(
              children: [
                Expanded(child: Text(entry.value)),
                Checkbox(
                  value: readable.contains(entry.key),
                  onChanged: (v) => setState(() {
                    if (v!) {
                      readable.add(entry.key);
                    } else {
                      readable.remove(entry.key);
                      writable.remove(entry.key);
                    }
                  }),
                ),
                Checkbox(
                  value: writable.contains(entry.key),
                  onChanged: !readable.contains(entry.key)
                      ? null
                      : (v) => setState(() {
                          if (v!) {
                            writable.add(entry.key);
                          } else {
                            writable.remove(entry.key);
                          }
                        }),
                ),
              ],
            ),
          SwitchListTile(
            title: const Text('Исправлять прошлые смены'),
            value: history,
            onChanged: (v) => setState(() => history = v),
          ),
          SwitchListTile(
            title: const Text('Сдавать отчёты'),
            value: submit,
            onChanged: (v) => setState(() => submit = v),
          ),
          SwitchListTile(
            title: const Text('Передавать GPS во время смены'),
            subtitle: const Text('С разрешения Android на телефоне сотрудника'),
            value: geo,
            onChanged: (v) => setState(() => geo = v),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Отмена'),
      ),
      TextButton(
        onPressed: () {
          if ((status == EmployeeAccessStatus.blocked ||
                  status == EmployeeAccessStatus.archived) &&
              reason.text.trim().isEmpty) {
            setState(() => error = 'Укажите причину');
            return;
          }
          Navigator.pop(
            context,
            EmployeeAccess(
              status: status,
              readable: readable,
              writable: writable,
              editHistory: history,
              submitReports: submit,
              shareLocation: geo,
              reason: reason.text.trim(),
              revision: widget.employee.access.revision,
              sessionEpoch: widget.employee.access.sessionEpoch,
            ),
          );
        },
        child: const Text('Сохранить'),
      ),
    ],
  );
}

Widget _guardEmployeeSection(Widget child) {
  final section = switch (child) {
    _EmployeeDetails() || _EmployeesScreen() => 'employees',
    _GasReportScreen() || _GasCalculationScreen() => 'gas',
    _AdvanceReportScreen() => 'advance',
    _MaintenancePage() || _VehicleDocumentsPage() => 'maintenance',
    _DirectionsScreen() => 'directions',
    LoadingInvoiceScreen() => 'invoices',
    MoneyScreen() => 'money',
    _CalculationSettingsScreen() => 'settings',
    _SalaryDashboard() => 'salary',
    _LoaderDashboard() => 'loader',
    _MillStatistics() || _MillStatisticsRoute() => 'statistics',
    HomePage() ||
    WorkPage() ||
    LoaderShiftPage() ||
    LoaderHistoryPage() ||
    _MetricDetails() ||
    _GasDashboard() ||
    _DistrictDashboard() ||
    _MileageReference() => 'work',
    _ => null,
  };
  return section == null
      ? child
      : _EmployeeSectionGate(section: section, child: child);
}

class _EmployeeSectionGate extends StatelessWidget {
  final String section;
  final Widget child;
  const _EmployeeSectionGate({required this.section, required this.child});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<EmployeeAccess>(
    valueListenable: AccountScope.access,
    builder: (context, policy, _) =>
        (section == 'loader'
                ? AccountScope.canRead('work') && AccountScope.canRead('salary')
                : AccountScope.canRead(section)) &&
            (section != 'statistics' || AccountScope.canRead('salary'))
        ? child
        : Scaffold(
            backgroundColor: const Color(0xFF0B141B),
            appBar: AppBar(title: const Text('Доступ ограничен')),
            body: const Center(child: Text('Владелец отключил этот раздел')),
          ),
  );
}
