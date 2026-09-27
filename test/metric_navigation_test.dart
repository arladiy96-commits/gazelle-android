import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gazelle_android/screens/app_shell.dart';
import 'package:gazelle_android/services/session_service.dart';
import 'package:gazelle_android/services/activity_service.dart';
import 'package:gazelle_android/services/test_store.dart';
import 'package:gazelle_android/models/app_role.dart';
void main(){
  testWidgets('city opens daily report and returns to the same month', (tester) async {
    SharedPreferences.setMockInitialValues({});TestPreferences.resetCache();
    await TestStore.open(128540);final now=DateTime.now();
    await ActivityRepository.add(kind:'trip',type:'Город',amount:4,direction:'Султан',date:now);
    tester.view.physicalSize=const Size(412,915);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:HomePage(
      session:const AppSession(role:AppRole.driver,displayName:'Аркадий',login:'test'),onNavigate:(_){},onQuickAdd:(){}))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Город'));await tester.pumpAndSettle();
    expect(find.text('Перевезено за месяц'),findsOneWidget);
    await tester.ensureVisible(find.text('4 000 кг').first);
    await tester.tap(find.text('4 000 кг').first);await tester.pumpAndSettle();
    expect(find.text('Рейсы · 1'),findsOneWidget);
    expect(find.text('01  Султан'),findsOneWidget);
    await tester.tap(find.byTooltip('Назад'));await tester.pumpAndSettle();
    expect(find.text('Перевезено за месяц'),findsOneWidget);
    expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
