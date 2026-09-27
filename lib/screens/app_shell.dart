import 'dart:math' as math;
import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/test_store.dart';

import '../models/app_role.dart';
import '../services/session_service.dart';
import '../services/maintenance_service.dart';
import '../services/activity_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

part 'garage_home.dart';
part 'work_dashboard.dart';
part 'maintenance_dashboard.dart';
part 'metric_details.dart';
part 'garage_sections.dart';
part 'test_mode.dart';
part 'cinematic.dart';

class AppShell extends StatefulWidget {
  final AppSession session;

  const AppShell({
    super.key,
    required this.session,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  List<_NavItem> get _items {
    if (widget.session.role == AppRole.loader) {
      return const [
        _NavItem(
          label: 'Смена',
          icon: Icons.schedule_outlined,
          activeIcon: Icons.schedule_rounded,
        ),
        _NavItem(
          label: 'История',
          icon: Icons.history_outlined,
          activeIcon: Icons.history_rounded,
        ),
      ];
    }

    return const [
      _NavItem(
        label: 'Главная',
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
      ),
      _NavItem(
        label: 'Работа',
        icon: Icons.local_shipping_outlined,
        activeIcon: Icons.local_shipping_rounded,
      ),
      _NavItem(
        label: 'Добавить',
        icon: Icons.add_rounded,
        activeIcon: Icons.add_rounded,
      ),
      _NavItem(
        label: 'Накладные',
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
      ),
      _NavItem(
        label: 'Ещё',
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
      ),
    ];
  }

  List<Widget> get _pages {
    if (widget.session.role == AppRole.loader) {
      return [
        LoaderShiftPage(session: widget.session),
        LoaderHistoryPage(session: widget.session),
      ];
    }

    return [
      HomePage(
        session: widget.session,
        onNavigate: (index) => setState(() => _index = index),
        onQuickAdd: _openQuickAdd,
      ),
      WorkPage(session: widget.session,
        onNavigate: (index) => setState(() => _index = index), onQuickAdd: _openQuickAdd),
      const SizedBox.shrink(),
      const _TestHub(page:'Накладные',embedded:true),
      StatisticsPage(session: widget.session),
    ];
  }

  void _openQuickAdd() {
    HapticFeedback.mediumImpact();
    _showQuickAddMenu(context, widget.session);
  }

  Future<void> _logout() async {
    HapticFeedback.mediumImpact();
    await SessionService.clear();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const LoginScreen(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final pages = _pages;

    if (_index >= pages.length) {
      _index = 0;
    }

    return Scaffold(
      body: Stack(
        children: [
          if (widget.session.role != AppRole.loader && _index == 0)
            Positioned.fill(child: Image.asset('assets/images/garage_approved.png', fit: BoxFit.fill))
          else if (widget.session.role != AppRole.loader && _index == 1)
            Positioned.fill(child: Image.asset('assets/images/work_approved.png', fit: BoxFit.fill))
          else
            const _AppBackground(),
          SafeArea(
            bottom: false,
            child: _SceneTabStage(
              index: _index,
              children: pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.session.role != AppRole.loader && _index <= 1
          ? null
          : _BottomNavigation(
        items: items,
        index: _index,
        onChanged: (value) {
          if (widget.session.role != AppRole.loader && value == 2) {
            _openQuickAdd();
            return;
          }
          if (widget.session.role != AppRole.loader && value == 4) {
            _openHomeMenu(context, widget.session);
            return;
          }
          HapticFeedback.selectionClick();
          setState(() => _index = value);
        },
        onLongPressLogo: _logout,
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}


class _BottomNavigation extends StatelessWidget {
  final List<_NavItem> items;
  final int index;
  final ValueChanged<int> onChanged;
  final VoidCallback onLongPressLogo;

  const _BottomNavigation({
    required this.items,
    required this.index,
    required this.onChanged,
    required this.onLongPressLogo,
  });

  @override
  Widget build(BuildContext context) {
    final hasAdd = items.length == 5 && items[2].label == 'Добавить';

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: CustomPaint(
          foregroundPainter: const _ChromeRailPainter(),
          child: Container(
            padding: EdgeInsets.only(
              left: 5,
              right: 5,
              top: 4,
              bottom: MediaQuery.paddingOf(context).bottom + 5,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xEC22262B),
                  Color(0xF50D0F12),
                  Color(0xFF030405),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xC9000000),
                  blurRadius: 30,
                  offset: Offset(0, -12),
                ),
              ],
            ),
            child: Row(
              children: List.generate(items.length, (i) {
                final item = items[i];
                final isAdd = hasAdd && i == 2;
                final active = !isAdd && i == index;

                if (isAdd) {
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(i),
                      child: SizedBox(
                        height: 69,
                        child: Center(
                          child: Transform.translate(
                            offset: const Offset(0, -8),
                            child: const _BottomAddOrb(),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(i),
                    onLongPress: i == 0 ? onLongPressLogo : null,
                    child: SizedBox(
                      height: 65,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (active)
                            Positioned(
                              bottom: 4,
                              child: Container(
                                width: 44,
                                height: 24,
                                decoration: const BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x7AFF7418),
                                      blurRadius: 19,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                active ? item.activeIcon : item.icon,
                                size: 20,
                                color: active
                                    ? AppColors.orangeSoft
                                    : const Color(0xFF858B94),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                style: TextStyle(
                                  color: active
                                      ? AppColors.orangeSoft
                                      : const Color(0xFF777D86),
                                  fontSize: 8.2,
                                  fontWeight:
                                      active ? FontWeight.w800 : FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: active ? 28 : 0,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: AppColors.orange,
                                  borderRadius: BorderRadius.circular(99),
                                  boxShadow: active
                                      ? const [
                                          BoxShadow(
                                            color: Color(0xCCFF7418),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}







class _ChromeRailPainter extends CustomPainter {
  const _ChromeRailPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, 4);

    final darkEdge = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x002B2F34),
          Color(0xFF6C7178),
          Color(0xFF202328),
          Color(0xFF6C7178),
          Color(0x002B2F34),
        ],
        stops: [0, .18, .50, .82, 1],
      ).createShader(rect);
    canvas.drawRect(rect, darkEdge);

    final orangeGlow = Paint()
      ..color = const Color(0x48FF7418)
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawLine(
      Offset(size.width * .41, 1.2),
      Offset(size.width * .59, 1.2),
      orangeGlow,
    );

    final orange = Paint()
      ..color = const Color(0xB8FF7418)
      ..strokeWidth = .8;
    canvas.drawLine(
      Offset(size.width * .44, 1.1),
      Offset(size.width * .56, 1.1),
      orange,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



class _BottomAddOrb extends StatelessWidget {
  const _BottomAddOrb();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: CustomPaint(
        painter: const _MiniChromeOrbPainter(),
        child: const Icon(
          Icons.add_rounded,
          color: AppColors.orangeSoft,
          size: 31,
        ),
      ),
    );
  }
}

class _MiniChromeOrbPainter extends CustomPainter {
  const _MiniChromeOrbPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    final glow = Paint()
      ..color = const Color(0x72FF7418)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11);
    canvas.drawCircle(c, r - 5, glow);

    final fillRect = Rect.fromCircle(center: c, radius: r - 5);
    final fill = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-.35, -.45),
        colors: [
          Color(0xFF5B6068),
          Color(0xFF25292E),
          Color(0xFF07080A),
        ],
        stops: [0, .46, 1],
      ).createShader(fillRect);
    canvas.drawCircle(c, r - 5, fill);

    final ringRect = Rect.fromCircle(center: c, radius: r - 7);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFF777C84),
          Color(0xFFFF7418),
          Color(0xFF1D2024),
          Color(0xFFFF9B49),
          Color(0xFFFFFFFF),
        ],
      ).createShader(ringRect);
    canvas.drawCircle(c, r - 7, ring);

    final hot = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFF7418)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawArc(ringRect, math.pi * .10, math.pi * .75, false, hot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



final ValueNotifier<int> _homeDataRevision = TestStore.revision;

class _HomeMonthData {
  final double gas;
  final double petrol;
  final double tonnage;
  final int trips;
  final double mileage;
  final double salary;
  final double city;
  final double region;
  final double todaySalary;

  const _HomeMonthData({
    required this.gas,
    required this.petrol,
    required this.tonnage,
    required this.trips,
    required this.mileage,
    required this.salary,
    this.city = 0,
    this.region = 0,
    this.todaySalary = 0,
  });

  static String _monthKey(String name, [DateTime? month]) {
    final d = month ?? DateTime.now();
    return 'home_${d.year}_${d.month}_$name';
  }

  static Future<_HomeMonthData> load([DateTime? month]) async {
    final now=DateTime.now();final d=month??now;
    final b=await TestStore.load();final journal=await ActivityRepository.load(d);
    final stats=b.statistics(d);
    return _HomeMonthData(gas:journal.total('gas'),petrol:journal.total('petrol'),tonnage:journal.total('tonnage'),trips:journal.total('trips').round(),
      mileage:stats['mileage']!,salary:stats['salary']!,
      city:journal.total('city_tonnage'),region:journal.total('region_tonnage'),todaySalary:b.statistics(now,day:now)['salary']!);
  }

  static Future<void> addFuel(String fuel,double litres) async {
    await ActivityRepository.add(kind:'fuel',type:fuel,amount:litres);

  }
  static Future<void> addTrip(double tonnage,{String type='Город',String direction=''}) async {
    await ActivityRepository.add(kind:'trip',type:type,amount:tonnage,direction:direction);

  }

}

String _fmt1(double value) {
  if ((value - value.round()).abs() < .001) return value.round().toString();
  return value.toStringAsFixed(1).replaceAll('.', ',');
}

String _fmtInt(double value) {
  final raw = value.round().toString();
  final out = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && (raw.length - i) % 3 == 0) out.write(' ');
    out.write(raw[i]);
  }
  return out.toString();
}

class HomePage extends StatefulWidget {
  final AppSession session;
  final ValueChanged<int> onNavigate;
  final VoidCallback onQuickAdd;
  const HomePage({super.key, required this.session, required this.onNavigate, required this.onQuickAdd});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late Future<_HomeMonthData> _data;
  @override
  void initState() {
    super.initState();
    _data = _HomeMonthData.load(_month);
    _homeDataRevision.addListener(_reload);
  }
  void _reload() {
    if (mounted) setState(() => _data = _HomeMonthData.load(_month));
  }
  void _selectMonth(DateTime month) {
    setState(() { _month = DateTime(month.year, month.month); _data = _HomeMonthData.load(_month); });
  }
  @override
  void dispose() { _homeDataRevision.removeListener(_reload); super.dispose(); }
  @override
  Widget build(BuildContext context) => FutureBuilder<_HomeMonthData>(
    future: _data,
    builder: (context, snap) {
      if(snap.hasError)return Center(child:_detailButton('Не удалось прочитать тестовые данные. Повторить',_reload));
      final data = snap.data ?? const _HomeMonthData(gas: 0, petrol: 0,tonnage: 0, trips: 0, mileage: 0, salary: 0);
      return LayoutBuilder(builder: (context, c) => _ReferenceHomeDashboard(
        session: widget.session, data: data, month: _month, onMonthChanged: _selectMonth,
        size: Size(c.maxWidth, c.maxHeight), onNavigate: widget.onNavigate, onQuickAdd: widget.onQuickAdd));
    });
}

class _HomeTopBar extends StatelessWidget {
  final AppSession session;

  const _HomeTopBar({
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          _RefHeaderButton(
            icon: Icons.menu_rounded,
            onTap: () => _openHomeMenu(context, session),
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Главная',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 20,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.45,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Доброе утро, водитель!',
                  style: TextStyle(
                    color: Color(0xFF9C9FA5),
                    fontSize: 9.2,
                    height: 1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _RefHeaderButton(
            icon: Icons.search_rounded,
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SearchPage(session: session),
                ),
              );
            },
          ),
          const SizedBox(width: 7),
          _RefHeaderButton(
            icon: Icons.notifications_none_rounded,
            showDot: true,
            onTap: () => _showFeatureStub(
              context,
              'Уведомления',
              'Здесь будут события смены, документы, ТО и системные предупреждения.',
            ),
          ),
        ],
      ),
    );
  }
}







class _HomeTruckHero extends StatelessWidget {
  final double height;
  final VoidCallback onTap;

  const _HomeTruckHero({
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _RefHomeTile(
      radius: 22,
      accent: AppColors.orange,
      onTap: onTap,
      child: SizedBox(
        height: height.clamp(142.0, 170.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/home_truck.jpg',
                fit: BoxFit.cover,
                alignment: const Alignment(.38, .24),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      Color(0x22000000),
                      Color(0x75000000),
                      Color(0xF207080A),
                    ],
                    stops: [0, .46, 1],
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0x32FFFFFF),
                      Color(0x08FFFFFF),
                      Color(0x00FFFFFF),
                    ],
                    stops: [0, .16, .43],
                  ),
                ),
              ),
              const Positioned(
                left: 14,
                top: 12,
                child: Text(
                  'Заработок за сентябрь',
                  style: TextStyle(
                    color: Color(0xFFC4C6CB),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Positioned(
                left: 14,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '312 105,8 ₸',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 28,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.9,
                      ),
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'из ',
                          style: TextStyle(
                            color: Color(0xFFA4A7AC),
                            fontSize: 9.5,
                          ),
                        ),
                        Text(
                          '354 000 ₸',
                          style: TextStyle(
                            color: AppColors.orangeSoft,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          color: Color(0xFF55E66B),
                          size: 13,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '+18 600 ₸ к прошлому месяцу',
                          style: TextStyle(
                            color: Color(0xFF55E66B),
                            fontSize: 8.7,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Positioned(
                right: 14,
                bottom: 14,
                child: _HomeSalaryRing(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}









class _HomeSalaryCard extends StatelessWidget {
  final double gap;
  final VoidCallback onPaidRoutesTap;

  const _HomeSalaryCard({
    required this.gap,
    required this.onPaidRoutesTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: _RefMetricTile(
            title: 'Рейсы',
            value: '29',
            note: 'сегодня',
            delta: '+12%',
            icon: Icons.local_shipping_outlined,
            accent: AppColors.orange,
          ),
        ),
        SizedBox(width: gap),
        const Expanded(
          child: _RefMetricTile(
            title: 'Пробег',
            value: '184 км',
            note: 'за месяц',
            delta: '+8%',
            icon: Icons.route_rounded,
            accent: AppColors.blue,
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _RefMetricTile(
            title: 'Направления',
            value: '2',
            note: 'сегодня',
            delta: '',
            icon: Icons.alt_route_rounded,
            accent: AppColors.amber,
            onTap: onPaidRoutesTap,
          ),
        ),
      ],
    );
  }
}









class _HomeSalaryRing extends StatelessWidget {
  const _HomeSalaryRing();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 91,
      height: 91,
      child: CustomPaint(
        painter: _HomeRingPainter(progress: .88),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '88%',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'план',
                style: TextStyle(
                  color: Color(0xFF9B9EA4),
                  fontSize: 7.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




class _HomeRingPainter extends CustomPainter {
  final double progress;

  const _HomeRingPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 9;
    final rect = Rect.fromCircle(center: c, radius: r);

    final shadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xD0000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, shadow);

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [
          Color(0xFF53575D),
          Color(0xFF1B1E22),
          Color(0xFF0A0B0D),
          Color(0xFF3A3E43),
          Color(0xFF53575D),
        ],
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, bg);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x60FF7418)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      glow,
    );

    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFF5A00),
          Color(0xFFFF8D22),
          Color(0xFFFFB54C),
          Color(0xFFFF5A00),
        ],
      ).createShader(rect);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      fg,
    );

    final white = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .75
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xB8FFFFFF);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 4.8),
      -math.pi * .42,
      math.pi * .28,
      false,
      white,
    );
  }

  @override
  bool shouldRepaint(covariant _HomeRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}






class _HomeMaintenanceCard extends StatelessWidget {
  const _HomeMaintenanceCard();

  @override
  Widget build(BuildContext context) {
    return _RefHomeTile(
      radius: 19,
      accent: AppColors.orange,
      child: const SizedBox(
        height: 63,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 11),
          child: Row(
            children: [
              _RefIconPlate(
                icon: Icons.build_outlined,
                accent: AppColors.orange,
                size: 43,
              ),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'БЛИЖАЙШЕЕ ТО',
                      style: TextStyle(
                        color: Color(0xFFA4A7AC),
                        fontSize: 7.7,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .65,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Через 5 406 км',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 16.5,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.orange,
                size: 23,
              ),
            ],
          ),
        ),
      ),
    );
  }
}







class _HomeTonnageCard extends StatelessWidget {
  const _HomeTonnageCard();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: _RefGaugeTile(
            title: 'Тоннаж',
            value: '99 882',
            unit: 'кг',
            progress: .72,
            icon: Icons.scale_outlined,
            leftCaption: 'Город 59%',
            rightCaption: 'Район 41%',
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _RefGaugeTile(
            title: 'Топливо',
            value: '1 545',
            unit: 'л газа',
            progress: .63,
            icon: Icons.local_gas_station_rounded,
            leftCaption: 'Газ 1 545 л',
            rightCaption: 'Бензин 20 л',
            onTap: () => _showGasSheet(context),
          ),
        ),
      ],
    );
  }
}







