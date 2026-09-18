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
        _NavItem(label: 'Смена', icon: Icons.schedule_outlined, activeIcon: Icons.schedule_rounded),
        _NavItem(label: 'История', icon: Icons.history_outlined, activeIcon: Icons.history_rounded),
      ];
    }

    return const [
      _NavItem(label: 'Главная', icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
      _NavItem(label: 'Работа', icon: Icons.local_shipping_outlined, activeIcon: Icons.local_shipping_rounded),
      _NavItem(label: '', icon: Icons.add_rounded, activeIcon: Icons.add_rounded),
      _NavItem(label: 'Накладные', icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded),
      _NavItem(label: 'Статистика', icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded),
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
      InvoicesPage(session: widget.session),
      StatisticsPage(session: widget.session),
    ];
  }

  int get _pageIndex {
    if (widget.session.role == AppRole.loader) return _index;
    if (_index <= 1) return _index;
    if (_index == 3) return 2;
    if (_index == 4) return 3;
    return 0;
  }

  void _openQuickAdd() {
    HapticFeedback.mediumImpact();
    _showQuickAddSheet(context);
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
              index: _pageIndex,
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
    final hasCenterAdd = items.length == 5 && items[2].label.isEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFA090B0E),
        border: Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(color: Colors.black, blurRadius: 26, offset: Offset(0, -8)),
        ],
      ),
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 7,
        bottom: MediaQuery.paddingOf(context).bottom + 7,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(items.length, (i) {
          final item = items[i];
          final center = hasCenterAdd && i == 2;
          final active = !center && i == index;

          if (center) {
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: Transform.translate(
                  offset: const Offset(0, -9),
                  child: Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF17120E),
                        border: Border.all(color: AppColors.orange, width: 1.4),
                        boxShadow: const [
                          BoxShadow(color: Color(0x66FF7818), blurRadius: 22),
                          BoxShadow(color: Colors.black, blurRadius: 12, offset: Offset(0, 6)),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded, color: AppColors.orange, size: 32),
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 190),
                curve: Curves.easeOutCubic,
                height: 58,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF19150F) : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: active ? Border.all(color: const Color(0xFF49301B)) : null,
                  boxShadow: active
                      ? const [BoxShadow(color: Color(0x33FF7818), blurRadius: 16)]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      active ? item.activeIcon : item.icon,
                      size: 22,
                      color: active ? AppColors.orange : AppColors.textDim,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      maxLines: 1,
                      style: TextStyle(
                        color: active ? AppColors.orange : AppColors.textDim,
                        fontSize: 9.2,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
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
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
      children: [
        _HomeTopBar(session: session),
        const SizedBox(height: 14),
        const Divider(
          height: 1,
          color: Color(0xFF2A2119),
        ),
        const SizedBox(height: 16),
        const _HomeTitleRow(),
        const SizedBox(height: 14),
        const _HomeMonthSelector(),
        const SizedBox(height: 14),
        const _HomeTruckHero(),
        const SizedBox(height: 14),
        _HomeSalaryCard(
          onTap: () => _showSalarySheet(context),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _HomeTile(
                title: 'ПРОБЕГ ЗА МЕСЯЦ',
                value: '0 км',
                icon: Icons.route_rounded,
                accent: AppColors.green,
                footer: const _HomeThinLine(
                  color: AppColors.green,
                  progress: 0.98,
                ),
                onTap: () => _showMileageSheet(context),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: _HomeTile(
                title: 'РЕЙСОВ ВЫПОЛНЕНО',
                value: '29',
                subtitle: 'рейса',
                icon: Icons.local_shipping_outlined,
                accent: AppColors.orange,
                footer: _HomeDots(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _HomeTile(
                title: 'ГОРОД',
                value: '58 800 кг',
                subtitle: '59%',
                icon: Icons.location_city_rounded,
                accent: AppColors.green,
                footer: const _HomeProgressBar(
                  color: AppColors.green,
                  progress: 0.59,
                ),
                onTap: () => _showCitySheet(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HomeTile(
                title: 'РАЙОН',
                value: '41 082 кг',
                subtitle: '41%',
                icon: Icons.terrain_rounded,
                accent: AppColors.orange,
                footer: const _HomeProgressBar(
                  color: AppColors.orange,
                  progress: 0.41,
                ),
                onTap: () => _showDistrictSheet(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _HomeSmallTile(
                title: '🔥 ГАЗ',
                value: '1 545 л',
                subtitle: 'за месяц',
                icon: Icons.local_gas_station_outlined,
                accent: AppColors.blue,
                onTap: () => _showGasSheet(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HomeSmallTile(
                title: '⛽ БЕНЗИН',
                value: '20 л',
                subtitle: 'за месяц',
                icon: Icons.local_gas_station_rounded,
                accent: AppColors.violet,
                onTap: () => _showPetrolSheet(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HomeSmallTile(
                title: 'ПЛАТНЫЕ\nНАПРАВЛЕНИЯ',
                value: '3',
                subtitle: 'рейсов',
                icon: Icons.route_outlined,
                accent: AppColors.green,
                onTap: () => _showPaidRoutesSheet(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _HomeMaintenanceCard(),
        const SizedBox(height: 12),
        const _HomeTonnageCard(),
        const SizedBox(height: 12),
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
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openHomeMenu(context, session),
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              Icons.menu_rounded,
              color: AppColors.text,
              size: 34,
            ),
          ),
        ),
        const Spacer(),
        _HomeSearchButton(session: session),
        const SizedBox(width: 8),
        const _HomeShiftPill(),
      ],
    );
  }
}

class _HomeSearchButton extends StatelessWidget {
  final AppSession session;
  const _HomeSearchButton({required this.session});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              body: Stack(
                children: [
                  const _AppBackground(),
                  SafeArea(child: SearchPage(session: session)),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xB5121418),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFF35271D)),
        ),
        child: const Icon(Icons.search_rounded, color: AppColors.textSoft, size: 23),
      ),
    );
  }
}

class _HomeShiftPill extends StatelessWidget {
  const _HomeShiftPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1710),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF2D7D3E),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3328D951),
            blurRadius: 16,
          ),
        ],
      ),
      child: const Row(
        children: [
          _GlowDot(color: Color(0xFF60E765)),
          SizedBox(width: 9),
          Text(
            'На смене',
            style: TextStyle(
              color: Color(0xFFA9EBAE),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTitleRow extends StatelessWidget {
  const _HomeTitleRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Главная',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 31,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.0,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Текущий месяц',
                style: TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        _HomeDatePill(),
      ],
    );
  }
}

class _HomeDatePill extends StatelessWidget {
  const _HomeDatePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF111113),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF9A4B18),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.calendar_month_rounded,
            color: AppColors.orangeSoft,
            size: 16,
          ),
          SizedBox(width: 7),
          Text(
            '18.09.2026',
            style: TextStyle(
              color: AppColors.orangeSoft,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeMonthSelector extends StatelessWidget {
  const _HomeMonthSelector();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HomeArrowButton(
          icon: Icons.chevron_left_rounded,
          onTap: () => _showFeatureStub(
            context,
            'Месяц',
            'Переключение месяцев подключим вместе с реальными данными.',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: _homePanelDecoration(
              radius: 18,
              borderColor: const Color(0xFF493224),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_view_month_rounded,
                  size: 14,
                  color: AppColors.textSoft,
                ),
                SizedBox(width: 7),
                Text(
                  'сентябрь 2026 г.',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _HomeArrowButton(
          icon: Icons.chevron_right_rounded,
          muted: true,
          onTap: null,
        ),
      ],
    );
  }
}

class _HomeArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool muted;

  const _HomeArrowButton({
    required this.icon,
    required this.onTap,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 48,
        height: 52,
        decoration: _homePanelDecoration(
          radius: 18,
          borderColor: muted
              ? const Color(0xFF202228)
              : const Color(0xFF493224),
        ),
        child: Icon(
          icon,
          color: muted
              ? const Color(0xFF343840)
              : AppColors.textSoft,
        ),
      ),
    );
  }
}

