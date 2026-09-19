import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_role.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

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
        label: 'Статистика',
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
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
      HomePage(session: widget.session),
      WorkPage(session: widget.session),
      const SizedBox.shrink(),
      InvoicesPage(session: widget.session),
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
          const _AppBackground(),
          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _index,
              children: pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNavigation(
        items: items,
        index: _index,
        onChanged: (value) {
          if (widget.session.role != AppRole.loader && value == 2) {
            _openQuickAdd();
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
    final topRect = Rect.fromLTWH(0, 0, size.width, 3.5);
    final line = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x00FFFFFF),
          Color(0x80FFFFFF),
          Color(0xFFFF7418),
          Color(0x5AFFFFFF),
          Color(0x00FFFFFF),
        ],
        stops: [0, .22, .50, .72, 1],
      ).createShader(topRect);
    canvas.drawRect(topRect, line);

    final glow = Paint()
      ..color = const Color(0x32FF7418)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRect(
      Rect.fromLTWH(size.width * .28, -1, size.width * .44, 5),
      glow,
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


class HomePage extends StatelessWidget {
  final AppSession session;

  const HomePage({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 26),
      children: [
        _HomeTopBar(session: session),
        const SizedBox(height: 10),
        const _HomeTruckHero(),
        const SizedBox(height: 8),
        _HomeSalaryCard(onTap: () => _showSalarySheet(context)),
        const SizedBox(height: 8),
        const _HomeTonnageCard(),
        const SizedBox(height: 8),
        _HomePaidRoutesCard(
          onTap: () => _showPaidRoutesSheet(context),
        ),
        const SizedBox(height: 8),
        const _HomeMaintenanceCard(),
        const SizedBox(height: 8),
        const _HomeDynamicsCard(),
      ],
    );
  }
}





class _HomeTopBar extends StatelessWidget {
  final AppSession session;