class _HomeDynamicsCard extends StatelessWidget {
  const _HomeDynamicsCard();

  @override
  Widget build(BuildContext context) {
    const values = [.28, .47, .40, .66, .52, .76, .44, .58, .68, .55, .77, .91];

    return _RefHomeTile(
      radius: 20,
      accent: AppColors.orange,
      child: SizedBox(
        height: 141,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(11, 10, 11, 8),
          child: Column(
            children: [
              const Row(
                children: [
                  Text(
                    'Динамика дохода',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Spacer(),
                  _RefSegment(text: 'Доход', active: true),
                  SizedBox(width: 5),
                  _RefSegment(text: 'Тоннаж', active: false),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(values.length, (i) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.8),
                        child: Container(
                          height: 80 * values[i],
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3.5),
                            ),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFFFC16A),
                                Color(0xFFFF7B19),
                                Color(0xFF9A3500),
                              ],
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x62FF7418),
                                blurRadius: 7,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 5),
              const Row(
                children: [
                  Text('1 нед', style: TextStyle(color: Color(0xFF777A80), fontSize: 6.8)),
                  Spacer(),
                  Text('2 нед', style: TextStyle(color: Color(0xFF777A80), fontSize: 6.8)),
                  Spacer(),
                  Text('3 нед', style: TextStyle(color: Color(0xFF777A80), fontSize: 6.8)),
                  Spacer(),
                  Text('4 нед', style: TextStyle(color: Color(0xFF777A80), fontSize: 6.8)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}







class _RefHomeTile extends StatelessWidget {
  final Widget child;
  final double radius;
  final Color accent;
  final VoidCallback? onTap;

  const _RefHomeTile({
    required this.child,
    required this.radius,
    this.accent = AppColors.orange,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget tile = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          const BoxShadow(
            color: Color(0xE5000000),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
          BoxShadow(
            color: accent.withValues(alpha: .14),
            blurRadius: 18,
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CustomPaint(
          painter: _RefHomeGlassPainter(radius: radius, accent: accent),
          foregroundPainter: _RefHomeFramePainter(radius: radius, accent: accent),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      tile = InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        child: tile,
      );
    }

    return tile;
  }
}


class _RefMetricTile extends StatelessWidget {
  final String title;
  final String value;
  final String note;
  final String delta;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  const _RefMetricTile({
    required this.title,
    required this.value,
    required this.note,
    required this.delta,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _RefHomeTile(
      radius: 18,
      accent: accent,
      onTap: onTap,
      child: SizedBox(
        height: 98,
        child: Stack(
          children: [
            Positioned(
              right: -8,
              top: -12,
              child: IgnorePointer(
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: .22),
                        blurRadius: 22,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 9, 9),
              child: Stack(
                children: [
                  Positioned(
                    right: 0,
                    top: 0,
                    child: _RefNeonIcon(
                      icon: icon,
                      color: accent,
                      size: 19,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFFB5B8BD),
                          fontSize: 8.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 19,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Text(
                            note,
                            style: const TextStyle(
                              color: Color(0xFF888C92),
                              fontSize: 7.2,
                            ),
                          ),
                          if (delta.isNotEmpty) ...[
                            const Spacer(),
                            const Icon(
                              Icons.arrow_upward_rounded,
                              size: 8,
                              color: Color(0xFF55E66B),
                            ),
                            const SizedBox(width: 1),
                            Text(
                              delta,
                              style: const TextStyle(
                                color: Color(0xFF55E66B),
                                fontSize: 7.1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}




class _RefGaugeTile extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final double progress;
  final IconData icon;
  final String leftCaption;
  final String rightCaption;
  final VoidCallback? onTap;

  const _RefGaugeTile({
    required this.title,
    required this.value,
    required this.unit,
    required this.progress,
    required this.icon,
    required this.leftCaption,
    required this.rightCaption,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _RefHomeTile(
      radius: 20,
      accent: AppColors.orange,
      onTap: onTap,
      child: SizedBox(
        height: 164,
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _RefGaugeGlassSwooshPainter(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFB4B7BC),
                          fontSize: 8.4,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .5,
                        ),
                      ),
                      const Spacer(),
                      _RefNeonIcon(
                        icon: icon,
                        color: AppColors.orange,
                        size: 17,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: 112,
                        height: 112,
                        child: CustomPaint(
                          painter: _RefGaugePainter(progress: progress),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  value,
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 18.5,
                                    height: 1,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -.45,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  unit,
                                  style: const TextStyle(
                                    color: Color(0xFF92969C),
                                    fontSize: 7.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          leftCaption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFA7AAB0),
                            fontSize: 7.0,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          rightCaption,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFA7AAB0),
                            fontSize: 7.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}




class _RefGaugeGlassSwooshPainter extends CustomPainter {
  const _RefGaugeGlassSwooshPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(size.width * .47, -8)
      ..cubicTo(
        size.width * .68,
        size.height * .02,
        size.width * .72,
        size.height * .19,
        size.width * .92,
        size.height * .23,
      )
      ..cubicTo(
        size.width * .78,
        size.height * .27,
        size.width * .72,
        size.height * .34,
        size.width * .66,
        size.height * .48,
      );

    final wide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x18FFFFFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawPath(p, wide);

    final thin = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .65
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [
          Color(0x00FFFFFF),
          Color(0xA8FFFFFF),
          Color(0x10FFFFFF),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(p, thin);

    final warm = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x2EFF7418)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawArc(
      Rect.fromLTWH(size.width * .72, 4, size.width * .40, size.height * .42),
      .35,
      1.35,
      false,
      warm,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RefGaugePainter extends CustomPainter {
  final double progress;

  const _RefGaugePainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 12;
    final rect = Rect.fromCircle(center: c, radius: r);
    const start = math.pi * .78;
    const sweep = math.pi * 1.45;

    final shadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xB8000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawArc(rect, start, sweep, false, shadow);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [
          Color(0xFF696E74),
          Color(0xFF24272C),
          Color(0xFF0D0F12),
          Color(0xFF3E4248),
          Color(0xFF696E74),
        ],
      ).createShader(rect);
    canvas.drawArc(rect, start, sweep, false, track);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x62FF7418)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawArc(rect, start, sweep * progress, false, glow);

    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.5
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFB650),
          Color(0xFFFF7B18),
          Color(0xFFFF5300),
        ],
      ).createShader(rect);
    canvas.drawArc(rect, start, sweep * progress, false, active);

    final highlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xB8FFFFFF);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 4.8),
      start + .10,
      sweep * .25,
      false,
      highlight,
    );
  }

  @override
  bool shouldRepaint(covariant _RefGaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}


class _RefHeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  const _RefHeaderButton({
    required this.icon,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: SizedBox(
        width: 43,
        height: 43,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: _RefHomeTile(
                radius: 15,
                accent: AppColors.orange,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-.55, -.55),
                      radius: 1.15,
                      colors: [
                        Colors.white.withValues(alpha: .055),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Icon(
                icon,
                color: AppColors.text,
                size: 22,
              ),
            ),
            if (showDot)
              const Positioned(
                right: -1,
                top: -1,
                child: SizedBox(
                  width: 8,
                  height: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xCCFF7418),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}



class _RefIconPlate extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final double size;

  const _RefIconPlate({
    required this.icon,
    required this.accent,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: _RefHomeTile(
        radius: 13,
        accent: accent,
        child: Center(
          child: _RefNeonIcon(
            icon: icon,
            color: accent,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _RefNeonIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _RefNeonIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      color: color,
      size: size,
      shadows: [
        Shadow(
          color: color.withValues(alpha: .95),
          blurRadius: 9,
        ),
        Shadow(
          color: color.withValues(alpha: .45),
          blurRadius: 18,
        ),
      ],
    );
  }
}

class _RefSegment extends StatelessWidget {
  final String text;
  final bool active;

  const _RefSegment({
    required this.text,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: active
            ? const LinearGradient(
                colors: [
                  Color(0xFF3C281A),
                  Color(0xFF160F0B),
                ],
              )
            : null,
        border: Border.all(
          color: active
              ? const Color(0xFF9A5C2B)
              : const Color(0xFF34373C),
          width: .7,
        ),
        boxShadow: active
            ? const [
                BoxShadow(
                  color: Color(0x36FF7418),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? AppColors.orangeSoft : const Color(0xFF7E8187),
          fontSize: 7,
          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }
}


class _RefHomeGlassPainter extends CustomPainter {
  final double radius;
  final Color accent;

  const _RefHomeGlassPainter({
    required this.radius,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    canvas.save();
    canvas.clipRRect(rr);

    // Deep black glass. Reference is not grey — it is almost black.
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF171A1E),
          Color(0xFF0C0E11),
          Color(0xFF050608),
          Color(0xFF020304),
        ],
        stops: [0, .28, .68, 1],
      ).createShader(rect);
    canvas.drawRRect(rr, base);

    // Very soft warm contamination from the illuminated edge.
    final warmTL = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-1.05, -.92),
        radius: .72,
        colors: [
          accent.withValues(alpha: .115),
          accent.withValues(alpha: .030),
          Colors.transparent,
        ],
        stops: const [0, .46, 1],
      ).createShader(rect);
    canvas.drawRRect(rr, warmTL);

    final warmBR = Paint()
      ..shader = RadialGradient(
        center: const Alignment(1.05, 1.05),
        radius: .72,
        colors: [
          accent.withValues(alpha: .085),
          accent.withValues(alpha: .018),
          Colors.transparent,
        ],
        stops: const [0, .48, 1],
      ).createShader(rect);
    canvas.drawRRect(rr, warmBR);

    // Main internal glass sweep.
    final sweep = Path()
      ..moveTo(-size.width * .20, size.height * .18)
      ..cubicTo(
        size.width * .12,
        size.height * .02,
        size.width * .46,
        size.height * .02,
        size.width * .84,
        -size.height * .05,
      )
      ..lineTo(size.width * .95, size.height * .09)
      ..cubicTo(
        size.width * .53,
        size.height * .17,
        size.width * .18,
        size.height * .16,
        -size.width * .08,
        size.height * .36,
      )
      ..close();

    final sweepPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x00FFFFFF),
          Color(0x20FFFFFF),
          Color(0x08FFFFFF),
          Color(0x00FFFFFF),
        ],
        stops: [0, .40, .64, 1],
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(sweep, sweepPaint);

    // Secondary curved reflection, gives the "moulded glass" look.
    final innerCurve = Path()
      ..moveTo(size.width * .58, -size.height * .03)
      ..cubicTo(
        size.width * .72,
        size.height * .10,
        size.width * .80,
        size.height * .26,
        size.width * .98,
        size.height * .30,
      );

    final curvePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.2, size.shortestSide * .018)
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x18FFFFFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawPath(innerCurve, curvePaint);

    // Real inner depth: dark lower/right bevel.
    final depthRect = rect.deflate(3.5);
    final depthRR = RRect.fromRectAndRadius(
      depthRect,
      Radius.circular(math.max(2, radius - 3.5)),
    );
    final depth = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.8
      ..color = const Color(0x7A000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRRect(depthRR, depth);

    // Subtle upper/left internal edge.
    final innerEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .55
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x5CFFFFFF),
          Color(0x12FFFFFF),
          Color(0x00000000),
          Color(0x38000000),
        ],
      ).createShader(depthRect);
    canvas.drawRRect(depthRR, innerEdge);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RefHomeGlassPainter oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.accent != accent;
  }
}




class _RefHomeFramePainter extends CustomPainter {
  final double radius;
  final Color accent;

  const _RefHomeFramePainter({
    required this.radius,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(.8, .8, size.width - 1.6, size.height - 1.6);
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // Dark chrome perimeter: mostly black/steel.
    final metal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .9
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF6F747A),
          Color(0xFF34383D),
          Color(0xFF15171A),
          Color(0xFF33373C),
          Color(0xFF111316),
        ],
        stops: [0, .18, .48, .74, 1],
      ).createShader(rect);
    canvas.drawRRect(rr, metal);

    // Inner dark bevel.
    final innerRect = rect.deflate(2.0);
    final innerRR = RRect.fromRectAndRadius(
      innerRect,
      Radius.circular(math.max(2, radius - 2)),
    );
    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .48
      ..color = const Color(0x4C969BA1);
    canvas.drawRRect(innerRR, inner);

    // Chrome appears only in short reflected sections.
    final chromeGlow = Paint()
      ..color = const Color(0x44FFFFFF)
      ..strokeWidth = 3.3
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5);
    final chromeCore = Paint()
      ..color = const Color(0xB8F4F5F6)
      ..strokeWidth = .62
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(radius * .72, 1.25),
      Offset(size.width * .34, 1.25),
      chromeGlow,
    );
    canvas.drawLine(
      Offset(radius * .72, 1.20),
      Offset(size.width * .34, 1.20),
      chromeCore,
    );

    canvas.drawLine(
      Offset(size.width - 1.25, radius * .80),
      Offset(size.width - 1.25, size.height * .22),
      chromeGlow,
    );
    canvas.drawLine(
      Offset(size.width - 1.20, radius * .80),
      Offset(size.width - 1.20, size.height * .22),
      chromeCore,
    );

    // Orange "burns": local and asymmetrical, like the reference.
    final hotGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.8
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: .58)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);

    final hotCore = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.10
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(accent, Colors.white, .08)!;

    final tl = Rect.fromLTWH(-6, -6, radius * 2.12, radius * 2.12);
    canvas.drawArc(tl, math.pi * .94, math.pi * .50, false, hotGlow);
    canvas.drawArc(tl, math.pi * .94, math.pi * .50, false, hotCore);

    final br = Rect.fromLTWH(
      size.width - radius * 2.02,
      size.height - radius * 2.02,
      radius * 2.14,
      radius * 2.14,
    );
    canvas.drawArc(br, -math.pi * .08, math.pi * .53, false, hotGlow);
    canvas.drawArc(br, -math.pi * .08, math.pi * .53, false, hotCore);

    // Side glow segments, not full lit borders.
    final sideGlow = Paint()
      ..color = accent.withValues(alpha: .43)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

    canvas.drawLine(
      Offset(1.15, size.height * .30),
      Offset(1.15, size.height * .44),
      sideGlow,
    );
    canvas.drawLine(
      Offset(size.width - 1.15, size.height * .66),
      Offset(size.width - 1.15, size.height * .76),
      sideGlow,
    );
  }

  @override
  bool shouldRepaint(covariant _RefHomeFramePainter oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.accent != accent;
  }
}




BoxDecoration _homePanelDecoration({
  required double radius,
  Color borderColor = AppColors.line,
}) {
  return BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF3B4047),
        Color(0xFF202329),
        Color(0xFF0A0C0F),
        Color(0xFF030405),
      ],
      stops: [0, .15, .59, 1],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor.withValues(alpha: .96), width: .78),
    boxShadow: const [
      BoxShadow(
        color: Color(0xB8000000),
        blurRadius: 22,
        offset: Offset(0, 12),
      ),
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 22,
        spreadRadius: -3,
      ),
      BoxShadow(
        color: Color(0x2AFFFFFF),
        blurRadius: 1,
        offset: Offset(-1, -1),
      ),
    ],
  );
}

Future<void> _openHomeMenu(BuildContext context,AppSession session) async {
  await Navigator.push(context,_SceneRoute<void>(builder:(_)=>_CinematicMore(session:session)));
}


void _showSalarySheet(BuildContext context) {
  const rows = [
    ('Основной оклад', '166 250 ₸'),
    ('Выходные', '0 ₸'),
    ('Праздники', '0 ₸'),
    ('Платные рейсы', '9 000 ₸'),
    ('Городской вес', '58 800 ₸'),
    ('Районный вес', '78 055,8 ₸'),
  ];

  _showHomeSheet(
    context,
    title: 'Зарплата',
    icon: Icons.route_outlined,
    maxHeightFactor: 0.66,
    child: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _homePanelDecoration(
            radius: 20,
            borderColor: const Color(0xFF4A3425),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '312 105,8 ₸',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Итого за сентябрь 2026 г.',
                style: TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _HomeSheetHeader(
          columns: ['СОСТАВЛЯЮЩАЯ', 'СУММА'],
          flexes: [3, 2],
        ),
        ...rows.map(
          (row) => _HomeSheetRow(
            cells: [row.$1, row.$2],
            flexes: const [3, 2],
          ),
        ),
        const SizedBox(height: 8),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Часы: 154 / 176 ч',
            style: TextStyle(
              color: AppColors.textSoft,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );
}

void _showGasSheet(BuildContext context) {
  const rows = [
    ['09-15', '06:52', '500 л'],
    ['09-09', '07:02', '400 л'],
    ['09-01', '11:52', '500 л'],
    ['09-01', '04:07', '145 л'],
  ];

  _showHomeSheet(
    context,
    title: 'Газ',
    icon: Icons.local_gas_station_outlined,
    maxHeightFactor: 0.42,
    child: Column(
      children: [
        const _HomeSheetHeader(
          columns: ['ДАТА', 'ВРЕМЯ', 'ЛИТРЫ'],
          flexes: [2, 2, 2],
        ),
        ...rows.map(
          (row) => _HomeSheetRow(
            cells: row,
            flexes: const [2, 2, 2],
          ),
        ),
      ],
    ),
  );
}

void _showPaidRoutesSheet(BuildContext context) {
  const rows = [
    ['09-11', 'Щучинск', 'район', '4 000 кг'],
    ['09-04', 'Новоишимское', 'район', '3 500 кг'],
    ['09-02', 'Щучинск', 'район', '4 000 кг'],
  ];

  _showHomeSheet(
    context,
    title: 'Платные направления',
    icon: Icons.route_outlined,
    maxHeightFactor: 0.38,
    child: Column(
      children: [
        const _HomeSheetHeader(
          columns: ['ДАТА', 'КУДА', 'ТИП', 'ВЕС'],
          flexes: [2, 3, 2, 2],
        ),
        ...rows.map(
          (row) => _HomeSheetRow(
            cells: row,
            flexes: const [2, 3, 2, 2],
          ),
        ),
      ],
    ),
  );
}

Future<void> _showHomeSheet(
  BuildContext context, {
  required String title,
  required IconData icon,
  required Widget child,
  required double maxHeightFactor,
}) async {
  HapticFeedback.mediumImpact();

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Закрыть',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      final height = MediaQuery.sizeOf(dialogContext).height;

      return Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 7,
                    sigmaY: 7,
                  ),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.66),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: height * maxHeightFactor,
                  ),
                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111214),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(31),
                    ),
                    border: Border.all(
                      color: const Color(0xFF7A421C),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 34,
                        offset: Offset(0, -10),
                      ),
                      BoxShadow(
                        color: Color(0x22FF7418),
                        blurRadius: 32,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFF17120E),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF693A18),
                              ),
                            ),
                            child: Icon(
                              icon,
                              color: AppColors.orange,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF171719),
                              side: const BorderSide(
                                color: Color(0xFF4B3525),
                              ),
                            ),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textSoft,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(
                        height: 1,
                        color: Color(0xFF3D281A),
                      ),
                      const SizedBox(height: 10),
                      Flexible(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: child,
                        ),
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
    transitionBuilder: (
      context,
      animation,
      secondaryAnimation,
      child,
    ) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.12),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}