class _HomeTruckHero extends StatelessWidget {
  const _HomeTruckHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFBA5B1D),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2AFF7418),
            blurRadius: 22,
          ),
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/home_truck.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0x16000000),
                    Color(0xD0000000),
                  ],
                  stops: [0, 0.58, 1],
                ),
              ),
            ),
            Positioned(
              left: 18,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xC90B100B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF5D3C1F),
                  ),
                ),
                child: const Row(
                  children: [
                    _GlowDot(color: Color(0xFF50AE2E)),
                    SizedBox(width: 9),
                    Text(
                      'Смена активна',
                      style: TextStyle(
                        color: Color(0xFF8FAF69),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
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
}

class _HomeSalaryCard extends StatelessWidget {
  final VoidCallback onTap;

  const _HomeSalaryCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(27),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 154,
        padding: const EdgeInsets.all(16),
        decoration: _homePanelDecoration(
          radius: 27,
          borderColor: const Color(0xFF4A3425),
          glow: const Color(0x1FFF7418),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ЗАРПЛАТА ЗА СЕНТЯБРЬ 2026 Г.',
                    style: TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '312 105,8 ₸',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '154 / 176 ч',
                    style: TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 11,
                    ),
                  ),
                  Spacer(),
                  _HomeSalaryProgress(),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const _HomeSalaryRing(),
          ],
        ),
      ),
    );
  }
}

