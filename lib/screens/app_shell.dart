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
    _showQuickAddMenu(context);
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
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xEE171A1F),
                Color(0xF80A0C0F),
                Color(0xFF050607),
              ],
            ),
            border: Border(
              top: BorderSide(color: Color(0xFF3D4148), width: .8),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xB0000000),
                blurRadius: 24,
                offset: Offset(0, -10),
              ),
              BoxShadow(
                color: Color(0x24FF7418),
                blurRadius: 20,
                spreadRadius: -8,
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 6,
            right: 6,
            top: 5,
            bottom: MediaQuery.paddingOf(context).bottom + 6,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
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
                      height: 72,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.translate(
                            offset: const Offset(0, -7),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  center: Alignment(-.28, -.34),
                                  radius: 1.05,
                                  colors: [
                                    Color(0xFF41454C),
                                    Color(0xFF17191D),
                                    Color(0xFF08090B),
                                  ],
                                  stops: [0, .44, 1],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x6AFF7418),
                                    blurRadius: 22,
                                    spreadRadius: 1,
                                  ),
                                  BoxShadow(
                                    color: Color(0xCC000000),
                                    blurRadius: 14,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.orange,
                                    width: 1.25,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: AppColors.orangeSoft,
                                  size: 31,
                                ),
                              ),
                            ),
                          ),
                          const Text(
                            'Добавить',
                            style: TextStyle(
                              color: AppColors.orangeSoft,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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
                    duration: const Duration(milliseconds: 115),
                    curve: Curves.easeOutCubic,
                    height: 62,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      gradient: active
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF24272C),
                                Color(0xFF0E1013),
                              ],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(18),
                      border: active
                          ? Border.all(color: const Color(0xFF6A4A32), width: .8)
                          : null,
                      boxShadow: active
                          ? const [
                              BoxShadow(
                                color: Color(0x24FF7418),
                                blurRadius: 14,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          active ? item.activeIcon : item.icon,
                          size: 21,
                          color: active ? AppColors.orange : AppColors.textDim,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          style: TextStyle(
                            color: active ? AppColors.orangeSoft : AppColors.textDim,
                            fontSize: 8.8,
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
        ),
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
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 30),
      children: [
        _HomeTopBar(session: session),
        const SizedBox(height: 15),
        const _HomeTitleRow(),
        const SizedBox(height: 10),
        const _HomeMonthSelector(),
        const SizedBox(height: 12),
        const _HomeTruckHero(),
        const SizedBox(height: 10),
        _HomeSalaryCard(onTap: () => _showSalarySheet(context)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _HomeTile(
                title: 'ГОРОД',
                value: '58 800 кг',
                subtitle: '59% тоннажа',
                icon: Icons.location_city_rounded,
                accent: AppColors.green,
                footer: const _HomeProgressBar(
                  color: AppColors.green,
                  progress: .59,
                ),
                onTap: () => _showCitySheet(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HomeTile(
                title: 'РАЙОН',
                value: '41 082 кг',
                subtitle: '41% тоннажа',
                icon: Icons.terrain_rounded,
                accent: AppColors.orange,
                footer: const _HomeProgressBar(
                  color: AppColors.orange,
                  progress: .41,
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
                title: 'ГАЗ',
                value: '1 545 л',
                subtitle: 'за месяц',
                icon: Icons.local_fire_department_outlined,
                accent: AppColors.blue,
                onTap: () => _showGasSheet(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HomeSmallTile(
                title: 'БЕНЗИН',
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
                title: 'ПЛАТНЫЕ',
                value: '3',
                subtitle: 'рейса',
                icon: Icons.alt_route_rounded,
                accent: AppColors.orange,
                onTap: () => _showPaidRoutesSheet(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _HomeMaintenanceCard(),
        const SizedBox(height: 10),
        const _HomeTonnageCard(),
        const SizedBox(height: 10),
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
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openHomeMenu(context, session),
          child: Container(
            width: 44,
            height: 44,
            decoration: _homePanelDecoration(
              radius: 16,
              borderColor: const Color(0xFF4A4F57),
            ),
            child: const Icon(Icons.menu_rounded, color: AppColors.text, size: 25),
          ),
        ),
        const SizedBox(width: 10),
        const Icon(Icons.grain_rounded, color: AppColors.orange, size: 30),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TAMERLAN',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              SizedBox(height: 1),
              Text(
                'MILLING SYSTEM',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.7,
                ),
              ),
            ],
          ),
        ),
        _HomeSearchButton(session: session),
        const SizedBox(width: 8),
        const _HomeShiftPill(),
      ],
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
                  SafeArea(
                    child: SearchPage(session: session),
                  ),
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
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C3036), Color(0xFF0C0E11)],
          ),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: const Color(0xFF4C5057),
            width: .8,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x55000000), blurRadius: 12, offset: Offset(0, 6)),
          ],
        ),
        child: const Icon(
          Icons.search_rounded,
          color: AppColors.textSoft,
          size: 22,
        ),
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
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Сентябрь 2026',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.7,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Обзор месяца',
                style: TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 11,
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
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: _homePanelDecoration(
        radius: 17,
        borderColor: const Color(0xFF484D55),
      ),
      child: Row(
        children: [
          _HomeArrowButton(
            icon: Icons.chevron_left_rounded,
            onTap: () => _showFeatureStub(
              context,
              'Месяц',
              'Переключение месяцев подключим вместе с реальными данными.',
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'ТЕКУЩИЙ МЕСЯЦ',
                style: TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          _HomeArrowButton(
            icon: Icons.chevron_right_rounded,
            muted: true,
            onTap: null,
          ),
        ],
      ),
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
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: SizedBox(
        width: 38,
        height: 36,
        child: Icon(
          icon,
          size: 21,
          color: muted ? const Color(0xFF343840) : AppColors.textSoft,
        ),
      ),
    );
  }
}