class _NeonIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _NeonIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          icon,
          color: color.withValues(alpha: .42),
          size: size + 7,
          shadows: [
            Shadow(
              color: color.withValues(alpha: .7),
              blurRadius: 12,
            ),
          ],
        ),
        Icon(icon, color: color, size: size),
      ],
    );
  }
}


class _ChromeGlassSurface extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color accent;
  final VoidCallback? onTap;

  const _ChromeGlassSurface({
    required this.child,
    required this.radius,
    required this.padding,
    this.accent = AppColors.orange,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget result = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          const BoxShadow(
            color: Color(0xE0000000),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
          BoxShadow(
            color: accent.withValues(alpha: .16),
            blurRadius: 24,
            spreadRadius: -7,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: CustomPaint(
            painter: _LuxuryGlassFillPainter(
              radius: radius,
              accent: accent,
            ),
            foregroundPainter: _LuxuryChromeFramePainter(
              radius: radius,
              accent: accent,
            ),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      result = InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        child: result,
      );
    }

    return result;
  }
}






class _LuxuryGlassFillPainter extends CustomPainter {
  final double radius;
  final Color accent;

  const _LuxuryGlassFillPainter({
    required this.radius,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(
      rect,
      Radius.circular(radius),
    );

    canvas.save();
    canvas.clipRRect(rr);

    // Глубокое черное стекло. Серого здесь специально мало.
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF24272C),
          Color(0xFF111317),
          Color(0xFF060709),
          Color(0xFF020304),
        ],
        stops: [0, .20, .60, 1],
      ).createShader(rect);
    canvas.drawRRect(rr, base);

    // Мягкий теплый свет в левом верхнем углу.
    final warmTop = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-1.05, -.96),
        radius: .86,
        colors: [
          accent.withValues(alpha: .18),
          accent.withValues(alpha: .055),
          Colors.transparent,
        ],
        stops: const [0, .42, 1],
      ).createShader(rect);
    canvas.drawRRect(rr, warmTop);

    // Второй теплый рефлекс снизу справа.
    final warmBottom = Paint()
      ..shader = RadialGradient(
        center: const Alignment(1.04, 1.06),
        radius: .72,
        colors: [
          accent.withValues(alpha: .15),
          accent.withValues(alpha: .025),
          Colors.transparent,
        ],
        stops: const [0, .48, 1],
      ).createShader(rect);
    canvas.drawRRect(rr, warmBottom);

    // Широкий холодный стеклянный блик по диагонали.
    final glossPath = Path()
      ..moveTo(-size.width * .16, size.height * .17)
      ..lineTo(size.width * .54, -size.height * .04)
      ..lineTo(size.width * .78, size.height * .09)
      ..lineTo(size.width * .03, size.height * .34)
      ..close();

    final gloss = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x00FFFFFF),
          Color(0x18FFFFFF),
          Color(0x08FFFFFF),
          Color(0x00FFFFFF),
        ],
        stops: [0, .36, .64, 1],
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(glossPath, gloss);

    // Узкий отражающий "штрих", как на полированном черном хроме.
    final streak = Paint()
      ..color = const Color(0x20FFFFFF)
      ..strokeWidth = math.max(2.0, size.shortestSide * .016)
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawLine(
      Offset(size.width * .12, size.height * .07),
      Offset(size.width * .59, size.height * .01),
      streak,
    );

    // Боковые прожиги. Они специально локальные, а не рамка по кругу.
    final sideGlow = Paint()
      ..color = accent.withValues(alpha: .47)
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);

    canvas.drawLine(
      Offset(2.2, size.height * .24),
      Offset(2.2, size.height * .58),
      sideGlow,
    );
    canvas.drawLine(
      Offset(size.width - 2.2, size.height * .58),
      Offset(size.width - 2.2, size.height * .79),
      sideGlow,
    );

    // Тонкие горячие сердцевины боковых прожигов.
    final sideCore = Paint()
      ..color = Color.lerp(accent, Colors.white, .13)!
      ..strokeWidth = 1.05
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(1.7, size.height * .29),
      Offset(1.7, size.height * .53),
      sideCore,
    );
    canvas.drawLine(
      Offset(size.width - 1.7, size.height * .62),
      Offset(size.width - 1.7, size.height * .75),
      sideCore,
    );

    // Внутренняя глубина: темный нижний/правый кант.
    final innerDarkRect = rect.deflate(4.0);
    final innerDark = RRect.fromRectAndRadius(
      innerDarkRect,
      Radius.circular(math.max(2, radius - 4)),
    );
    final depth = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..color = const Color(0x74000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRRect(innerDark, depth);

    // Микро-блик внутри по верхней грани.
    final innerLightRect = rect.deflate(3.0);
    final innerLight = RRect.fromRectAndRadius(
      innerLightRect,
      Radius.circular(math.max(2, radius - 3)),
    );
    final bevel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .65
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x4FFFFFFF),
          Color(0x0FFFFFFF),
          Color(0x00000000),
          Color(0x52000000),
        ],
      ).createShader(rect);
    canvas.drawRRect(innerLight, bevel);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LuxuryGlassFillPainter oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.accent != accent;
  }
}