class _HomeSalaryProgress extends StatelessWidget {
  const _HomeSalaryProgress();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 7,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(100),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: 0.88,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF5C00),
                Color(0xFFFF8517),
                Color(0xFFFFC35A),
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55FF7418),
                blurRadius: 7,
              ),
            ],
          ),
        ),
      ),
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

class _HomeTile extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final Widget footer;
  final VoidCallback? onTap;

  const _HomeTile({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.accent,
    required this.footer,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: Container(
        height: 142,
        padding: const EdgeInsets.all(14),
        decoration: _homePanelDecoration(
          radius: 24,
          borderColor: const Color(0xFF4A3425),
          glow: accent.withValues(alpha: 0.05),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                icon,
                size: 23,
                color: accent,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 30),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.65,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 11,
                    ),
                  ),
                ],
                const Spacer(),
                footer,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSmallTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _HomeSmallTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 146,
        padding: const EdgeInsets.all(12),
        decoration: _homePanelDecoration(
          radius: 22,
          borderColor: const Color(0xFF473223),
          glow: accent.withValues(alpha: 0.05),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                icon,
                size: 20,
                color: accent,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 8.7,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 9.5,
                  ),
                ),
                const Spacer(),
                _HomeThinLine(
                  color: accent,
                  progress: 0.82,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeProgressBar extends StatelessWidget {
  final Color color;
  final double progress;

  const _HomeProgressBar({
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 7,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2B2D),
        borderRadius: BorderRadius.circular(100),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            gradient: LinearGradient(
              colors: [
                color,
                Color.lerp(color, Colors.white, 0.25)!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeThinLine extends StatelessWidget {
  final Color color;
  final double progress;

  const _HomeThinLine({
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Container(
          height: 2,
          color: const Color(0xFF222428),
        ),
        FractionallySizedBox(
          widthFactor: progress,
          child: Container(
            height: 2,
            color: color,
          ),
        ),
        Align(
          alignment: Alignment(progress * 2 - 1, 0),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 7,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeDots extends StatelessWidget {
  const _HomeDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        9,
        (index) => Padding(
          padding: const EdgeInsets.only(right: 7),
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.orange,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x55FF7418),
                  blurRadius: 7,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeMaintenanceCard extends StatelessWidget {
  const _HomeMaintenanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: _homePanelDecoration(
        radius: 24,
        borderColor: const Color(0xFF4B3423),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 54,
            child: Icon(
              Icons.handyman_outlined,
              color: Color(0xFFB5B8C0),
              size: 30,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'БЛИЖАЙШЕЕ ТО',
                  style: TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Через 5 406 км',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Добавь запись ТО',
                  style: TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_rounded,
            color: AppColors.orange,
            size: 28,
          ),
        ],
      ),
    );
  }
}

class _HomeTonnageCard extends StatelessWidget {
  const _HomeTonnageCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: _homePanelDecoration(
        radius: 25,
        borderColor: const Color(0xFF4A3425),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.balance_rounded,
                color: Color(0xFFADB0B6),
                size: 22,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Тоннаж по направлениям',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '99 882 кг',
                style: TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: SizedBox(
                  height: 145,
                  child: _HomeTonnageRing(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _HomeLegendRow(
                      color: AppColors.orange,
                      title: 'Город',
                      value: '58 800 кг (59%)',
                    ),
                    const SizedBox(height: 18),
                    _HomeLegendRow(
                      color: Color(0xFFFFC053),
                      title: 'Район',
                      value: '41 082 кг (41%)',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeTonnageRing extends StatelessWidget {
  const _HomeTonnageRing();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HomeTonnagePainter(),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '99 882',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'кг',
              style: TextStyle(
                color: AppColors.textSoft,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTonnagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 15.0;
    final d = math.min(size.width, size.height);
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: d / 2 - stroke,
    );

    final bg = Paint()
      ..color = const Color(0xFF24262A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final city = Paint()
      ..color = AppColors.orange
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeWidth = stroke;

    final district = Paint()
      ..color = const Color(0xFFFFC053)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeWidth = stroke;

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, bg);

    const gap = 0.055;
    const full = math.pi * 2;
    final citySweep = full * 0.59 - gap;
    final districtSweep = full * 0.41 - gap;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      citySweep,
      false,
      city,
    );

    canvas.drawArc(
      rect,
      -math.pi / 2 + citySweep + gap * 2,
      districtSweep,
      false,
      district,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HomeLegendRow extends StatelessWidget {
  final Color color;
  final String title;
  final String value;

  const _HomeLegendRow({
    required this.color,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
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
    const values = [
      0.05,
      0.82,
      0.28,
      0.61,
      0.90,
      0.39,
      0.51,
      0.68,
      0.36,
      0.58,
      0.60,
      1.0,
    ];
    const labels = [
      '01.09',
      '02.09',
      '03.09',
      '04.09',
      '07.09',
      '08.09',
      '09.09',
      '10.09',
      '11.09',
      '14.09',
      '15.09',
      '16.09',
    ];
    const numbers = [
      '0',
      '10 000',
      '3 462',
      '7 500',
      '10 954',
      '4 346',
      '5 781',
      '8 365',
      '4 000',
      '6 803',
      '7 000',
      '12 171',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: _homePanelDecoration(
        radius: 25,
        borderColor: const Color(0xFF4A3425),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Text(
                'Динамика тоннажа',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Spacer(),
              Text(
                'Месяц',
                style: TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 195,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(values.length, (index) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              numbers[index],
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                              style: const TextStyle(
                                color: AppColors.textSoft,
                                fontSize: 6.7,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 13,
                              height: 118 * values[index] + 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFFFFC263),
                                    Color(0xFFFF8D1A),
                                    Color(0xFFFF6500),
                                  ],
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x44FF7418),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              labels[index],
                              style: const TextStyle(
                                color: AppColors.textDim,
                                fontSize: 6.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
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
        Color(0xFF18191B),
        Color(0xFF0F1012),
      ],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: borderColor,
      width: 1,
    ),
    boxShadow: [
      const BoxShadow(
        color: Color(0x88000000),
        blurRadius: 22,
        offset: Offset(0, 11),
      ),
      BoxShadow(
        color: glow,
        blurRadius: 22,
      ),
      const BoxShadow(
        color: Color(0x552A1608),
        blurRadius: 2,
        offset: Offset(0, 4),
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

void _showMileageSheet(BuildContext context) {
  const rows = [
    ('09-18', '— км'),
    ('09-17', '0 км'),
    ('09-16', '0 км'),
    ('09-15', '0 км'),
    ('09-14', '0 км'),
    ('09-11', '0 км'),
    ('09-10', '0 км'),
    ('09-09', '0 км'),
    ('09-08', '0 км'),
    ('09-07', '0 км'),
    ('09-04', '0 км'),
    ('09-03', '0 км'),
    ('09-02', '0 км'),
    ('09-01', '0 км'),
  ];

  _showHomeTableSheet(
    context,
    title: 'Пробег по дням',
    icon: Icons.route_rounded,
    headers: const ['ДАТА', 'ПРОБЕГ'],
    rows: rows,
  );
}

void _showCitySheet(BuildContext context) {
  const rows = [
    ('09-18', '4 000 кг'),
    ('09-17', '13 500 кг'),
    ('09-16', '8 000 кг'),
    ('09-15', '3 500 кг'),
    ('09-14', '4 800 кг'),
    ('09-11', '0 кг'),
    ('09-10', '4 000 кг'),
    ('09-09', '3 500 кг'),
    ('09-08', '0 кг'),
    ('09-07', '7 500 кг'),
    ('09-04', '4 000 кг'),
    ('09-03', '0 кг'),
    ('09-02', '6 000 кг'),
    ('09-01', '0 кг'),
  ];

  _showHomeTableSheet(
    context,
    title: 'Город по дням',
    icon: Icons.location_city_rounded,
    headers: const ['ДАТА', 'ГОРОД'],
    rows: rows,
  );
}

void _showDistrictSheet(BuildContext context) {
  const rows = [
    ('09-18', '0 кг'),
    ('09-17', '2 000 кг'),
    ('09-16', '4 171 кг'),
    ('09-15', '3 500 кг'),
    ('09-14', '2 003 кг'),
    ('09-11', '4 000 кг'),
    ('09-10', '4 365 кг'),
    ('09-09', '2 281 кг'),
    ('09-08', '4 346 кг'),
    ('09-07', '3 454 кг'),
    ('09-04', '3 500 кг'),
    ('09-03', '3 462 кг'),
    ('09-02', '4 000 кг'),
    ('09-01', '0 кг'),
  ];

  _showHomeTableSheet(
    context,
    title: 'Район по дням',
    icon: Icons.terrain_rounded,
    headers: const ['ДАТА', 'РАЙОН'],
    rows: rows,
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

void _showPetrolSheet(BuildContext context) {
  const rows = [
    ['09-01', '11:52', '20 л'],
  ];

  _showHomeSheet(
    context,
    title: 'Бензин',
    icon: Icons.local_gas_station_rounded,
    maxHeightFactor: 0.32,
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

void _showHomeTableSheet(
  BuildContext context, {
  required String title,
  required IconData icon,
  required List<String> headers,
  required List<(String, String)> rows,
}) {
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

class WorkPage extends StatelessWidget {
  final AppSession session;

  const WorkPage({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Работа',
      subtitle: 'Текущая смена',
      trailing: const _StatusPill(text: 'На смене', color: AppColors.green),
      children: const [
        _LiveRouteCard(),
        SizedBox(height: 12),
        _GpsStrip(),
        SizedBox(height: 12),
        _TodayMetrics(),
        SizedBox(height: 12),
        _OdometerCard(),
        SizedBox(height: 12),
        _FuelTodayCard(),
        SizedBox(height: 18),
        _SectionTitle(title: 'Ход смены', caption: 'Сегодня'),
        SizedBox(height: 10),
        _ShiftTimeline(),
      ],
    );
  }
}

class _LiveRouteCard extends StatelessWidget {
  const _LiveRouteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _premiumDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('МАРШРУТ СМЕНЫ', style: TextStyle(color: AppColors.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                    SizedBox(height: 5),
                    Text('Пресновка', style: TextStyle(color: AppColors.text, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -.6)),
                  ],
                ),
              ),
              _StatusPill(text: 'LIVE', color: AppColors.orange),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 205,
            decoration: BoxDecoration(
              color: const Color(0xFF0B0E12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF4A3020)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21),
              child: CustomPaint(
                painter: _RoutePainter(),
                child: const Stack(
                  children: [
                    Positioned(left: 14, bottom: 14, child: _MapMetric(icon: Icons.route_rounded, text: '19,18 км')),
                    Positioned(right: 14, bottom: 14, child: _MapMetric(icon: Icons.gps_fixed_rounded, text: 'GPS активен')),
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

class _MapMetric extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MapMetric({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xDD0B0D10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3A2A1E)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.orange, size: 15),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: AppColors.text, fontSize: 10.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _GpsStrip extends StatelessWidget {
  const _GpsStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: _premiumDecoration(radius: 20),
      child: Row(
        children: [
          const _GlowDot(color: AppColors.green),
          const SizedBox(width: 9),
          const Expanded(
            child: Text('GPS включён', style: TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const Text('19,18 км', style: TextStyle(color: AppColors.orange, fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(width: 10),
          Container(width: 1, height: 24, color: AppColors.line),
          const SizedBox(width: 8),
          TextButton(
            onPressed: null,
            child: Text('Пауза', style: TextStyle(color: AppColors.textSoft, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _TodayMetrics extends StatelessWidget {
  const _TodayMetrics();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _WorkMetricBox(label: 'РЕЙСОВ', value: '3', icon: Icons.local_shipping_outlined)),
        SizedBox(width: 8),
        Expanded(child: _WorkMetricBox(label: 'НАПРАВЛЕНИЙ', value: '2', icon: Icons.route_outlined)),
        SizedBox(width: 8),
        Expanded(child: _WorkMetricBox(label: 'ВЕС', value: '12 383', suffix: 'кг', icon: Icons.scale_outlined)),
      ],
    );
  }
}

class _WorkMetricBox extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;
  final IconData icon;
  const _WorkMetricBox({required this.label, required this.value, required this.icon, this.suffix});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(13),
      decoration: _premiumDecoration(radius: 20),
      child: Stack(
        children: [
          Positioned(right: 0, top: 0, child: Icon(icon, color: AppColors.orange, size: 21)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSoft, fontSize: 8.5, letterSpacing: .6)),
              const Spacer(),
              Text(value, maxLines: 1, style: const TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w800)),
              if (suffix != null) Text(suffix!, style: const TextStyle(color: AppColors.textSoft, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}

class _OdometerCard extends StatelessWidget {
  const _OdometerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _premiumDecoration(),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ОДОМЕТР', style: TextStyle(color: AppColors.textSoft, fontSize: 10, letterSpacing: .8)),
                SizedBox(height: 13),
                Row(
                  children: [
                    _OdoValue(label: 'В НАЧАЛЕ', value: '253 546'),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.arrow_forward_rounded, color: AppColors.orange, size: 22),
                    ),
                    _OdoValue(label: 'ТЕКУЩИЙ', value: '253 565'),
                  ],
                ),
                SizedBox(height: 10),
                Text('+19,18 км за смену', style: TextStyle(color: AppColors.orange, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          SizedBox(width: 8),
          _SpeedGauge(value: 74),
        ],
      ),
    );
  }
}

class _OdoValue extends StatelessWidget {
  final String label;
  final String value;
  const _OdoValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 8)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w800)),
        const Text('км', style: TextStyle(color: AppColors.textSoft, fontSize: 8)),
      ],
    );
  }
}

class _FuelTodayCard extends StatelessWidget {
  const _FuelTodayCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _premiumDecoration(),
      child: const Column(
        children: [
          _FuelLine(label: 'ГАЗ', value: 'не заполнено', color: AppColors.blue),
          SizedBox(height: 17),
          _FuelLine(label: 'БЕНЗИН', value: 'не заполнено', color: AppColors.violet),
        ],
      ),
    );
  }
}

class _FuelLine extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _FuelLine({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.local_gas_station_rounded, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.text, fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(color: AppColors.textSoft, fontSize: 10)),
            ],
          ),
        ),
        Container(width: 80, height: 4, decoration: BoxDecoration(color: color.withValues(alpha: .20), borderRadius: BorderRadius.circular(10))),
      ],
    );
  }
}

class _ShiftTimeline extends StatelessWidget {
  const _ShiftTimeline();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: _premiumDecoration(),
      child: const Column(
        children: [
          _TimelineItem(time: '05:48', title: 'Смена открыта', icon: Icons.play_arrow_rounded),
          _TimelineItem(time: '06:15', title: 'Рейс · Пресновка', icon: Icons.local_shipping_outlined),
          _TimelineItem(time: '07:02', title: 'Газ · 400 л', icon: Icons.local_gas_station_outlined),
          _TimelineItem(time: '09:10', title: 'Рейс · Щучинск', icon: Icons.route_outlined, last: true),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String time;
  final String title;
  final IconData icon;
  final bool last;
  const _TimelineItem({required this.time, required this.title, required this.icon, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: const Color(0xFF1A140F), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF4A301E))),
            child: Icon(icon, color: AppColors.orange, size: 17),
          ),
          const SizedBox(width: 11),
          Expanded(child: Text(title, style: const TextStyle(color: AppColors.text, fontSize: 11.5, fontWeight: FontWeight.w600))),
          Text(time, style: const TextStyle(color: AppColors.textSoft, fontSize: 10)),
        ],
      ),
    );
  }
}

Future<void> _showQuickAddSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .78),
    builder: (sheetContext) => const _QuickAddSheet(),
  );
}

class _QuickAddSheet extends StatelessWidget {
  const _QuickAddSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
        decoration: BoxDecoration(
          color: const Color(0xFF101114),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF5A361E)),
          boxShadow: const [BoxShadow(color: Color(0x66FF7818), blurRadius: 28)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFF4A4B50), borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 16),
            const Row(
              children: [
                Text('Добавить', style: TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w800)),
                Spacer(),
                Text('Текущая смена', style: TextStyle(color: AppColors.textSoft, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _QuickChoice(icon: Icons.local_shipping_outlined, title: 'Рейс', onTap: () => _openTripFlow(context))),
                const SizedBox(width: 9),
                Expanded(child: _QuickChoice(icon: Icons.scale_outlined, title: 'Вес', onTap: () => _openSimpleEntry(context, 'Вес', 'Введите вес, кг'))),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(child: _QuickChoice(icon: Icons.local_gas_station_outlined, title: 'Топливо', onTap: () => _openFuelFlow(context))),
                const SizedBox(width: 9),
                Expanded(child: _QuickChoice(icon: Icons.speed_rounded, title: 'Одометр', onTap: () => _openSimpleEntry(context, 'Одометр', 'Текущее значение, км'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChoice extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _QuickChoice({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 92,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF151619),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF3B2A1E)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.orange, size: 23),
            const Spacer(),
            Text(title, style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

void _openTripFlow(BuildContext context) {
  Navigator.pop(context);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _TripEntrySheet(),
  );
}

class _TripEntrySheet extends StatefulWidget {
  const _TripEntrySheet();
  @override
  State<_TripEntrySheet> createState() => _TripEntrySheetState();
}

class _TripEntrySheetState extends State<_TripEntrySheet> {
  String type = 'Город';
  String direction = 'Пресновка';

  @override
  Widget build(BuildContext context) {
    final directions = type == 'Город'
        ? const ['Петропавловск', 'Бишкуль']
        : const ['Пресновка', 'Щучинск', 'Новоишимское'];
    if (!directions.contains(direction)) direction = directions.first;

    return _EntryShell(
      title: 'Новый рейс',
      icon: Icons.local_shipping_outlined,
      child: Column(
        children: [
          _SegmentedChoice(values: const ['Город', 'Район'], selected: type, onChanged: (v) => setState(() { type = v; direction = v == 'Город' ? 'Петропавловск' : 'Пресновка'; })),
          const SizedBox(height: 14),
          _ChoiceField(
            label: 'НАПРАВЛЕНИЕ',
            value: direction,
            onTap: () async {
              final value = await _pickValue(context, 'Направление', directions);
              if (value != null) setState(() => direction = value);
            },
          ),
          const SizedBox(height: 18),
          _SaveButton(text: 'Добавить рейс', onTap: () { HapticFeedback.mediumImpact(); Navigator.pop(context); }),
        ],
      ),
    );
  }
}

void _openFuelFlow(BuildContext context) {
  Navigator.pop(context);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _FuelEntrySheet(),
  );
}

class _FuelEntrySheet extends StatefulWidget {
  const _FuelEntrySheet();
  @override
  State<_FuelEntrySheet> createState() => _FuelEntrySheetState();
}

class _FuelEntrySheetState extends State<_FuelEntrySheet> {
  String fuel = 'Газ';
  final controller = TextEditingController();

  @override
  void dispose() { controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _EntryShell(
      title: 'Топливо',
      icon: Icons.local_gas_station_outlined,
      child: Column(
        children: [
          _SegmentedChoice(values: const ['Газ', 'Бензин'], selected: fuel, onChanged: (v) => setState(() => fuel = v)),
          const SizedBox(height: 14),
          _NumberField(controller: controller, hint: 'Литры'),
          const SizedBox(height: 18),
          _SaveButton(text: 'Сохранить', onTap: () { HapticFeedback.mediumImpact(); Navigator.pop(context); }),
        ],
      ),
    );
  }
}

void _openSimpleEntry(BuildContext context, String title, String hint) {
  Navigator.pop(context);
  final controller = TextEditingController();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EntryShell(
      title: title,
      icon: title == 'Вес' ? Icons.scale_outlined : Icons.speed_rounded,
      child: Column(
        children: [
          _NumberField(controller: controller, hint: hint),
          const SizedBox(height: 18),
          _SaveButton(text: 'Сохранить', onTap: () { HapticFeedback.mediumImpact(); Navigator.pop(_); }),
        ],
      ),
    ),
  ).whenComplete(controller.dispose);
}

class _EntryShell extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _EntryShell({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
          decoration: BoxDecoration(
            color: const Color(0xFF101114),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFF5A361E)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFF4A4B50), borderRadius: BorderRadius.circular(8))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFF1A140F), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF5A361E))), child: Icon(icon, color: AppColors.orange)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(title, style: const TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w800))),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: AppColors.textSoft)),
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

class _SegmentedChoice extends StatelessWidget {
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;
  const _SegmentedChoice({required this.values, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: values.map((v) {
        final active = v == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: v == values.first ? 5 : 0, left: v == values.last ? 5 : 0),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () { HapticFeedback.selectionClick(); onChanged(v); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF25170E) : const Color(0xFF151619),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: active ? AppColors.orange : AppColors.line),
                ),
                child: Text(v, style: TextStyle(color: active ? AppColors.orange : AppColors.textSoft, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ChoiceField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _ChoiceField({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: const Color(0xFF151619), borderRadius: BorderRadius.circular(17), border: Border.all(color: AppColors.line)),
        child: Row(
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 8.5, letterSpacing: .7)),
              const SizedBox(height: 5),
              Text(value, style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w700)),
            ])),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.orange),
          ],
        ),
      ),
    );
  }
}