  const _HomeTopBar({
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Row(
        children: [
          _ChromeIconButton(
            icon: Icons.menu_rounded,
            onTap: () => _openHomeMenu(context, session),
          ),
          const SizedBox(width: 10),
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
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Доброе утро, водитель!',
                  style: TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          _HomeSearchButton(session: session),
          const SizedBox(width: 7),
          _ChromeIconButton(
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




class _HomeSearchButton extends StatelessWidget {
  final AppSession session;

  const _HomeSearchButton({
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return _ChromeIconButton(
      icon: Icons.search_rounded,
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SearchPage(session: session),
          ),
        );
      },
    );
  }
}




class _HomeTruckHero extends StatelessWidget {
  const _HomeTruckHero();

  @override
  Widget build(BuildContext context) {
    return _ChromeImageCard(
      height: 205,
      imageAsset: 'assets/images/home_truck.jpg',
      radius: 25,
      child: Stack(
        children: [
          const Positioned(
            left: 15,
            top: 15,
            child: Text(
              'Заработок за сентябрь',
              style: TextStyle(
                color: AppColors.textSoft,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Positioned(
            left: 15,
            bottom: 47,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '312 105,8 ₸',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 31,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.1,
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'из ',
                      style: TextStyle(color: AppColors.textSoft, fontSize: 10),
                    ),
                    Text(
                      '354 000 ₸',
                      style: TextStyle(
                        color: AppColors.orangeSoft,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Text(
                  '+18 600 ₸ к прошлому месяцу',
                  style: TextStyle(
                    color: Color(0xFF61E37B),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            right: 16,
            bottom: 29,
            child: _HomeSalaryRing(),
          ),
        ],
      ),
    );
  }
}






class _HomeSalaryCard extends StatelessWidget {
  final VoidCallback onTap;

  const _HomeSalaryCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LuxuryMetricTile(
            label: 'Рейсы',
            value: '29',
            note: 'сегодня',
            delta: '+12%',
            icon: Icons.local_shipping_outlined,
            accent: AppColors.orange,
            onTap: onTap,
          ),
        ),
        const SizedBox(width: 7),
        const Expanded(
          child: _LuxuryMetricTile(
            label: 'Пробег',
            value: '184 км',
            note: 'за месяц',
            delta: '+8%',
            icon: Icons.route_rounded,
            accent: AppColors.blue,
          ),
        ),
        const SizedBox(width: 7),
        const Expanded(
          child: _LuxuryMetricTile(
            label: 'Направления',
            value: '2',
            note: 'сегодня',
            delta: '',
            icon: Icons.alt_route_rounded,
            accent: AppColors.amber,
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
      width: 104,
      height: 104,
      child: CustomPaint(
        painter: _HomeRingPainter(
          progress: 0.88,
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '88%',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'план',
                style: TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 8,
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

  _HomeRingPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 10.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    final bg = Paint()
      ..color = const Color(0xFF2C2D30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final fg = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFF5E00),
          Color(0xFFFF8B18),
          Color(0xFFFFB84A),
          Color(0xFFFF5E00),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

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
      math.pi * 2 * progress,
      false,
      fg,
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
    return _ChromeGlassSurface(
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      accent: AppColors.orange,
      child: const Row(
        children: [
          _ChromeMiniIcon(icon: Icons.build_outlined, color: AppColors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'БЛИЖАЙШЕЕ ТО',
                  style: TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Через 5 406 км',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: AppColors.orange, size: 24),
        ],
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
          child: _HomeGaugeCard(
            title: 'Тоннаж',
            value: '99 882',
            unit: 'кг',
            progress: .72,
            icon: Icons.scale_outlined,
            accent: AppColors.orange,
            leftCaption: 'Город 59%',
            rightCaption: 'Район 41%',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _HomeGaugeCard(
            title: 'Топливо',
            value: '1 545',
            unit: 'л газа',
            progress: .63,
            icon: Icons.local_gas_station_rounded,
            accent: AppColors.orange,
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
    const values = [0.26, 0.48, 0.42, 0.68, 0.53, 0.76, 0.45, 0.61, 0.69, 0.58, 0.78, 0.92];

    return _ChromeGlassSurface(
      radius: 23,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      child: Column(
        children: [
          const Row(
            children: [
              Text(
                'ДИНАМИКА ДОХОДА',
                style: TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
              Spacer(),
              _ChromeChip(text: 'Доход'),
              SizedBox(width: 7),
              Text('Сентябрь 2026', style: TextStyle(color: AppColors.textDim, fontSize: 8)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 118,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (index) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      height: 92 * values[index],
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFFB35A),
                            Color(0xFFFF7418),
                            Color(0xFF9B3B00),
                          ],
                        ),
                        boxShadow: const [
                          BoxShadow(color: Color(0x55FF7418), blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 7),
          const Row(
            children: [
              Text('1 нед', style: TextStyle(color: AppColors.textDim, fontSize: 7.5)),
              Spacer(),
              Text('2 нед', style: TextStyle(color: AppColors.textDim, fontSize: 7.5)),
              Spacer(),
              Text('3 нед', style: TextStyle(color: AppColors.textDim, fontSize: 7.5)),
              Spacer(),
              Text('4 нед', style: TextStyle(color: AppColors.textDim, fontSize: 7.5)),
            ],
          ),
        ],
      ),
    );
  }
}




BoxDecoration _homePanelDecoration({
  required double radius,
  Color borderColor = AppColors.line,
  Color glow = const Color(0x14000000),
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
    boxShadow: [
      const BoxShadow(
        color: Color(0xB8000000),
        blurRadius: 22,
        offset: Offset(0, 12),
      ),
      BoxShadow(color: glow, blurRadius: 22, spreadRadius: -3),
      const BoxShadow(
        color: Color(0x2AFFFFFF),
        blurRadius: 1,
        offset: Offset(-1, -1),
      ),
    ],
  );
}

Future<void> _openHomeMenu(
  BuildContext context,
  AppSession session,
) async {
  HapticFeedback.selectionClick();

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        decoration: _homePanelDecoration(
          radius: 28,
          borderColor: const Color(0xFF4A3425),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF34363A),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.grain_rounded,
                    color: AppColors.orange,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'ТАМЕРЛАН',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  Text(
                    session.role.title,
                    style: const TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (session.role == AppRole.admin)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.groups_2_outlined,
                    color: AppColors.orange,
                  ),
                  title: const Text('Сотрудники'),
                  subtitle: const Text('Водители, грузчики, доступы'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEmployees(context);
                  },
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.orange,
                ),
                title: const Text('Настройки'),
                subtitle: const Text('Интерфейс, звук, уведомления'),
                onTap: () {
                  Navigator.pop(context);
                  _showFeatureStub(
                    context,
                    'Настройки',
                    'Этот раздел подключим после Главной.',
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
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

) {
  _showHomeSheet(
    context,
    title: title,
    icon: icon,
    maxHeightFactor: 0.67,
    child: Column(
      children: [
        _HomeSheetHeader(
          columns: headers,
          flexes: const [2, 3],
        ),
        ...rows.map(
          (row) => _HomeSheetRow(
            cells: [row.$1, row.$2],
            flexes: const [2, 3],
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


class _HomePaidRoutesCard extends StatelessWidget {
  final VoidCallback onTap;

  const _HomePaidRoutesCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ChromeGlassSurface(
      radius: 21,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      onTap: onTap,
      child: const Row(
        children: [
          _ChromeMiniIcon(icon: Icons.alt_route_rounded, color: AppColors.orange),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ПЛАТНЫЕ НАПРАВЛЕНИЯ',
                  style: TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '3 рейса',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+ 9 000 ₸',
            style: TextStyle(
              color: AppColors.orangeSoft,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(width: 5),
          Icon(Icons.chevron_right_rounded, color: AppColors.orange, size: 21),
        ],
      ),
    );
  }
}


class _LuxuryMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String note;
  final String delta;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  const _LuxuryMetricTile({
    required this.label,
    required this.value,
    required this.note,
    required this.delta,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ChromeGlassSurface(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(11, 10, 10, 9),
      accent: accent,
      onTap: onTap,
      child: SizedBox(
        height: 94,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: _NeonIcon(
                icon: icon,
                color: accent,
                size: 18,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
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
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.45,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      note,
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 7.4,
                      ),
                    ),
                    if (delta.isNotEmpty) ...[
                      const Spacer(),
                      Text(
                        delta,
                        style: const TextStyle(
                          color: Color(0xFF55E66B),
                          fontSize: 7.8,
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
    );
  }
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


class _HomeGaugeCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final double progress;
  final IconData icon;
  final Color accent;
  final String leftCaption;
  final String rightCaption;
  final VoidCallback? onTap;

  const _HomeGaugeCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.progress,
    required this.icon,
    required this.accent,
    required this.leftCaption,
    required this.rightCaption,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ChromeGlassSurface(
      radius: 23,
      padding: const EdgeInsets.fromLTRB(11, 11, 11, 10),
      accent: accent,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .7,
                ),
              ),
              const Spacer(),
              Icon(icon, color: accent, size: 18),
            ],
          ),
          const SizedBox(height: 7),
          Center(
            child: SizedBox(
              width: 104,
              height: 104,
              child: CustomPaint(
                painter: _ChromeGaugePainter(
                  progress: progress,
                  accent: accent,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.5,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        unit,
                        style: const TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 7.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  leftCaption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSoft, fontSize: 7.5),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  rightCaption,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textDim, fontSize: 7.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChromeGaugePainter extends CustomPainter {
  final double progress;
  final Color accent;

  const _ChromeGaugePainter({
    required this.progress,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 9;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final shadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = const Color(0xFF353941);
    canvas.drawArc(rect, -math.pi * .75, math.pi * 1.5, false, shadow);

    final chrome = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFB9BDC4),
          Color(0xFF353941),
          Color(0xFF0A0B0D),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi * .75, math.pi * .27, false, chrome);

    final glow = Paint()
      ..color = accent.withValues(alpha: .28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi * .75, math.pi * 1.5 * progress, false, glow);

    final active = Paint()
      ..shader = LinearGradient(
        colors: [
          Color.lerp(accent, Colors.white, .35)!,
          accent,
          const Color(0xFFFF4F00),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi * .75, math.pi * 1.5 * progress, false, active);
  }

  @override
  bool shouldRepaint(covariant _ChromeGaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.accent != accent;
  }
}

class _ChromeChip extends StatelessWidget {
  final String text;

  const _ChromeChip({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF373B42), Color(0xFF111316)],
        ),
        border: Border.all(color: const Color(0xFF955A2B), width: .7),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.orangeSoft,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ChromeMiniIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _ChromeMiniIcon({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF42464E),
            Color(0xFF1A1D21),
            Color(0xFF07080A),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: .65), width: .8),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .16), blurRadius: 13),
        ],
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

class _ChromeIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  const _ChromeIconButton({
    required this.icon,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: _ChromeGlassSurface(
                radius: 16,
                padding: EdgeInsets.zero,
                child: Icon(icon, color: AppColors.text, size: 23),
              ),
            ),
            if (showDot)
              const Positioned(
                right: 2,
                top: 1,
                child: _GlowDot(color: AppColors.orange),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChromeImageCard extends StatelessWidget {
  final double height;
  final String imageAsset;
  final double radius;
  final Widget child;

  const _ChromeImageCard({
    required this.height,
    required this.imageAsset,
    required this.radius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0xA8000000),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
          BoxShadow(
            color: Color(0x50FF7418),
            blurRadius: 22,
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(imageAsset, fit: BoxFit.cover, alignment: Alignment.center),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Color(0x18000000),
                    Color(0x55000000),
                    Color(0xE80A0A0B),
                  ],
                  stops: [0, .43, 1],
                ),
              ),
            ),
            const _ChromeCornerBurn(radius: 25),
            child,
          ],
        ),
      ),
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
            color: Color(0xD3000000),
            blurRadius: 26,
            offset: Offset(0, 14),
          ),
          BoxShadow(
            color: accent.withValues(alpha: .18),
            blurRadius: 22,
            spreadRadius: -6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: CustomPaint(
            foregroundPainter: _LuxuryChromeFramePainter(
              radius: radius,
              accent: accent,
            ),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xCC4A4F57),
                    Color(0xE526292F),
                    Color(0xF20B0D10),
                    Color(0xFC020304),
                  ],
                  stops: [0, .16, .56, 1],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: const Alignment(-.95, -.85),
                            end: const Alignment(.65, .50),
                            colors: [
                              Colors.white.withValues(alpha: .14),
                              Colors.white.withValues(alpha: .035),
                              Colors.transparent,
                              Colors.transparent,
                            ],
                            stops: const [0, .11, .31, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -34,
                    right: -50,
                    child: IgnorePointer(
                      child: Container(
                        width: 145,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(80),
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: .13),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  child,
                ],
              ),
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



class _ChromeCornerBurn extends StatelessWidget {
  final double radius;
  final Color accent;

  const _ChromeCornerBurn({
    required this.radius,
    this.accent = AppColors.orange,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ChromeCornerPainter(
          radius: radius,
          accent: accent,
        ),
      ),
    );
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
    final outerRect = Rect.fromLTWH(.8, .8, size.width - 1.6, size.height - 1.6);
    final outer = RRect.fromRectAndRadius(
      outerRect,
      Radius.circular(radius),
    );

    // 1) Cold polished metal perimeter.
    final chrome = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFE9EDF2),
          Color(0xFF555B63),
          Color(0xFF16191D),
          Color(0xFFA2A8B0),
          Color(0xFF25292E),
          Color(0xFFF4F6F8),
        ],
        stops: [0, .16, .33, .55, .76, 1],
      ).createShader(outerRect);
    canvas.drawRRect(outer, chrome);

    // 2) Inner glass bevel.
    final innerRect = outerRect.deflate(2.2);
    final inner = RRect.fromRectAndRadius(
      innerRect,
      Radius.circular(math.max(2, radius - 2)),
    );
    final innerLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .75
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x9AFFFFFF),
          Color(0x22FFFFFF),
          Color(0x20000000),
          Color(0x7A000000),
        ],
      ).createShader(innerRect);
    canvas.drawRRect(inner, innerLine);

    // 3) Warm orange electric edge that does not wrap uniformly.
    final hotGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: .68)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);

    final hotLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.45
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(accent, Colors.white, .12)!;

    // Top-left burn.
    canvas.drawArc(
      Rect.fromLTWH(-8, -8, 72, 72),
      math.pi * .96,
      math.pi * .58,
      false,
      hotGlow,
    );
    canvas.drawArc(
      Rect.fromLTWH(-8, -8, 72, 72),
      math.pi * .96,
      math.pi * .58,
      false,
      hotLine,
    );

    // Bottom-right burn.
    canvas.drawArc(
      Rect.fromLTWH(size.width - 66, size.height - 66, 74, 74),
      -math.pi * .10,
      math.pi * .62,
      false,
      hotGlow,
    );
    canvas.drawArc(
      Rect.fromLTWH(size.width - 66, size.height - 66, 74, 74),
      -math.pi * .10,
      math.pi * .62,
      false,
      hotLine,
    );

    // Small mid-edge hot spots like reflected light.
    final edgeGlow = Paint()
      ..color = accent.withValues(alpha: .50)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * .64, 1.5),
      Offset(size.width * .83, 1.5),
      edgeGlow,
    );
    canvas.drawLine(
      Offset(1.5, size.height * .63),
      Offset(1.5, size.height * .78),
      edgeGlow,
    );

    // 4) White glass reflection on top-left.
    final reflection = Paint()
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [
          Color(0xC9FFFFFF),
          Color(0x4AFFFFFF),
          Color(0x00FFFFFF),
        ],
      ).createShader(Rect.fromLTWH(12, 0, size.width * .55, 8));

    canvas.drawLine(
      const Offset(18, 2.5),
      Offset(math.max(20, size.width * .48), 2.5),
      reflection,
    );
  }

  @override
  bool shouldRepaint(covariant _LuxuryChromeFramePainter oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.accent != accent;
  }
}


class _ChromeCornerPainter extends CustomPainter {
  final double radius;
  final Color accent;

  const _ChromeCornerPainter({
    required this.radius,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _LuxuryChromeFramePainter(
      radius: radius,
      accent: accent,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _ChromeCornerPainter oldDelegate) {
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


Future<void> _showQuickAddMenu(
  BuildContext context,
  AppSession session,
) async {
  final rootContext = context;

  await Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: .88),
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (routeContext, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: .982, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: _QuickAddMenu(
              onTrip: () {
                Navigator.of(routeContext).pop();
                Future<void>.delayed(
                  const Duration(milliseconds: 80),
                  () => _openTripEntry(rootContext),
                );
              },
              onFuel: () {
                Navigator.of(routeContext).pop();
                Future<void>.delayed(
                  const Duration(milliseconds: 80),
                  () => _openFuelEntry(rootContext),
                );
              },
              onInvoice: () {
                Navigator.of(routeContext).pop();
                Future<void>.delayed(
                  const Duration(milliseconds: 80),
                  () {
                    Navigator.of(rootContext).push(
                      MaterialPageRoute<void>(
                        builder: (_) => InvoicesPage(session: session),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    ),
  );
}






class _QuickAddMenu extends StatelessWidget {
  final VoidCallback onTrip;
  final VoidCallback onFuel;
  final VoidCallback onInvoice;

  const _QuickAddMenu({
    required this.onTrip,
    required this.onFuel,
    required this.onInvoice,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/home_truck.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0x3B000000),
                  Color(0xB40A0B0D),
                  Color(0xF6020304),
                ],
                stops: [0, .43, 1],
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: const SizedBox.expand(),
          ),
          CustomPaint(
            foregroundPainter: const _FullScreenChromePainter(),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(17, 13, 17, 15),
                child: Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.of(context).pop(),
                          child: const SizedBox(
                            width: 42,
                            height: 42,
                            child: Icon(
                              Icons.close_rounded,
                              color: AppColors.text,
                              size: 29,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Новое действие',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(flex: 1),
                    const Text(
                      'Что добавить?',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.9,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Выберите тип действия',
                      style: TextStyle(
                        color: AppColors.textSoft,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _QuickActionOrb(
                      icon: Icons.local_shipping_outlined,
                      title: 'Рейс',
                      subtitle: 'Добавить новый рейс',
                      onTap: onTrip,
                    ),
                    const SizedBox(height: 12),
                    _QuickActionOrb(
                      icon: Icons.local_gas_station_rounded,
                      title: 'Топливо',
                      subtitle: 'Добавить заправку',
                      onTap: onFuel,
                    ),
                    const SizedBox(height: 12),
                    _QuickActionOrb(
                      icon: Icons.receipt_long_outlined,
                      title: 'Накладная',
                      subtitle: 'Создать накладную',
                      onTap: onInvoice,
                    ),
                    const Spacer(flex: 1),
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: const _ChromeCloseOrb(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}







class _QuickActionOrb extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionOrb({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: SizedBox(
        width: 158,
        height: 158,
        child: CustomPaint(
          painter: const _ChromeOrbPainter(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 26,
                right: 26,
                top: 17,
                height: 42,
                child: IgnorePointer(
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(
                        Radius.elliptical(90, 36),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x85FFFFFF),
                          Color(0x22FFFFFF),
                          Color(0x00FFFFFF),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NeonIcon(
                    icon: icon,
                    color: AppColors.orange,
                    size: 35,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}






void _openTripEntry(BuildContext context) {
showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const _TripEntrySheet(),
  );
}




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
    final outerR = size.width / 2 - 4;
    final orbRect = Rect.fromCircle(center: c, radius: outerR);

    final glow = Paint()
      ..color = const Color(0x72FF7418)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(c, outerR - 1, glow);

    final deepShadow = Paint()
      ..color = const Color(0xCC000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13);
    canvas.drawCircle(Offset(c.dx, c.dy + 7), outerR - 9, deepShadow);

    final fill = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-.36, -.42),
        radius: 1.0,
        colors: [
          Color(0xFF6C7179),
          Color(0xFF383C43),
          Color(0xFF15181D),
          Color(0xFF050607),
        ],
        stops: [0, .23, .60, 1],
      ).createShader(orbRect);
    canvas.drawCircle(c, outerR - 10, fill);

    final wideChrome = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFF777D85),
          Color(0xFF101216),
          Color(0xFFFF7A1A),
          Color(0xFF353940),
          Color(0xFFF7F8FA),
        ],
        stops: [0, .17, .38, .60, .79, 1],
      ).createShader(orbRect);
    canvas.drawCircle(c, outerR - 10, wideChrome);

    final innerRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..color = const Color(0xA8FFFFFF);
    canvas.drawCircle(c, outerR - 16, innerRing);

    final orangeGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xB5FF7418)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: outerR - 12),
      math.pi * .09,
      math.pi * .84,
      false,
      orangeGlow,
    );

    final orangeLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFF8C36);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: outerR - 12),
      math.pi * .09,
      math.pi * .84,
      false,
      orangeLine,
    );

    final highlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xD7FFFFFF);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: outerR - 14),
      math.pi * 1.10,
      math.pi * .37,
      false,
      highlight,
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
  String _type = 'Город';
  String _direction = 'Петропавловск';

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
          const SizedBox(height: 18),
          _QuickSaveButton(
            text: 'Добавить рейс',
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

void _openFuelEntry(BuildContext context) {
showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const _FuelEntrySheet(),
  );
}

class _FuelEntrySheet extends StatefulWidget {
  const _FuelEntrySheet();

  @override
  State<_FuelEntrySheet> createState() => _FuelEntrySheetState();
}

class _FuelEntrySheetState extends State<_FuelEntrySheet> {
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
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _QuickEntryShell extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _QuickEntryShell({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF25282E),
                Color(0xFF101216),
                Color(0xFF070809),
              ],
              stops: [0, .38, 1],
            ),
            borderRadius: BorderRadius.all(Radius.circular(30)),
            border: Border.fromBorderSide(
              BorderSide(color: Color(0xFF6B4A32), width: .9),
            ),
            boxShadow: [
              BoxShadow(color: Color(0x99000000), blurRadius: 28, offset: Offset(0, -8)),
              BoxShadow(color: Color(0x24FF7418), blurRadius: 24),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A4B50),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A140F),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF5A361E),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSoft,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
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
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF25170E)
                      : const Color(0xFF151619),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: active
                        ? AppColors.orange
                        : AppColors.line,
                  ),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    color: active
                        ? AppColors.orange
                        : AppColors.textSoft,
                    fontWeight: FontWeight.w700,
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
          color: const Color(0xFF151619),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.line),
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
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.orange,
            ),
          ],
        ),
      ),
    );
  }
}

Future<String?> _pickQuickValue(
  BuildContext context,
  String title,
  List<String> values,
) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFF111215),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(28),
      ),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ...values.map(
                (value) => ListTile(
                  title: Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.text,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.orange,
                  ),
                  onTap: () => Navigator.pop(sheetContext, value),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

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
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textDim,
          fontSize: 14,
        ),
        filled: true,
        fillColor: const Color(0xFF151619),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: AppColors.line,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: AppColors.orange,
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
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.orange,
          side: const BorderSide(
            color: AppColors.orange,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}



class WorkPage extends StatelessWidget {
  final AppSession session;

  const WorkPage({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(9, 10, 9, 26),
      children: const [
        _PageHeader(
          title: 'Работа',
          subtitle: '',
          trailing: _StatusPill(
            text: 'На смене',
            color: Color(0xFF55E66B),
          ),
        ),
        SizedBox(height: 8),
        _WorkHero(),
        SizedBox(height: 8),
        _ShiftTimelineCard(),
        SizedBox(height: 8),
        _WorkGpsStrip(),
      ],
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



class _GaugePainter extends CustomPainter {
  final double progress;

  _GaugePainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );
    final radius = size.width / 2 - 8;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    final bg = Paint()
      ..color = const Color(0xFF2A2D33)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final fg = Paint()
      ..shader = const SweepGradient(
        colors: [
          AppColors.orange,
          AppColors.orangeSoft,
          AppColors.orange,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    const start = math.pi * 0.75;
    const sweep = math.pi * 1.5;

    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      bg,
    );

    canvas.drawArc(
      rect,
      start,
      sweep * progress.clamp(0.0, 1.0).toDouble(),
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
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
  const _MapRoundButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(-.3, -.3),
          colors: [Color(0xFF33373D), Color(0xFF111317), Color(0xFF070809)],
        ),
        boxShadow: [BoxShadow(color: Color(0x77000000), blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF555A62), width: .7),
        ),
        child: Icon(icon, color: AppColors.text, size: 18),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final minor = Paint()
      ..color = const Color(0xFF161D23)
      ..strokeWidth = .75;
    final major = Paint()
      ..color = const Color(0xFF273038)
      ..strokeWidth = 1.2;

    for (double x = -40; x < size.width + 40; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x + 85, size.height), minor);
    }
    for (double y = 18; y < size.height; y += 46) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 24), minor);
    }
    canvas.drawLine(Offset(0, size.height * .64), Offset(size.width, size.height * .35), major);
    canvas.drawLine(Offset(size.width * .22, 0), Offset(size.width * .72, size.height), major);

    final path = Path()
      ..moveTo(size.width * .12, size.height * .80)
      ..cubicTo(
        size.width * .23,
        size.height * .73,
        size.width * .24,
        size.height * .58,
        size.width * .39,
        size.height * .60,
      )
      ..cubicTo(
        size.width * .55,
        size.height * .62,
        size.width * .52,
        size.height * .40,
        size.width * .66,
        size.height * .42,
      )
      ..cubicTo(
        size.width * .79,
        size.height * .44,
        size.width * .77,
        size.height * .22,
        size.width * .88,
        size.height * .18,
      );

    final glow = Paint()
      ..color = const Color(0x66FF7418)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    final line = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFA14A), Color(0xFFFF7418), Color(0xFFFFB85A)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.3
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, glow);
    canvas.drawPath(path, line);

    final start = Offset(size.width * .12, size.height * .80);
    final finish = Offset(size.width * .88, size.height * .18);
    final markerPaint = Paint()..color = const Color(0xFFFF7418);
    canvas.drawCircle(start, 7, markerPaint);
    canvas.drawCircle(finish, 8, markerPaint);
    canvas.drawCircle(finish, 13, Paint()..color = const Color(0x33FF7418));
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
        Color(0xFF41464E),
        Color(0xFF24272D),
        Color(0xFF0C0E11),
        Color(0xFF030405),
      ],
      stops: [0, .13, .58, 1],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: const Color(0xFF676C74),
      width: .75,
    ),
    boxShadow: [
      const BoxShadow(
        color: Color(0xC0000000),
        blurRadius: 22,
        offset: Offset(0, 12),
      ),
      BoxShadow(
        color: accent.withValues(alpha: .14),
        blurRadius: 22,
        spreadRadius: -4,
      ),
      const BoxShadow(
        color: Color(0x38FFFFFF),
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