class _LuxuryChromeFramePainter extends CustomPainter {
  final double radius;
  final Color accent;

  const _LuxuryChromeFramePainter({
    required this.radius,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(.8, .8, size.width - 1.6, size.height - 1.6);
    final rr = RRect.fromRectAndRadius(
      rect,
      Radius.circular(radius),
    );

    // Основная кромка почти черная — как в референсе.
    final darkMetal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF92979E),
          Color(0xFF33373D),
          Color(0xFF111317),
          Color(0xFF5A5F66),
          Color(0xFF17191D),
        ],
        stops: [0, .17, .47, .72, 1],
      ).createShader(rect);
    canvas.drawRRect(rr, darkMetal);

    // Вторая очень тонкая внутренняя металлическая линия.
    final innerRect = rect.deflate(2.25);
    final inner = RRect.fromRectAndRadius(
      innerRect,
      Radius.circular(math.max(2, radius - 2.2)),
    );
    final innerMetal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .62
      ..color = const Color(0x5ECDD0D5);
    canvas.drawRRect(inner, innerMetal);

    // Полированный хром — только короткими участками, не по всей рамке.
    final silverGlow = Paint()
      ..color = const Color(0x5CFFFFFF)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final silverCore = Paint()
      ..color = const Color(0xB8F3F5F7)
      ..strokeWidth = .72
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(radius * .76, 1.45),
      Offset(size.width * .40, 1.45),
      silverGlow,
    );
    canvas.drawLine(
      Offset(radius * .76, 1.35),
      Offset(size.width * .40, 1.35),
      silverCore,
    );

    canvas.drawLine(
      Offset(size.width - 1.45, radius * .82),
      Offset(size.width - 1.45, size.height * .26),
      silverGlow,
    );
    canvas.drawLine(
      Offset(size.width - 1.35, radius * .82),
      Offset(size.width - 1.35, size.height * .26),
      silverCore,
    );

    // Оранжевые прожиги по двум диагонально противоположным углам.
    final hotGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: .72)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final hotCore = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.45
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(accent, Colors.white, .11)!;

    canvas.drawArc(
      Rect.fromLTWH(-7, -7, radius * 2.25, radius * 2.25),
      math.pi * .94,
      math.pi * .53,
      false,
      hotGlow,
    );
    canvas.drawArc(
      Rect.fromLTWH(-7, -7, radius * 2.25, radius * 2.25),
      math.pi * .94,
      math.pi * .53,
      false,
      hotCore,
    );

    canvas.drawArc(
      Rect.fromLTWH(
        size.width - radius * 2.10,
        size.height - radius * 2.10,
        radius * 2.26,
        radius * 2.26,
      ),
      -math.pi * .08,
      math.pi * .58,
      false,
      hotGlow,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width - radius * 2.10,
        size.height - radius * 2.10,
        radius * 2.26,
        radius * 2.26,
      ),
      -math.pi * .08,
      math.pi * .58,
      false,
      hotCore,
    );

    // Дополнительные горячие точки по бокам.
    final sideGlow = Paint()
      ..color = accent.withValues(alpha: .62)
      ..strokeWidth = 3.8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawLine(
      Offset(1.35, size.height * .33),
      Offset(1.35, size.height * .47),
      sideGlow,
    );
    canvas.drawLine(
      Offset(size.width - 1.35, size.height * .66),
      Offset(size.width - 1.35, size.height * .78),
      sideGlow,
    );
  }

  @override
  bool shouldRepaint(covariant _LuxuryChromeFramePainter oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.accent != accent;
  }
}




class _HomeSheetHeader extends StatelessWidget {
  final List<String> columns;
  final List<int> flexes;

  const _HomeSheetHeader({
    required this.columns,
    required this.flexes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF3B281B),
          ),
        ),
      ),
      child: Row(
        children: List.generate(columns.length, (index) {
          return Expanded(
            flex: flexes[index],
            child: Text(
              columns[index],
              style: const TextStyle(
                color: AppColors.textSoft,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _HomeSheetRow extends StatelessWidget {
  final List<String> cells;
  final List<int> flexes;

  const _HomeSheetRow({
    required this.cells,
    required this.flexes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 13,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF332217),
          ),
        ),
      ),
      child: Row(
        children: List.generate(cells.length, (index) {
          return Expanded(
            flex: flexes[index],
            child: Text(
              cells[index],
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                height: 1.2,
              ),
            ),
          );
        }),
      ),
    );
  }
}


Future<void> _showQuickAddMenu(BuildContext context,AppSession session) async {
  final choice=await Navigator.of(context).push<String>(_SceneRoute<String>(builder:(c)=>_QuickAddMenu(
    onTrip:()=>Navigator.pop(c,'trip'),onFuel:()=>Navigator.pop(c,'fuel'),onInvoice:()=>Navigator.pop(c,'invoice'))));
  if(choice!=null&&context.mounted)await _testEditor(context,choice);
}

class _QuickAddMenu extends StatelessWidget {
  final VoidCallback onTrip,onFuel,onInvoice;
  const _QuickAddMenu({required this.onTrip,required this.onFuel,required this.onInvoice});
  @override
  Widget build(BuildContext context)=>Material(color:const Color(0xFF030B10),child:Stack(children:[
    Positioned.fill(child:_SceneBackdrop(dim:false)),
    const Positioned.fill(child:ColoredBox(color:Color(0x5900070D))),
    SafeArea(child:LayoutBuilder(builder:(context,box)=>SingleChildScrollView(child:ConstrainedBox(
      constraints:BoxConstraints(minHeight:box.maxHeight),child:Padding(padding:const EdgeInsets.fromLTRB(20,8,20,24),child:Column(children:[
        Row(children:[IconButton(tooltip:'Закрыть',onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.close,color:_paper)),
          Expanded(child:_dt('Новое действие',size:18,weight:FontWeight.w500))]),
        const SizedBox(height:20),_dt('Добавить',size:18,weight:FontWeight.w500),const SizedBox(height:6),
        _dt('Выберите действие',size:13,color:const Color(0xFFADC0CC)),const SizedBox(height:18),
        _QuickActionOrb(icon:Icons.local_shipping_outlined,title:'Рейс',subtitle:'Город или район',onTap:onTrip),const SizedBox(height:16),
        _QuickActionOrb(icon:Icons.local_gas_station_outlined,title:'Топливо',subtitle:'Газ или бензин',onTap:onFuel),const SizedBox(height:16),
        _QuickActionOrb(icon:Icons.receipt_long_outlined,title:'Накладная',subtitle:'Создать накладную',onTap:onInvoice),
      ]))))))]));
}