Future<String?> _pickValue(BuildContext context, String title, List<String> values) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFF111215),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ...values.map((v) => ListTile(
              title: Text(v, style: const TextStyle(color: AppColors.text)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.orange),
              onTap: () => Navigator.pop(context, v),
            )),
          ],
        ),
      ),
    ),
  );
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _NumberField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF151619),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: AppColors.line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: AppColors.orange)),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _SaveButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.orange,
          side: const BorderSide(color: AppColors.orange),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
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
      subtitle: 'Документы и загрузка',
      trailing: _RoundAction(
        icon: Icons.add_rounded,
        onTap: () => _showFeatureStub(
          context,
          'Создание накладной',
          'На следующем этапе подключим существующую механику накладных к серверу.',
        ),
      ),
      children: [
        _PrimaryActionCard(
          icon: Icons.note_add_outlined,
          title: 'Создать накладную',
          caption: 'Добавить позиции и вес',
          onTap: () => _showFeatureStub(
            context,
            'Создание накладной',
            'Каркас готов. Здесь будет твоя текущая логика выбора товаров, веса и отметки загрузки.',
          ),
        ),
        const SizedBox(height: 18),
        const _SectionTitle(
          title: 'Сегодня',
          caption: '3 документа',
        ),
        const SizedBox(height: 10),
        const _InvoiceCard(
          number: '№ 4821',
          direction: 'Пресновка',
          weight: '2 840 кг',
          time: '07:42',
          status: 'Загружено',
        ),
        const SizedBox(height: 10),
        const _InvoiceCard(
          number: '№ 4820',
          direction: 'Бишкуль',
          weight: '1 960 кг',
          time: '06:18',
          status: 'Доставлено',
        ),
        const SizedBox(height: 10),
        const _InvoiceCard(
          number: '№ 4819',
          direction: 'Мамлютка',
          weight: '3 120 кг',
          time: '05:25',
          status: 'Доставлено',
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
      trailing: const _StatusPill(
        text: 'Месяц',
        color: AppColors.violet,
      ),
      children: const [
        _StatisticsHero(),
        SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Пробег',
                value: '2 418 км',
                caption: 'за месяц',
                icon: Icons.route_outlined,
                accent: AppColors.blue,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Тоннаж',
                value: '164.8 т',
                caption: 'за месяц',
                icon: Icons.scale_outlined,
                accent: AppColors.amber,
              ),
            ),
          ],
        ),
        SizedBox(height: 18),
        _SectionTitle(
          title: 'Динамика',
          caption: 'Последние 14 дней',
        ),
        SizedBox(height: 10),
        _ChartCard(),
        SizedBox(height: 18),
        _DirectionStats(),
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

