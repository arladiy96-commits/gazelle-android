import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class PreviewHomeScreen extends StatelessWidget {
  const PreviewHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _Background(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: const Icon(
                          Icons.grain_rounded,
                          color: AppColors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ТАМЕРЛАН',
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'предпросмотр системы',
                              style: TextStyle(
                                color: AppColors.textSoft,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.logout_rounded),
                        color: AppColors.textSoft,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const _HeroPanel(),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(
                        child: _MiniCard(
                          title: 'Смена',
                          value: 'Открыта',
                          icon: Icons.schedule_rounded,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _MiniCard(
                          title: 'Погрузка',
                          value: 'Активна',
                          icon: Icons.warehouse_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Expanded(
                        child: _MiniCard(
                          title: 'Маршруты',
                          value: '12',
                          icon: Icons.alt_route_rounded,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _MiniCard(
                          title: 'Накладные',
                          value: '8',
                          icon: Icons.receipt_long_outlined,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Center(
                    child: Text(
                      'ДАЛЬШЕ ПОДКЛЮЧИМ НАСТОЯЩУЮ АВТОРИЗАЦИЮ И ЭКРАНЫ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF555962),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF33261B)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
          BoxShadow(
            color: Color(0x16FF7418),
            blurRadius: 36,
            spreadRadius: -8,
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Первый этап готов',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'MP4-интро уже встроено. Экран входа и общий стиль тоже приведены к единому виду. Следующий этап — подключение реального сервера и ролей.',
            style: TextStyle(
              color: AppColors.textSoft,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MiniCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111318),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF262A31)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.orange,
            size: 20,
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSoft,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF15100B),
            AppColors.background,
            Color(0xFF050608),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -120,
            child: _GlowBall(size: 320, color: Color(0x1AFF6A00)),
          ),
          Positioned(
            left: -100,
            bottom: 120,
            child: _GlowBall(size: 240, color: Color(0x10FFB46B)),
          ),
        ],
      ),
    );
  }
}

class _GlowBall extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBall({
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
            blurRadius: 95,
            spreadRadius: 36,
          ),
        ],
      ),
    );
  }
}