class _QuickActionOrb extends StatefulWidget {
  final IconData icon;final String title,subtitle;final VoidCallback onTap;
  const _QuickActionOrb({required this.icon,required this.title,required this.subtitle,required this.onTap});
  @override
  State<_QuickActionOrb> createState()=>_QuickActionOrbState();
}
class _QuickActionOrbState extends State<_QuickActionOrb> {
  bool _pressed=false;
  @override
  Widget build(BuildContext context)=>Semantics(button:true,label:widget.title,child:GestureDetector(
    onTapDown:(_)=>setState(()=>_pressed=true),onTapCancel:()=>setState(()=>_pressed=false),
    onTapUp:(_)=>setState(()=>_pressed=false),onTap:(){HapticFeedback.selectionClick();widget.onTap();},
    child:AnimatedScale(scale:_pressed ? 0.95 : 1.0,duration:const Duration(milliseconds:180),curve:Curves.easeOutCubic,
      child:Container(width:144,height:144,decoration:BoxDecoration(shape:BoxShape.circle,
        gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFF556168),Color(0xFF24343D),Color(0xFF070C10),Color(0xFFC78832)]),
        boxShadow:const [BoxShadow(color:Color(0xCC000000),blurRadius:16,offset:Offset(0,10)),BoxShadow(color:Color(0x44FFAD35),blurRadius:25,spreadRadius:1)]),
        padding:const EdgeInsets.all(4),child:Container(decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:const Color(0xD9FFBD5A)),
          gradient:const RadialGradient(center:Alignment(-.5,-.7),radius:1.2,colors:[Color(0xFF314752),Color(0xFF0D1D25),Color(0xFF02090E)])),
          child:Stack(alignment:Alignment.center,children:[Positioned(top:9,left:27,right:27,child:Container(height:31,decoration:const BoxDecoration(
            borderRadius:BorderRadius.all(Radius.elliptical(70,30)),gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Color(0x3375E4EF),Color(0x0075E4EF)])))),
            Column(mainAxisSize:MainAxisSize.min,children:[Icon(widget.icon,color:widget.title=='Топливо'?_ice:_amber,size:32,shadows:const [Shadow(color:Color(0x66FFB542),blurRadius:12)]),
              const SizedBox(height:12),_dt(widget.title,size:17,weight:FontWeight.w500),const SizedBox(height:6),_dt(widget.subtitle,size:11,color:const Color(0xFFB6C5CE))])]))))));
}

void _openTripEntry(BuildContext context) => _testEditor(context,'trip');




class _FullScreenChromePainter extends CustomPainter {
  const _FullScreenChromePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final orange = Paint()
      ..color = const Color(0xFFFF7418)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final glow = Paint()
      ..color = const Color(0x7AFF7418)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawLine(
      Offset(size.width * .68, 1.5),
      Offset(size.width * .90, 1.5),
      glow,
    );
    canvas.drawLine(
      Offset(size.width * .68, 1.5),
      Offset(size.width * .90, 1.5),
      orange,
    );

    canvas.drawLine(
      Offset(size.width - 1.5, size.height * .30),
      Offset(size.width - 1.5, size.height * .52),
      glow,
    );
    canvas.drawLine(
      Offset(size.width - 1.5, size.height * .30),
      Offset(size.width - 1.5, size.height * .52),
      orange,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



class _ChromeOrbPainter extends CustomPainter {
  const _ChromeOrbPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 5;
    final rect = Rect.fromCircle(center: c, radius: r);

    final outerGlow = Paint()
      ..color = const Color(0x78FF7418)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 19);
    canvas.drawCircle(c, r - 1, outerGlow);

    final cast = Paint()
      ..color = const Color(0xD8000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(Offset(c.dx, c.dy + 9), r - 8, cast);

    // Черная стеклянная линза.
    final fill = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-.38, -.48),
        radius: 1.02,
        colors: [
          Color(0xFF545960),
          Color(0xFF24282E),
          Color(0xFF0C0E11),
          Color(0xFF020304),
        ],
        stops: [0, .25, .61, 1],
      ).createShader(rect);
    canvas.drawCircle(c, r - 9, fill);

    // Широкая темная металлическая кромка.
    final metal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFB6BBC2),
          Color(0xFF2D3137),
          Color(0xFF0A0C0F),
          Color(0xFF555A62),
          Color(0xFF17191D),
          Color(0xFFB6BBC2),
        ],
        stops: [0, .16, .37, .58, .80, 1],
      ).createShader(rect);
    canvas.drawCircle(c, r - 9, metal);

    // Внутренний стеклянный кант.
    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .72
      ..color = const Color(0x69E6E8EB);
    canvas.drawCircle(c, r - 14, inner);

    // Оранжевая дуга + мягкий glow.
    final hotGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x9CFF7418)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 11),
      math.pi * .10,
      math.pi * .82,
      false,
      hotGlow,
    );

    final hot = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFF8E39);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 11),
      math.pi * .10,
      math.pi * .82,
      false,
      hot,
    );

    // Верхний белый блик — короткий, не сплошной белый ободок.
    final whiteGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x5BFFFFFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 12),
      math.pi * 1.10,
      math.pi * .29,
      false,
      whiteGlow,
    );

    final whiteCore = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .78
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xC8FFFFFF);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 12),
      math.pi * 1.10,
      math.pi * .29,
      false,
      whiteCore,
    );

    // Внутренний оранжевый рефлекс в нижней правой части сферы.
    final innerOrange = Paint()
      ..color = const Color(0x34FF7418)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(
      Offset(c.dx + r * .28, c.dy + r * .32),
      r * .25,
      innerOrange,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}





class _ChromeCloseOrb extends StatelessWidget {
  const _ChromeCloseOrb();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: CustomPaint(
        painter: const _ChromeOrbPainter(),
        child: const Icon(
          Icons.close_rounded,
          color: AppColors.text,
          size: 25,
        ),
      ),
    );
  }
}


class _TripEntrySheet extends StatefulWidget {
  const _TripEntrySheet();

  @override
  State<_TripEntrySheet> createState() => _TripEntrySheetState();
}

class _TripEntrySheetState extends State<_TripEntrySheet> {
  bool _saving=false;
  String _type = 'Город';
  String _direction = 'Петропавловск';
  final TextEditingController _tonnageController = TextEditingController();

  @override
  void dispose() {
    _tonnageController.dispose();
    super.dispose();
  }

  List<String> get _directions => _type == 'Город'
      ? const ['Петропавловск', 'Бишкуль']
      : const ['Пресновка', 'Щучинск', 'Новоишимское'];

  @override
  Widget build(BuildContext context) {
    return _QuickEntryShell(
      title: 'Новый рейс',
      icon: Icons.local_shipping_outlined,
      child: Column(
        children: [
          _QuickSegment(
            values: const ['Город', 'Район'],
            selected: _type,
            onChanged: (value) {
              setState(() {
                _type = value;
                _direction = _directions.first;
              });
            },
          ),
          const SizedBox(height: 14),
          _QuickSelectField(
            label: 'НАПРАВЛЕНИЕ',
            value: _direction,
            onTap: () async {
              final result = await _pickQuickValue(
                context,
                'Направление',
                _directions,
              );
              if (result != null && mounted) {
                setState(() => _direction = result);
              }
            },
          ),
          const SizedBox(height: 14),
          _QuickNumberField(
            controller: _tonnageController,
            hint: 'Тоннаж, т',
          ),
          const SizedBox(height: 18),
          _QuickSaveButton(
            text: 'Добавить рейс',
            onTap: () async {
              HapticFeedback.mediumImpact();
              final tonnage = double.tryParse(_tonnageController.text.replaceAll(',', '.')) ?? 0;
              if (!tonnage.isFinite || tonnage <= 0) return;
              if(_saving)return;_saving=true;
              try {await _HomeMonthData.addTrip(tonnage, type: _type, direction: _direction);}
              catch(_){_saving=false;if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Рейс не сохранён. Повторите попытку.')));return;}
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

void _openFuelEntry(BuildContext context) => _testEditor(context,'fuel');

class _FuelEntrySheet extends StatefulWidget {
  const _FuelEntrySheet();

  @override
  State<_FuelEntrySheet> createState() => _FuelEntrySheetState();
}

class _FuelEntrySheetState extends State<_FuelEntrySheet> {
  bool _saving=false;
  String _fuel = 'Газ';
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _QuickEntryShell(
      title: 'Топливо',
      icon: Icons.local_gas_station_outlined,
      child: Column(
        children: [
          _QuickSegment(
            values: const ['Газ', 'Бензин'],
            selected: _fuel,
            onChanged: (value) {
              setState(() => _fuel = value);
            },
          ),
          const SizedBox(height: 14),
          _QuickNumberField(
            controller: _controller,
            hint: 'Литры',
          ),
          const SizedBox(height: 18),
          _QuickSaveButton(
            text: 'Сохранить',
            onTap: () async {
              HapticFeedback.mediumImpact();
              final litres = double.tryParse(_controller.text.replaceAll(',', '.')) ?? 0;
              if(!litres.isFinite||litres<=0||_saving)return;_saving=true;
              try {await _HomeMonthData.addFuel(_fuel, litres);}
              catch(_){_saving=false;if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Заправка не сохранена. Повторите попытку.')));return;}
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _QuickEntryShell extends StatelessWidget {
  final String title;final IconData icon;final Widget child;
  const _QuickEntryShell({required this.title,required this.icon,required this.child});
  @override Widget build(BuildContext context){final mq=MediaQuery.of(context);
    return AnimatedPadding(duration:const Duration(milliseconds:220),curve:Curves.easeOutCubic,padding:EdgeInsets.only(bottom:mq.viewInsets.bottom),
      child:ConstrainedBox(constraints:BoxConstraints(maxHeight:math.max(140,mq.size.height-mq.viewInsets.bottom-mq.padding.top-24)),
        child:SingleChildScrollView(padding:const EdgeInsets.fromLTRB(12,8,12,12),child:_DetailGlass(accent:true,padding:const EdgeInsets.all(14),child:Column(mainAxisSize:MainAxisSize.min,children:[
          Container(width:32,height:3,decoration:BoxDecoration(color:const Color(0xFF67747B),borderRadius:BorderRadius.circular(3))),const SizedBox(height:4),
          Row(children:[Icon(icon,color:_amber,size:21),const SizedBox(width:10),Expanded(child:_dt(title,size:16,weight:FontWeight.w500)),
            IconButton(tooltip:'Закрыть',onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.close,color:_paper,size:21))]),const SizedBox(height:8),child])))));
  }
}

class _QuickSegment extends StatelessWidget {
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;

  const _QuickSegment({
    required this.values,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(values.length, (index) {
        final value = values[index];
        final active = value == selected;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 5,
              right: index == values.length - 1 ? 0 : 5,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(value);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0x332EDCEF)
                      : const Color(0x88061119),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: active
                        ? _amber
                        : const Color(0x667A929F),
                  ),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    color: active
                        ? _amber
                        : AppColors.textSoft,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _QuickSelectField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _QuickSelectField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0x88061119),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Color(0x667A929F)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 8.5,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                    fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _amber,
            ),
          ],
        ),
      ),
    );
  }
}

Future<String?> _pickQuickValue(BuildContext context,String title,List<String> values)=>showModalBottomSheet<String>(
  context:context,isScrollControlled:true,backgroundColor:Colors.transparent,
  builder:(c)=>_QuickEntryShell(title:title,icon:Icons.list_alt,child:Column(mainAxisSize:MainAxisSize.min,children:[
    for(final value in values)_detailRow(value,'',onTap:()=>Navigator.pop(c,value))])));

class _QuickNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _QuickNumberField({
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        TextInputFormatter.withFunction((oldValue, newValue) =>
          RegExp(r'^\d*([.,]\d*)?$').hasMatch(newValue.text) ? newValue : oldValue),
      ],
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 16,
                    fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textDim,
          fontSize: 14,
        ),
        filled: true,
        fillColor: const Color(0x88061119),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: Color(0x667A929F),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: _amber,
          ),
        ),
      ),
    );
  }
}

class _QuickSaveButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _QuickSaveButton({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _amber,
          side: const BorderSide(
            color: _amber,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
                    fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}



class _ShiftTimelineCard extends StatelessWidget {
  const _ShiftTimelineCard();

  @override
  Widget build(BuildContext context) {
    return _ChromeGlassSurface(
      radius: 23,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 10),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'ХОД СМЕНЫ',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Spacer(),
              Text('Смотреть все', style: TextStyle(color: AppColors.textDim, fontSize: 8.5)),
              SizedBox(width: 3),
              Icon(Icons.arrow_forward_rounded, color: AppColors.orange, size: 16),
            ],
          ),
          SizedBox(height: 9),
          _TimelineRow(icon: Icons.radio_button_checked, time: '05:48', text: 'Смена открыта', active: true),
          _TimelineRow(icon: Icons.local_shipping_outlined, time: '06:15', text: 'Рейс: Петропавл → Щучинск'),
          _TimelineRow(icon: Icons.local_gas_station_outlined, time: '08:20', text: 'Заправка: 400 л • АЗС'),
          _TimelineRow(icon: Icons.route_outlined, time: '11:10', text: 'Щучинск → Новоишимское'),
          _TimelineRow(icon: Icons.flag_outlined, time: '14:53', text: 'Прибытие по маршруту'),
        ],
      ),
    );
  }
}




