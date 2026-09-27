import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gazelle_android/services/test_store.dart';
import 'package:gazelle_android/models/app_role.dart';
import 'package:gazelle_android/screens/app_shell.dart';
import 'package:gazelle_android/services/session_service.dart';

void main() {
  for (final size in [const Size(360, 640), const Size(412, 915)]) {
    testWidgets('Approved home fits $size with unique navigation and oil service entry', (tester) async {
      SharedPreferences.setMockInitialValues({});TestPreferences.resetCache();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var page = -1;
      var additions = 0;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: HomePage(
        session: const AppSession(role: AppRole.driver, displayName: 'Аркадий', login: 'driver'),
        onNavigate: (value) => page = value,
        onQuickAdd: () => additions++,
      ))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Город'), findsOneWidget);
      expect(find.text('Район'), findsOneWidget);
      expect(find.text('Тоннаж'), findsNothing);
      expect(find.text('Накладные'), findsOneWidget);
      expect(find.text('Ещё'), findsOneWidget);
      expect(find.text('История'), findsOneWidget);
      expect(find.text('Расходы'), findsNothing);
      expect(tester.getBottomRight(find.text('Главная')).dy, lessThanOrEqualTo(size.height));
      await tester.tap(find.text('Работа'));
      expect(page, 1);
      await tester.tap(find.text('Добавить'));
      expect(additions, 1);
      await tester.tap(find.text('Накладные'));
      expect(page, 3);
      await tester.tap(find.textContaining('До замены масла'));
      await tester.pumpAndSettle();
      expect(find.text('Обслуживание'), findsOneWidget);
      expect(find.text('Моторное масло'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Month navigation reads stored values without replacing them', (tester) async {
    final now = DateTime.now();
    final previous = DateTime(now.year, now.month - 1);
    final key = 'home_${previous.year}_${previous.month}_salary';
    SharedPreferences.setMockInitialValues({key: 55500.0});TestPreferences.resetCache();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: HomePage(
      session: const AppSession(role: AppRole.driver, displayName: 'Аркадий', login: 'driver'),
      onNavigate: (_) {}, onQuickAdd: () {},
    ))));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Предыдущий месяц'));
    await tester.pumpAndSettle();
    expect(find.text('55 500 ₸'), findsNothing);
    expect((await SharedPreferences.getInstance()).getDouble(key), 55500);
    expect(tester.takeException(), isNull);
  });
}