class _HomeTruckHero extends StatelessWidget {
  const _HomeTruckHero();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () {
        HapticFeedback.selectionClick();
        _showSalarySheet(context);
      },
      child: Container(
        height: 252,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF8A5A36), width: .9),
          boxShadow: const [
            BoxShadow(color: Color(0x5A000000), blurRadius: 28, offset: Offset(0, 16)),
            BoxShadow(color: Color(0x24FF7418), blurRadius: 26),
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
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color(0x22000000),
                      Color(0x76000000),
                      Color(0xF1090A0C),
                    ],
                    stops: [0, .48, 1],
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0x66FFFFFF),
                      Color(0x00FFFFFF),
                      Color(0x00FFFFFF),
                    ],
                    stops: [0, .10, .36],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                top: 17,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xA90A0B0D),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF565B63), width: .7),
                  ),
                  child: const Text(
                    'ЗАРАБОТОК ЗА СЕНТЯБРЬ',
                    style: TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .9,
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 18,
                bottom: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '312 105,8 ₸',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '+18 600 ₸ за неделю',
                      style: TextStyle(
                        color: Color(0xFF77E98A),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        _GlowDot(color: Color(0xFF55E66B)),
                        SizedBox(width: 8),
                        Text(
                          'Смена активна',
                          style: TextStyle(
                            color: Color(0xFFBAF3C2),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Positioned(
                right: 18,
                bottom: 20,
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
  final VoidCallback onTap;

  const _HomeSalaryCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 108,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: _homePanelDecoration(
          radius: 24,
          borderColor: const Color(0xFF555A62),
          glow: const Color(0x18FF7418),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'КЛЮЧЕВЫЕ ПОКАЗАТЕЛИ',
                  style: TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                Spacer(),
                Text(
                  'сегодня / месяц',
                  style: TextStyle(color: AppColors.textDim, fontSize: 8.5),
                ),
              ],
            ),
            Spacer(),
            Row(
              children: [
                Expanded(
                  child: _HomeKeyMetric(
                    icon: Icons.local_shipping_outlined,
                    label: 'Рейсы',
                    value: '29',
                    accent: AppColors.orange,
                  ),
                ),
                _VerticalDivider(),
                Expanded(
                  child: _HomeKeyMetric(
                    icon: Icons.route_rounded,
                    label: 'Пробег',
                    value: '184 км',
                    accent: AppColors.blue,
                  ),
                ),
                _VerticalDivider(),
                Expanded(
                  child: _HomeKeyMetric(
                    icon: Icons.alt_route_rounded,
                    label: 'Направления',
                    value: '2',
                    accent: AppColors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeKeyMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _HomeKeyMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: accent, size: 18),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textDim, fontSize: 8.5),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
      borderRadius: BorderRadius.circular(23),
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: Container(
        height: 128,
        padding: const EdgeInsets.all(14),
        decoration: _homePanelDecoration(
          radius: 23,
          borderColor: const Color(0xFF4B5058),
          glow: accent.withValues(alpha: .055),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              top: -26,
              child: Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: .10),
                      blurRadius: 34,
                      spreadRadius: 7,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(top: 0, right: 0, child: Icon(icon, size: 21, color: accent)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.5,
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!, style: const TextStyle(color: AppColors.textDim, fontSize: 9)),
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
      borderRadius: BorderRadius.circular(21),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 122,
        padding: const EdgeInsets.all(12),
        decoration: _homePanelDecoration(
          radius: 21,
          borderColor: const Color(0xFF494E56),
          glow: accent.withValues(alpha: .04),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 17, color: accent),
                const Spacer(),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: accent, blurRadius: 8)],
                  ),
                ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(color: AppColors.textSoft, fontSize: 8.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: AppColors.textDim, fontSize: 8)),
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
        Color(0xFF3A3E45),
        Color(0xFF1C1F24),
        Color(0xFF0B0D10),
        Color(0xFF050607),
      ],
      stops: [0, .14, .56, 1],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: borderColor.withValues(alpha: .94),
      width: .82,
    ),
    boxShadow: [
      const BoxShadow(
        color: Color(0xB0000000),
        blurRadius: 22,
        offset: Offset(0, 12),
      ),
      BoxShadow(
        color: glow,
        blurRadius: 22,
        spreadRadius: -2,
      ),
      const BoxShadow(
        color: Color(0x24FFFFFF),
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

Future<void> _showQuickAddMenu(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    builder: (sheetContext) {
      return const _QuickAddMenu();
    },
  );
}


class _QuickAddMenu extends StatelessWidget {
  const _QuickAddMenu();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FractionallySizedBox(
        heightFactor: .78,
        widthFactor: 1,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
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
                      Color(0x88000000),
                      Color(0xE80A0B0D),
                      Color(0xFB050607),
                    ],
                    stops: [0, .42, 1],
                  ),
                ),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
                    border: Border(
                      top: BorderSide(color: Color(0xFF777B82), width: .8),
                      left: BorderSide(color: Color(0xFF454950), width: .7),
                      right: BorderSide(color: Color(0xFF5F3C25), width: .8),
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFB3B7BF), AppColors.orange],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Что добавить?',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.8,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Выберите действие для текущей смены',
                        style: TextStyle(color: AppColors.textSoft, fontSize: 11),
                      ),
                      const Spacer(),
                      _QuickActionOrb(
                        icon: Icons.local_shipping_outlined,
                        title: 'Рейс',
                        subtitle: 'Добавить новый рейс',
                        onTap: () => _openTripEntry(context),
                      ),
                      const SizedBox(height: 20),
                      _QuickActionOrb(
                        icon: Icons.local_gas_station_outlined,
                        title: 'Топливо',
                        subtitle: 'Добавить заправку',
                        onTap: () => _openFuelEntry(context),
                      ),
                      const Spacer(),
                      InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: Alignment(-.35, -.35),
                              colors: [
                                Color(0xFF60656D),
                                Color(0xFF1B1E23),
                                Color(0xFF08090B),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(color: Color(0x66FF7418), blurRadius: 18),
                              BoxShadow(color: Color(0x99000000), blurRadius: 14, offset: Offset(0, 7)),
                            ],
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.orange, width: 1.2),
                            ),
                            child: const Icon(Icons.close_rounded, color: AppColors.text, size: 25),
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
      child: Container(
        width: 166,
        height: 166,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: Alignment(-.32, -.40),
            radius: 1.02,
            colors: [
              Color(0xFF5A5F67),
              Color(0xFF2A2E34),
              Color(0xFF101216),
              Color(0xFF050607),
            ],
            stops: [0, .26, .66, 1],
          ),
          boxShadow: [
            BoxShadow(color: Color(0x70FF7418), blurRadius: 31, spreadRadius: 1),
            BoxShadow(color: Color(0xDD000000), blurRadius: 24, offset: Offset(0, 12)),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.orange, width: 1.5),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 16,
                left: 28,
                right: 28,
                child: Container(
                  height: 34,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.elliptical(90, 30)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x45FFFFFF), Color(0x00FFFFFF)],
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: AppColors.orange, size: 37),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textSoft, fontSize: 9.5),
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
  Navigator.pop(context);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const _TripEntrySheet(),
  );
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
  Navigator.pop(context);
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
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 28),
      children: const [
        _PageHeader(
          title: 'Работа',
          subtitle: 'Текущая смена',
          trailing: _StatusPill(
            text: 'На смене',
            color: Color(0xFF55E66B),
          ),
        ),
        SizedBox(height: 10),
        _WorkHero(),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _WorkStatTile(icon: Icons.local_shipping_outlined, label: 'Рейсов сегодня', value: '3')),
            SizedBox(width: 7),
            Expanded(child: _WorkStatTile(icon: Icons.route_outlined, label: 'Направлений', value: '2')),
            SizedBox(width: 7),
            Expanded(child: _WorkStatTile(icon: Icons.scale_outlined, label: 'Вес сегодня', value: '12 383 кг')),
          ],
        ),
        SizedBox(height: 10),
        _ShiftTimelineCard(),
        SizedBox(height: 10),
        _OdometerCard(),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _FuelCard(title: 'Газ', icon: Icons.local_fire_department_outlined, value: '0 л')),
            SizedBox(width: 8),
            Expanded(child: _FuelCard(title: 'Бензин', icon: Icons.local_gas_station_outlined, value: '0 л')),
          ],
        ),
        SizedBox(height: 10),
        _ActionRow(),
      ],
    );
  }
}