class _MapMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;

  const _MapMetric({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(icon, color: AppColors.orange, size: 19),
              const SizedBox(width: 5),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: const TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: AppColors.textDim, fontSize: 7.5),
          ),
        ],
      ),
    );
  }
}

class _WorkGpsStrip extends StatelessWidget {
  const _WorkGpsStrip();

  @override
  Widget build(BuildContext context) {
    return _ChromeGlassSurface(
      radius: 19,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      accent: const Color(0xFF55E66B),
      child: const Row(
        children: [
          _GlowDot(color: Color(0xFF55E66B)),
          SizedBox(width: 8),
          Text(
            'GPS активен',
            style: TextStyle(
              color: Color(0xFF76F08C),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          Spacer(),
          Icon(Icons.signal_cellular_alt_rounded, color: Color(0xFF55E66B), size: 18),
          SizedBox(width: 10),
          Text(
            '18,96 км',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(width: 4),
          Text('пробег смены', style: TextStyle(color: AppColors.textDim, fontSize: 7.5)),
          SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: AppColors.orange, size: 18),
        ],
      ),
    );
  }
}


class _TimelineRow extends StatelessWidget {
  final IconData icon;
  final String time;
  final String text;
  final bool active;
  const _TimelineRow({required this.icon, required this.time, required this.text, this.active = false});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 16, color: active ? const Color(0xFF55E66B) : AppColors.orange),
          const SizedBox(width: 10),
          SizedBox(width: 42, child: Text(time, style: const TextStyle(color: AppColors.textSoft, fontSize: 10))),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.text, fontSize: 11.5, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}


class InvoicesPage extends StatelessWidget {
  final AppSession session;

  const InvoicesPage({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Накладные',
      subtitle: 'Сегодня • 3 документа',
      trailing: _RoundAction(
        icon: Icons.add_rounded,
        onTap: () => _showFeatureStub(
          context,
          'Новая накладная',
          'Следующим шагом подключим сюда твою существующую механику позиций, веса и отметки загрузки.',
        ),
      ),
      children: [
        _InvoiceSummaryCard(
          onCreate: () => _showFeatureStub(
            context,
            'Создать накладную',
            'Интерфейс уже подготовлен под текущую серверную механику накладных.',
          ),
        ),
        const SizedBox(height: 18),
        const _SectionTitle(title: 'Сегодня', caption: '12 383 кг'),
        const SizedBox(height: 10),
        const _InvoicePremiumCard(
          number: '№ 4821',
          direction: 'Пресновка',
          weight: '2 840 кг',
          time: '07:42',
          status: 'Загружено',
          items: '6 позиций',
          accent: AppColors.orange,
        ),
        const SizedBox(height: 10),
        const _InvoicePremiumCard(
          number: '№ 4820',
          direction: 'Бишкуль',
          weight: '1 960 кг',
          time: '06:18',
          status: 'Доставлено',
          items: '4 позиции',
          accent: AppColors.blue,
        ),
        const SizedBox(height: 10),
        const _InvoicePremiumCard(
          number: '№ 4819',
          direction: 'Мамлютка',
          weight: '3 120 кг',
          time: '05:25',
          status: 'Доставлено',
          items: '8 позиций',
          accent: AppColors.amber,
        ),
        const SizedBox(height: 18),
        _InvoiceArchiveCard(
          onTap: () => _showFeatureStub(
            context,
            'Архив накладных',
            'Здесь будет поиск по дате, направлению и номеру накладной.',
          ),
        ),
      ],
    );
  }
}

class StatisticsPage extends StatelessWidget {
  final AppSession session;

  const StatisticsPage({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Статистика',
      subtitle: 'Сентябрь 2026',
      trailing: const _StatusPill(text: 'Месяц', color: AppColors.orange),
      children: const [
        _StatisticsHero(),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatPremiumTile(
              title: 'Пробег',
              value: '0 км',
              caption: 'за месяц',
              icon: Icons.route_rounded,
              accent: AppColors.blue,
            )),
            SizedBox(width: 10),
            Expanded(child: _StatPremiumTile(
              title: 'Рейсы',
              value: '29',
              caption: 'выполнено',
              icon: Icons.local_shipping_outlined,
              accent: AppColors.orange,
            )),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _StatPremiumTile(
              title: 'Город',
              value: '58 800 кг',
              caption: '59%',
              icon: Icons.apartment_rounded,
              accent: Color(0xFF67E56A),
            )),
            SizedBox(width: 10),
            Expanded(child: _StatPremiumTile(
              title: 'Район',
              value: '41 082 кг',
              caption: '41%',
              icon: Icons.landscape_outlined,
              accent: AppColors.amber,
            )),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _StatPremiumTile(
              title: 'Газ',
              value: '1 545 л',
              caption: 'за месяц',
              icon: Icons.local_gas_station_outlined,
              accent: AppColors.blue,
            )),
            SizedBox(width: 10),
            Expanded(child: _StatPremiumTile(
              title: 'Бензин',
              value: '20 л',
              caption: 'за месяц',
              icon: Icons.local_gas_station_rounded,
              accent: AppColors.violet,
            )),
          ],
        ),
        SizedBox(height: 10),
        _PaidRoutesStatCard(),
        SizedBox(height: 18),
        _TonnageSplitCard(),
        SizedBox(height: 18),
        _SectionTitle(title: 'Динамика тоннажа', caption: 'Месяц'),
        SizedBox(height: 10),
        _ChartCard(),
        SizedBox(height: 18),
        _DirectionStats(),
      ],
    );
  }
}

class _InvoiceSummaryCard extends StatelessWidget {
  final VoidCallback onCreate;
  const _InvoiceSummaryCard({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _premiumDecoration(radius: 26),
      child: Column(
        children: [
          Row(
            children: [
              const _SquareIcon(icon: Icons.receipt_long_rounded, color: AppColors.orange),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Документы смены', style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w800)),
                    SizedBox(height: 3),
                    Text('3 накладные • 12 383 кг', style: TextStyle(color: AppColors.textSoft, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x1AFF7A1A),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: const Color(0x664A3320)),
                ),
                child: const Text('СЕГОДНЯ', style: TextStyle(color: AppColors.orangeSoft, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .8)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); onCreate(); },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF7417), Color(0xFFFFA51F)]),
                borderRadius: BorderRadius.circular(17),
                boxShadow: const [BoxShadow(color: Color(0x33FF7A1A), blurRadius: 18, offset: Offset(0, 7))],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: Colors.black, size: 22),
                  SizedBox(width: 8),
                  Text('Создать накладную', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoicePremiumCard extends StatelessWidget {
  final String number, direction, weight, time, status, items;
  final Color accent;
  const _InvoicePremiumCard({
    required this.number, required this.direction, required this.weight,
    required this.time, required this.status, required this.items, required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _premiumDecoration(radius: 22),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: .35)),
            ),
            child: Icon(Icons.description_outlined, color: accent, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(direction, style: const TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w900))),
                  Text(time, style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
                ]),
                const SizedBox(height: 5),
                Text('$weight  •  $items', style: const TextStyle(color: AppColors.textSoft, fontSize: 11)),
                const SizedBox(height: 8),
                Row(children: [
                  Text(number, style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
                  const Spacer(),
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(status, style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w800)),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textDim, size: 20),
        ],
      ),
    );
  }
}

class _InvoiceArchiveCard extends StatelessWidget {
  final VoidCallback onTap;
  const _InvoiceArchiveCard({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
        decoration: _premiumDecoration(radius: 20),
        child: const Row(
          children: [
            Icon(Icons.history_rounded, color: AppColors.orange, size: 21),
            SizedBox(width: 12),
            Expanded(child: Text('Архив накладных', style: TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w800))),
            Text('Поиск и история', style: TextStyle(color: AppColors.textDim, fontSize: 10)),
            SizedBox(width: 5),
            Icon(Icons.chevron_right_rounded, color: AppColors.orange, size: 20),
          ],
        ),
      ),
    );
  }
}

class _StatPremiumTile extends StatelessWidget {
  final String title, value, caption;
  final IconData icon;
  final Color accent;
  const _StatPremiumTile({required this.title, required this.value, required this.caption, required this.icon, required this.accent});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 126,
      padding: const EdgeInsets.all(15),
      decoration: _premiumDecoration(radius: 22),
      child: Stack(
        children: [
          Positioned(top: 0, right: 0, child: Icon(icon, color: accent, size: 22)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title.toUpperCase(), style: const TextStyle(color: AppColors.textSoft, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: .7)),
              const Spacer(),
              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: const TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -.5))),
              const SizedBox(height: 4),
              Text(caption, style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
              const SizedBox(height: 9),
              Container(height: 3, decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), gradient: LinearGradient(colors: [accent, accent.withValues(alpha: .08)]))),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaidRoutesStatCard extends StatelessWidget {
  const _PaidRoutesStatCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _premiumDecoration(radius: 22),
      child: const Row(
        children: [
          _SquareIcon(icon: Icons.alt_route_rounded, color: AppColors.orange),
          SizedBox(width: 13),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ПЛАТНЫЕ НАПРАВЛЕНИЯ', style: TextStyle(color: AppColors.textSoft, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: .7)),
              SizedBox(height: 5),
              Text('3 рейса', style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          )),
          Icon(Icons.arrow_forward_rounded, color: AppColors.orange, size: 21),
        ],
      ),
    );
  }
}

class _TonnageSplitCard extends StatelessWidget {
  const _TonnageSplitCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _premiumDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.scale_outlined, color: AppColors.orange, size: 21),
              SizedBox(width: 9),
              Expanded(child: Text('Тоннаж по направлениям', style: TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w900))),
              Text('99 882 кг', style: TextStyle(color: AppColors.textSoft, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const SizedBox(width: 120, height: 120, child: _RingProgress(progress: .59, centerTitle: '99 882', centerCaption: 'кг')),
              const SizedBox(width: 18),
              Expanded(child: Column(
                children: [
                  _TonnageLegend(color: AppColors.orange, title: 'Город', value: '58 800 кг', percent: '59%'),
                  SizedBox(height: 15),
                  _TonnageLegend(color: AppColors.amber, title: 'Район', value: '41 082 кг', percent: '41%'),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _TonnageLegend extends StatelessWidget {
  final Color color;
  final String title, value, percent;
  const _TonnageLegend({required this.color, required this.title, required this.value, required this.percent});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withValues(alpha: .35), blurRadius: 8)])),
        const SizedBox(width: 9),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: AppColors.textSoft, fontSize: 11)),
          const SizedBox(height: 3),
          Text('$value ($percent)', style: const TextStyle(color: AppColors.text, fontSize: 11, fontWeight: FontWeight.w800)),
        ])),
      ],
    );
  }
}


