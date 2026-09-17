import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class PreviewHomeScreen extends StatelessWidget {
  const PreviewHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: AppColors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Газель',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'тестовая оболочка приложения',
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
              const Spacer(),
              Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFF3D2B1E)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1FFF7A1A),
                        blurRadius: 34,
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.orange,
                        size: 54,
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Первый этап работает',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Splash и экран входа готовы.\n'
                        'Следующим этапом подключим настоящий сервер и роли.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const Center(
                child: Text(
                  'GAZELLE ANDROID • PREVIEW',
                  style: TextStyle(
                    color: Color(0xFF51555E),
                    fontSize: 9,
                    letterSpacing: 2.2,
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