class _WorkStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WorkStatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(11),
      decoration: _premiumDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.orange, size: 18),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textDim, fontSize: 7.8),
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
                Text('СПИДОМЕТР', style: TextStyle(color: AppColors.textSoft, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _OdoValue(label: 'В начале смены', value: '253 546')),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('→', style: TextStyle(color: AppColors.orange, fontSize: 24))),
                    Expanded(child: _OdoValue(label: 'Текущий', value: '253 565')),
                  ],
                ),
                SizedBox(height: 10),
                Text('+19,18 км', style: TextStyle(color: AppColors.orangeSoft, fontSize: 14, fontWeight: FontWeight.w800)),
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: AppColors.textSoft, fontSize: 9)),
      const SizedBox(height: 4),
      FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w800))),
      const Text('км', style: TextStyle(color: AppColors.textSoft, fontSize: 8)),
    ],
  );
}

class _FuelCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  const _FuelCard({required this.title, required this.icon, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 124,
      padding: const EdgeInsets.all(16),
      decoration: _premiumDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: AppColors.orange, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w700))]),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppColors.text, fontSize: 25, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Container(height: 3, decoration: BoxDecoration(color: const Color(0xFF26282D), borderRadius: BorderRadius.circular(5))),
        ],
      ),
    );
  }
}