class SearchPage extends StatefulWidget {
  final AppSession session;

  const SearchPage({
    super.key,
    required this.session,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = widget.session.role == AppRole.admin;

    return _PageScaffold(
      title: 'Поиск',
      subtitle: 'Данные и история',
      trailing: const _StatusPill(
        text: 'Быстрый',
        color: AppColors.blue,
      ),
      children: [
        TextField(
          controller: _controller,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Маршрут, дата, накладная...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _controller.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 18),
        const _SectionTitle(
          title: 'Быстрый доступ',
          caption: 'Разделы',
        ),
        const SizedBox(height: 10),
        const _SearchShortcut(
          icon: Icons.receipt_long_outlined,
          title: 'Накладные',
          caption: 'По номеру, дате и направлению',
          accent: AppColors.violet,
        ),
        const SizedBox(height: 10),
        const _SearchShortcut(
          icon: Icons.route_outlined,
          title: 'Маршруты',
          caption: 'История поездок и GPS',
          accent: AppColors.blue,
        ),
        const SizedBox(height: 10),
        const _SearchShortcut(
          icon: Icons.payments_outlined,
          title: 'Заработок',
          caption: 'Смена, месяц, начисления',
          accent: AppColors.orange,
        ),
        if (admin) ...[
          const SizedBox(height: 18),
          const _SectionTitle(
            title: 'Администратор',
            caption: 'Сотрудники',
          ),
          const SizedBox(height: 10),
          _SearchShortcut(
            icon: Icons.groups_2_outlined,
            title: 'Сотрудники',
            caption: 'Водители, грузчики и права доступа',
            accent: AppColors.amber,
            onTap: () => _showEmployees(context),
          ),
        ],
      ],
    );
  }
}

class LoaderShiftPage extends StatelessWidget {
  final AppSession session;

  const LoaderShiftPage({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Смена',
      subtitle: 'Кабинет грузчика',
      trailing: const _StatusPill(
        text: 'Активна',
        color: AppColors.blue,
      ),
      children: [
        _WelcomeHeader(
          session: session,
          icon: Icons.inventory_2_outlined,
        ),
        const SizedBox(height: 18),
        const _LoaderHero(),
        const SizedBox(height: 14),
        const Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Ставка',
                value: '1 365 ₸',
                caption: 'в час',
                icon: Icons.payments_outlined,
                accent: AppColors.orange,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Уже учтено',
                value: '124 ч',
                caption: 'в сентябре',
                icon: Icons.history_toggle_off_rounded,
                accent: AppColors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _LoaderMonthCard(),
        const SizedBox(height: 18),
        _PrimaryActionCard(
          icon: Icons.play_arrow_rounded,
          title: 'Начать смену',
          caption: 'Запустить учёт рабочего времени',
          onTap: () => _showFeatureStub(
            context,
            'Смена грузчика',
            'На следующем этапе эта кнопка будет работать через твой текущий сервер.',
          ),
        ),
      ],
    );
  }
}

class LoaderHistoryPage extends StatelessWidget {
  final AppSession session;

  const LoaderHistoryPage({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'История',
      subtitle: 'Смены грузчика',
      trailing: const _StatusPill(
        text: 'Сентябрь',
        color: AppColors.blue,
      ),
      children: const [
        _LoaderHistorySummary(),
        SizedBox(height: 18),
        _SectionTitle(
          title: 'Последние смены',
          caption: 'Сентябрь 2026',
        ),
        SizedBox(height: 10),
        _LoaderHistoryRow(
          date: '17 сентября',
          hours: '8 ч 30 мин',
          amount: '11 603 ₸',
        ),
        SizedBox(height: 10),
        _LoaderHistoryRow(
          date: '16 сентября',
          hours: '9 ч 10 мин',
          amount: '12 513 ₸',
        ),
        SizedBox(height: 10),
        _LoaderHistoryRow(
          date: '15 сентября',
          hours: '8 ч 00 мин',
          amount: '10 920 ₸',
        ),
      ],
    );
  }
}

class _PageScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;
  final List<Widget> children;

  const _PageScaffold({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        _PageHeader(
          title: title,
          subtitle: subtitle,
          trailing: trailing,
        ),
        const SizedBox(height: 22),
        ...children,
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;

  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  final AppSession session;
  final IconData icon;

  const _WelcomeHeader({
    required this.session,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Icon(
            icon,
            color: AppColors.orange,
            size: 24,
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
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                session.role.title,
                style: const TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const _TamerlanMiniLogo(),
      ],
    );
  }
}

class _TamerlanMiniLogo extends StatelessWidget {
  const _TamerlanMiniLogo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'ТАМЕРЛАН',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'MILLING SYSTEM',
          style: TextStyle(
            color: AppColors.textDim,
            fontSize: 7,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusPill({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: color.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.65),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Color accent;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 126,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              icon,
              color: accent,
              size: 22,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                style: const TextStyle(
                  color: AppColors.textDim,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlowDot extends StatelessWidget {
  final Color color;

  const _GlowDot({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.7),
            blurRadius: 12,
          ),
        ],
      ),
    );
  }
}



class _WorkHero extends StatelessWidget {
  const _WorkHero();

  @override
  Widget build(BuildContext context) {
    return _ChromeGlassSurface(
      radius: 27,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 575,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _RoutePreview(),
              Positioned(
                left: 8,
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 9, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xE40A0C0F),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF6A6F77), width: .7),
                    boxShadow: const [
                      BoxShadow(color: Color(0xB0000000), blurRadius: 16, offset: Offset(0, 7)),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Петропавл → Щучинск',
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.6,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Текущий маршрут • 18,96 км • 3 рейса • 12 383 кг',
                              style: TextStyle(color: AppColors.textSoft, fontSize: 8.5),
                            ),
                          ],
                        ),
                      ),
                      _StatusPill(text: 'LIVE', color: AppColors.orange),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: _ChromeGlassSurface(
                  radius: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                  child: const Row(
                    children: [
                      Expanded(
                        child: _MapMetric(
                          icon: Icons.speed_rounded,
                          value: '67',
                          unit: 'км/ч',
                          label: 'Текущая скорость',
                        ),
                      ),
                      _VerticalDivider(),
                      Expanded(
                        child: _MapMetric(
                          icon: Icons.timer_outlined,
                          value: '5:42',
                          unit: '',
                          label: 'В пути',
                        ),
                      ),
                      _VerticalDivider(),
                      Expanded(
                        child: _MapMetric(
                          icon: Icons.route_rounded,
                          value: '328',
                          unit: 'км',
                          label: 'До точки',
                        ),
                      ),
                    ],
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



class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      color: AppColors.line,
    );
  }
}