class _SpeedGauge extends StatelessWidget {
  final int value;

  const _SpeedGauge({
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      height: 118,
      child: CustomPaint(
        painter: _GaugePainter(
          progress: value / 120,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 0.95,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'км/ч',
                style: TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 9,
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

class _WorkMini extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WorkMini({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: AppColors.orange,
            size: 17,
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
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

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFF1A1D22)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 36) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        grid,
      );
    }

    for (double y = 0; y < size.height; y += 36) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        grid,
      );
    }

    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.76)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.62,
        size.width * 0.20,
        size.height * 0.34,
        size.width * 0.40,
        size.height * 0.45,
      )
      ..cubicTo(
        size.width * 0.58,
        size.height * 0.54,
        size.width * 0.62,
        size.height * 0.18,
        size.width * 0.88,
        size.height * 0.28,
      );

    final glow = Paint()
      ..color = const Color(0x555E9BFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;

    final line = Paint()
      ..shader = const LinearGradient(
        colors: [
          AppColors.blue,
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
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, glow);
    canvas.drawPath(path, line);
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

class _InvoiceCard extends StatelessWidget {
  final String number;
  final String direction;
  final String weight;
  final String time;
  final String status;

  const _InvoiceCard({
    required this.number,
    required this.direction,
    required this.weight,
    required this.time,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const _SquareIcon(
            icon: Icons.receipt_long_outlined,
            color: AppColors.violet,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        direction,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '$number • $weight',
                  style: const TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  status,
                  style: const TextStyle(
                    color: AppColors.orangeSoft,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsHero extends StatelessWidget {
  const _StatisticsHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 174,
      padding: const EdgeInsets.all(19),
      decoration: _premiumDecoration(),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Заработок',
                  style: TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '286 400 ₸',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '+7.4% к прошлой неделе',
                  style: TextStyle(
                    color: AppColors.orangeSoft,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Spacer(),
                Text(
                  '87 рейсов • 14 рабочих дней',
                  style: TextStyle(
                    color: AppColors.textDim,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          _RingProgress(
            progress: 0.68,
            centerTitle: '68%',
            centerCaption: 'цель',
          ),
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
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
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF12100D),
            AppColors.background,
            Color(0xFF06070A),
          ],
          stops: [0, 0.35, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -120,
            child: _AmbientGlow(
              size: 340,
              color: Color(0x1AFF6B00),
            ),
          ),
          Positioned(
            left: -150,
            bottom: 120,
            child: _AmbientGlow(
              size: 300,
              color: Color(0x0D5E9BFF),
            ),
          ),
        ],
      ),
    );
  }
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
            blurRadius: 110,
            spreadRadius: 45,
          ),
        ],
      ),
    );
  }
}

BoxDecoration _premiumDecoration({
  Color accent = AppColors.orange,
}) {
  return BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF1B1713),
        Color(0xFF111318),
      ],
    ),
    borderRadius: BorderRadius.circular(28),
    border: Border.all(
      color: accent.withValues(alpha: 0.24),
    ),
    boxShadow: [
      const BoxShadow(
        color: Color(0x66000000),
        blurRadius: 28,
        offset: Offset(0, 15),
      ),
      BoxShadow(
        color: accent.withValues(alpha: 0.07),
        blurRadius: 34,
        spreadRadius: -4,
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