class _ShiftTimelineCard extends StatelessWidget {
  const _ShiftTimelineCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: _premiumDecoration(radius: 24),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'СЕГОДНЯШНИЕ СОБЫТИЯ',
                style: TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              Spacer(),
              Text('Смотреть все', style: TextStyle(color: AppColors.textDim, fontSize: 9)),
              SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: AppColors.orange, size: 17),
            ],
          ),
          SizedBox(height: 12),
          _TimelineRow(icon: Icons.radio_button_checked, time: '05:48', text: 'Смена открыта', active: true),
          _TimelineRow(icon: Icons.local_shipping_outlined, time: '06:15', text: 'Рейс: Петропавл → Щучинск'),
          _TimelineRow(icon: Icons.local_gas_station_outlined, time: '07:02', text: 'Газ · 400 л'),
          _TimelineRow(icon: Icons.inventory_2_outlined, time: '08:20', text: 'Загрузка · 12 383 кг'),
          _TimelineRow(icon: Icons.flag_outlined, time: '09:10', text: 'В пути · Щучинск'),
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
    return Container(
      decoration: _premiumDecoration(radius: 30),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(29),
        child: Stack(
          children: [
            const SizedBox(
              height: 500,
              width: double.infinity,
              child: _RoutePreview(),
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
                decoration: BoxDecoration(
                  color: const Color(0xE20A0C0F),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF565B63), width: .75),
                  boxShadow: const [BoxShadow(color: Color(0x90000000), blurRadius: 16)],
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
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.55,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            '18,96 км  •  маршрут текущей смены',
                            style: TextStyle(color: AppColors.textSoft, fontSize: 9.5),
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
              left: 12,
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xEC2B2E34), Color(0xF20A0C0F)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF656A72), width: .75),
                  boxShadow: const [
                    BoxShadow(color: Color(0xB0000000), blurRadius: 22, offset: Offset(0, 10)),
                  ],
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 88,
                      height: 88,
                      child: _SpeedGauge(value: 74),
                    ),
                    SizedBox(width: 8),
                    _VerticalDivider(),
                    SizedBox(width: 8),
                    Expanded(
                      child: _WorkMini(
                        icon: Icons.timer_outlined,
                        label: 'В пути',
                        value: '5:42',
                      ),
                    ),
                    _VerticalDivider(),
                    Expanded(
                      child: _WorkMini(
                        icon: Icons.route_outlined,
                        label: 'До точки',
                        value: '18,96 км',
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


class _RoutePreview extends StatelessWidget {
  const _RoutePreview();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF11171D), Color(0xFF05080A)],
        ),
      ),
      child: CustomPaint(
        painter: _RoutePainter(),
        child: Stack(
          children: [
            Positioned(
              left: 14,
              top: 92,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xCC0A0D10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF42464D), width: .7),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cloud_outlined, color: AppColors.orangeSoft, size: 15),
                    SizedBox(width: 6),
                    Text('+14°', style: TextStyle(color: AppColors.text, fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 22,
              bottom: 145,
              child: _MapLabel(title: 'Петропавл', icon: Icons.local_shipping_rounded),
            ),
            const Positioned(
              right: 22,
              top: 135,
              child: _MapLabel(title: 'Щучинск', icon: Icons.location_on_rounded),
            ),
            Positioned(
              right: 14,
              top: 190,
              child: Column(
                children: [
                  _MapRoundButton(icon: Icons.near_me_rounded),
                  const SizedBox(height: 8),
                  _MapRoundButton(icon: Icons.add_rounded),
                  const SizedBox(height: 6),
                  _MapRoundButton(icon: Icons.remove_rounded),
                  const SizedBox(height: 8),
                  _MapRoundButton(icon: Icons.layers_outlined),
                ],
              ),
            ),
            Positioned(
              left: 14,
              bottom: 118,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xD90A120D),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF286C3A), width: .8),
                ),
                child: const Row(
                  children: [
                    _GlowDot(color: Color(0xFF55E66B)),
                    SizedBox(width: 7),
                    Text(
                      'GPS активен',
                      style: TextStyle(color: Color(0xFF9EF0AA), fontSize: 9.5, fontWeight: FontWeight.w800),
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

class _ActionRow extends StatelessWidget {
  const _ActionRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OutlineAction(
            icon: Icons.add_location_alt_outlined,
            label: 'Точка',
            onTap: () => _showFeatureStub(
              context,
              'Контрольные точки',
              'Подключим существующие геозоны и уведомления из текущего сервера.',
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _OutlineAction(
            icon: Icons.flag_outlined,
            label: 'Завершить',
            onTap: () => _showFeatureStub(
              context,
              'Завершение смены',
              'Позже здесь будет реальное завершение смены и корректировка итогового пробега.',
            ),
          ),
        ),
      ],
    );
  }
}

class _OutlineAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 18,
        ),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.orangeSoft,
          side: const BorderSide(
            color: Color(0xFF4A3320),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }
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
        Color(0xFF30343A),
        Color(0xFF1A1D22),
        Color(0xFF0D0F12),
        Color(0xFF050607),
      ],
      stops: [0, .17, .62, 1],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: accent.withValues(alpha: .28),
      width: .85,
    ),
    boxShadow: [
      const BoxShadow(
        color: Color(0xA8000000),
        blurRadius: 22,
        offset: Offset(0, 12),
      ),
      BoxShadow(
        color: accent.withValues(alpha: .075),
        blurRadius: 24,
        spreadRadius: -5,
      ),
      const BoxShadow(
        color: Color(0x20FFFFFF),
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