class _RoutePreview extends StatelessWidget {
  const _RoutePreview();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF101720),
            Color(0xFF091015),
            Color(0xFF030608),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _RoutePainter(),
        child: Stack(
          children: [
            const Positioned(
              left: 18,
              bottom: 114,
              child: _MapLabel(title: 'Петропавл', icon: Icons.local_shipping_rounded),
            ),
            const Positioned(
              right: 28,
              top: 140,
              child: _MapLabel(title: 'Щучинск', icon: Icons.location_on_rounded),
            ),
            Positioned(
              right: 12,
              top: 190,
              child: Column(
                children: [
                  _MapRoundButton(icon: Icons.near_me_rounded),
                  const SizedBox(height: 7),
                  _MapRoundButton(icon: Icons.add_rounded),
                  const SizedBox(height: 5),
                  _MapRoundButton(icon: Icons.remove_rounded),
                  const SizedBox(height: 7),
                  _MapRoundButton(icon: Icons.crop_free_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _MapLabel extends StatelessWidget {
  final String title;
  final IconData icon;

  const _MapLabel({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xD90A0C0F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF454950), width: .7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.orange, size: 14),
          const SizedBox(width: 5),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}


class _MapRoundButton extends StatelessWidget {
  final IconData icon;

  const _MapRoundButton({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: CustomPaint(
        painter: const _DarkRoundControlPainter(),
        child: Icon(
          icon,
          color: AppColors.text,
          size: 18,
        ),
      ),
    );
  }
}




class _DarkRoundControlPainter extends CustomPainter {
  const _DarkRoundControlPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 1.5;
    final rect = Rect.fromCircle(center: c, radius: r);

    final fill = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-.36, -.42),
        colors: [
          Color(0xFF464A51),
          Color(0xFF171A1E),
          Color(0xFF050607),
        ],
      ).createShader(rect);
    canvas.drawCircle(c, r, fill);

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFB2B7BE),
          Color(0xFF2C3035),
          Color(0xFF111317),
          Color(0xFF6B7077),
          Color(0xFFB2B7BE),
        ],
      ).createShader(rect);
    canvas.drawCircle(c, r - .7, edge);

    final shadow = Paint()
      ..color = const Color(0x94000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(c.dx, c.dy + 3), r - 6, shadow);

    final warm = Paint()
      ..color = const Color(0x30FF7418)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(c.dx + 6, c.dy + 7), r * .38, warm);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0B1218),
          Color(0xFF071015),
          Color(0xFF030608),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, background);

    final softGrid = Paint()
      ..color = const Color(0xFF111820)
      ..strokeWidth = .45;

    for (double x = 18; x < size.width; x += 58) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.width * .10, size.height),
        softGrid,
      );
    }
    for (double y = 24; y < size.height; y += 68) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + 15),
        softGrid,
      );
    }

    final minorRoad = Paint()
      ..color = const Color(0xFF263038)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05
      ..strokeCap = StrokeCap.round;

    final majorRoad = Paint()
      ..color = const Color(0xFF3A454D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.55
      ..strokeCap = StrokeCap.round;

    Path road(List<Offset> p) {
      final path = Path()..moveTo(p.first.dx, p.first.dy);
      for (var i = 1; i < p.length; i++) {
        path.lineTo(p[i].dx, p[i].dy);
      }
      return path;
    }

    final roads = <Path>[
      road([
        Offset(-20, size.height * .26),
        Offset(size.width * .22, size.height * .31),
        Offset(size.width * .47, size.height * .27),
        Offset(size.width * .76, size.height * .33),
        Offset(size.width + 20, size.height * .29),
      ]),
      road([
        Offset(size.width * .08, -20),
        Offset(size.width * .16, size.height * .18),
        Offset(size.width * .28, size.height * .38),
        Offset(size.width * .32, size.height * .72),
        Offset(size.width * .44, size.height + 20),
      ]),
      road([
        Offset(-20, size.height * .63),
        Offset(size.width * .23, size.height * .57),
        Offset(size.width * .42, size.height * .51),
        Offset(size.width * .67, size.height * .55),
        Offset(size.width + 20, size.height * .46),
      ]),
      road([
        Offset(size.width * .58, -20),
        Offset(size.width * .53, size.height * .22),
        Offset(size.width * .60, size.height * .46),
        Offset(size.width * .71, size.height * .72),
        Offset(size.width * .76, size.height + 20),
      ]),
      road([
        Offset(-20, size.height * .82),
        Offset(size.width * .18, size.height * .77),
        Offset(size.width * .37, size.height * .79),
        Offset(size.width * .58, size.height * .72),
        Offset(size.width + 20, size.height * .76),
      ]),
      road([
        Offset(size.width * .89, -20),
        Offset(size.width * .80, size.height * .21),
        Offset(size.width * .84, size.height * .45),
        Offset(size.width * .72, size.height * .63),
        Offset(size.width * .66, size.height + 20),
      ]),
    ];

    for (var i = 0; i < roads.length; i++) {
      canvas.drawPath(roads[i], i.isEven ? majorRoad : minorRoad);
    }

    // Несколько синих/холодных ответвлений, как у настоящей темной карты.
    final coldRoad = Paint()
      ..color = const Color(0xFF243F50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .9
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(
      Path()
        ..moveTo(size.width * .04, size.height * .13)
        ..cubicTo(
          size.width * .27,
          size.height * .18,
          size.width * .25,
          size.height * .48,
          size.width * .52,
          size.height * .43,
        )
        ..cubicTo(
          size.width * .75,
          size.height * .40,
          size.width * .78,
          size.height * .62,
          size.width * .98,
          size.height * .66,
        ),
      coldRoad,
    );

    // Сам маршрут.
    final route = Path()
      ..moveTo(size.width * .13, size.height * .82)
      ..cubicTo(
        size.width * .22,
        size.height * .73,
        size.width * .28,
        size.height * .64,
        size.width * .38,
        size.height * .62,
      )
      ..cubicTo(
        size.width * .53,
        size.height * .59,
        size.width * .49,
        size.height * .46,
        size.width * .62,
        size.height * .43,
      )
      ..cubicTo(
        size.width * .76,
        size.height * .40,
        size.width * .75,
        size.height * .24,
        size.width * .87,
        size.height * .18,
      );

    final routeGlow = Paint()
      ..color = const Color(0x99FF7418)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);

    final routeEdge = Paint()
      ..color = const Color(0xFFFF4F00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.2
      ..strokeCap = StrokeCap.round;

    final routeCore = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFC06A),
          Color(0xFFFF7A18),
          Color(0xFFFFA844),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(route, routeGlow);
    canvas.drawPath(route, routeEdge);
    canvas.drawPath(route, routeCore);

    final start = Offset(size.width * .13, size.height * .82);
    final finish = Offset(size.width * .87, size.height * .18);

    canvas.drawCircle(
      start,
      11,
      Paint()
        ..color = const Color(0x55FF7418)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(start, 5.5, Paint()..color = const Color(0xFFFF8B2A));

    canvas.drawCircle(
      finish,
      15,
      Paint()
        ..color = const Color(0x66FF7418)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(finish, 8, Paint()..color = const Color(0xFFFF8B2A));
    canvas.drawCircle(finish, 3.2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



class _PrimaryActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback onTap;

  const _PrimaryActionCard({
    required this.icon,
    required this.title,
    required this.caption,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1D1711),
              Color(0xFF121316),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF4A3320),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 22,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            _SquareIcon(
              icon: icon,
              color: AppColors.orange,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    caption,
                    style: const TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.orange,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsHero extends StatelessWidget {
  const _StatisticsHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 184,
      padding: const EdgeInsets.all(19),
      decoration: _premiumDecoration(radius: 26),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ЗАРПЛАТА ЗА СЕНТЯБРЬ 2026 Г.', style: TextStyle(color: AppColors.textSoft, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: .7)),
                SizedBox(height: 9),
                Text('312 105,8 ₸', style: TextStyle(color: AppColors.text, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
                SizedBox(height: 7),
                Text('154 / 176 ч', style: TextStyle(color: AppColors.textSoft, fontSize: 11)),
                Spacer(),
                Text('Выполнение месячного плана', style: TextStyle(color: AppColors.textDim, fontSize: 9)),
                SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(99)),
                  child: LinearProgressIndicator(
                    value: .88,
                    minHeight: 5,
                    backgroundColor: Color(0xFF24262A),
                    color: AppColors.orange,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          _RingProgress(progress: .88, centerTitle: '88%', centerCaption: 'план'),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 12),
      decoration: _premiumDecoration(radius: 24),
      child: CustomPaint(
        painter: _ChartPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFF1D2026)
      ..strokeWidth = 1;

    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        grid,
      );
    }

    final values = [
      0.70,
      0.52,
      0.60,
      0.38,
      0.45,
      0.28,
      0.35,
      0.20,
      0.33,
      0.24,
      0.16,
      0.23,
      0.14,
      0.11,
    ];

    final path = Path();
    final dx = size.width / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final x = i * dx;
      final y = size.height * values[i];

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final glow = Paint()
      ..color = const Color(0x44FF7A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final line = Paint()
      ..shader = const LinearGradient(
        colors: [
          AppColors.orange,
          AppColors.orangeSoft,
        ],
      ).createShader(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        ),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, glow);
    canvas.drawPath(path, line);

    final dot = Paint()
      ..color = AppColors.orange
      ..style = PaintingStyle.fill;

    for (int i = 0; i < values.length; i += 3) {
      canvas.drawCircle(
        Offset(
          i * dx,
          size.height * values[i],
        ),
        3.5,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DirectionStats extends StatelessWidget {
  const _DirectionStats();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Город', 0.74, '62 рейса'),
      ('Район', 0.52, '25 рейсов'),
      ('Платные', 0.28, '11 рейсов'),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == items.length - 1 ? 0 : 16,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.$1,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      item.$3,
                      style: const TextStyle(
                        color: AppColors.textSoft,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: item.$2,
                    minHeight: 5,
                    backgroundColor: const Color(0xFF23262C),
                    color: AppColors.orange,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _SearchShortcut extends StatelessWidget {
  final IconData icon;
  final String title;
  final String caption;
  final Color accent;
  final VoidCallback? onTap;

  const _SearchShortcut({
    required this.icon,
    required this.title,
    required this.caption,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            _SquareIcon(
              icon: icon,
              color: accent,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    caption,
                    style: const TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textDim,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoaderHero extends StatelessWidget {
  const _LoaderHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 188,
      padding: const EdgeInsets.all(20),
      decoration: _premiumDecoration(
        accent: AppColors.blue,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _GlowDot(color: AppColors.blue),
              SizedBox(width: 9),
              Text(
                'Смена не запущена',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Spacer(),
          Text(
            '0:00',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 45,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.8,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'рабочее время сегодня',
            style: TextStyle(
              color: AppColors.textSoft,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoaderMonthCard extends StatelessWidget {
  const _LoaderMonthCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              Text(
                'Сентябрь',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Spacer(),
              Text(
                '124 ч',
                style: TextStyle(
                  color: AppColors.blue,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Divider(height: 1),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TinyStat(
                  label: 'Начислено',
                  value: '169 260 ₸',
                ),
              ),
              Expanded(
                child: _TinyStat(
                  label: 'Удержания',
                  value: '40 000 ₸',
                ),
              ),
              Expanded(
                child: _TinyStat(
                  label: 'Итого',
                  value: '129 260 ₸',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoaderHistorySummary extends StatelessWidget {
  const _LoaderHistorySummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: _premiumDecoration(
        accent: AppColors.blue,
      ),
      child: const Row(
        children: [
          Expanded(
            child: _TinyStat(
              label: 'Часы за месяц',
              value: '149.7 ч',
            ),
          ),
          Expanded(
            child: _TinyStat(
              label: 'Смен',
              value: '17',
            ),
          ),
          Expanded(
            child: _TinyStat(
              label: 'К выплате',
              value: '164 341 ₸',
            ),
          ),
        ],
      ),
    );
  }
}

class _LoaderHistoryRow extends StatelessWidget {
  final String date;
  final String hours;
  final String amount;

  const _LoaderHistoryRow({
    required this.date,
    required this.hours,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const _SquareIcon(
            icon: Icons.schedule_outlined,
            color: AppColors.blue,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hours,
                  style: const TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String caption;

  const _SectionTitle({
    required this.title,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Text(
          caption,
          style: const TextStyle(
            color: AppColors.textDim,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SquareIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SquareIcon({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: 21,
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundAction({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.line),
      ),
      icon: Icon(
        icon,
        color: AppColors.orange,
      ),
    );
  }
}

class _TinyStat extends StatelessWidget {
  final String label;
  final String value;

  const _TinyStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textDim,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.fade,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _RingProgress extends StatelessWidget {
  final double progress;
  final String centerTitle;
  final String centerCaption;

  const _RingProgress({
    required this.progress,
    required this.centerTitle,
    required this.centerCaption,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerTitle,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                centerCaption,
                style: const TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;

  _RingPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 8.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    final bg = Paint()
      ..color = const Color(0xFF2A2D33)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final fg = Paint()
      ..shader = const SweepGradient(
        colors: [
          AppColors.orange,
          AppColors.orangeSoft,
          AppColors.orange,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2,
      false,
      bg,
    );

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0).toDouble(),
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _AppBackground extends StatelessWidget {
  const _AppBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF111318),
            Color(0xFF070809),
            Color(0xFF030405),
          ],
          stops: [0, .42, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -170,
            right: -120,
            child: _AmbientGlow(size: 360, color: Color(0x24FF7418)),
          ),
          Positioned(
            top: 300,
            left: -210,
            child: _AmbientGlow(size: 330, color: Color(0x105F6B7A)),
          ),
          Positioned(
            right: -180,
            bottom: 120,
            child: _AmbientGlow(size: 300, color: Color(0x14FF8A24)),
          ),
          Positioned.fill(child: _ChromeBackgroundLines()),
        ],
      ),
    );
  }
}

class _ChromeBackgroundLines extends StatelessWidget {
  const _ChromeBackgroundLines();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _ChromeBackgroundPainter()),
    );
  }
}

class _ChromeBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final silver = Paint()
      ..color = const Color(0x0BFFFFFF)
      ..strokeWidth = .7;
    final warm = Paint()
      ..color = const Color(0x10FF7418)
      ..strokeWidth = 1;

    canvas.drawLine(Offset(-40, size.height * .18), Offset(size.width * .72, -30), silver);
    canvas.drawLine(Offset(size.width * .22, size.height), Offset(size.width + 40, size.height * .56), silver);
    canvas.drawLine(Offset(size.width * .66, -20), Offset(size.width + 30, size.height * .28), warm);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AmbientGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _AmbientGlow({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 115,
            spreadRadius: 44,
          ),
        ],
      ),
    );
  }
}

BoxDecoration _premiumDecoration({
  Color accent = AppColors.orange,
  double radius = 28,
}) {
  return BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF22252A),
        Color(0xFF101216),
        Color(0xFF060709),
        Color(0xFF020304),
      ],
      stops: [0, .22, .63, 1],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: const Color(0xFF4B5057),
      width: .72,
    ),
    boxShadow: [
      const BoxShadow(
        color: Color(0xD0000000),
        blurRadius: 25,
        offset: Offset(0, 13),
      ),
      BoxShadow(
        color: accent.withValues(alpha: .13),
        blurRadius: 22,
        spreadRadius: -6,
      ),
      const BoxShadow(
        color: Color(0x16FFFFFF),
        blurRadius: 1,
        offset: Offset(-1, -1),
      ),
    ],
  );
}

void _showFeatureStub(
  BuildContext context,
  String title,
  String text,
) {
  HapticFeedback.selectionClick();

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: BoxDecoration(
          color: const Color(0xFF111318),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.line),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSoft,
                height: 1.45,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.orangeSoft,
                  side: const BorderSide(
                    color: Color(0xFF4A3320),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                child: const Text(
                  'Понятно',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

void _showEmployees(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.55,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, controller) {
          const employees = [
            ('Администратор', 'Администратор', true),
            ('Сергей', 'Водитель', true),
            ('Алексей', 'Водитель', true),
            ('Грузчик', 'Грузчик', true),
          ];

          return Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF101216),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.line),
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(18),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Сотрудники',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _StatusPill(
                      text: '4',
                      color: AppColors.violet,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Пока это визуальный каркас. Следующим этапом подключим реальные app_users и права доступа с сервера.',
                  style: TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                ...employees.map(
                  (employee) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          const _SquareIcon(
                            icon: Icons.person_outline_rounded,
                            color: AppColors.violet,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  employee.$1,
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  employee.$2,
                                  style: const TextStyle(
                                    color: AppColors.textSoft,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const _GlowDot(
                            color: AppColors.orange,
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
    },
  );
}
