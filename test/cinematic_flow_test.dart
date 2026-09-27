import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gazelle_android/models/app_role.dart';
import 'package:gazelle_android/screens/app_shell.dart';
import 'package:gazelle_android/services/session_service.dart';
import 'package:gazelle_android/services/test_store.dart';

void main(){
  setUp((){SharedPreferences.setMockInitialValues({});TestPreferences.resetCache();});
  testWidgets('Opening and closing shift saves real odometer and manual hours', (tester) async{
    tester.view.physicalSize=const Size(360,640);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:WorkPage(
      session:const AppSession(role:AppRole.driver,displayName:'Аркадий',login:'driver')))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Открыть смену'));
    await tester.tap(find.text('Открыть смену'));await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first,'253546');
    await tester.enterText(find.byType(TextField).last,'8');
    await tester.ensureVisible(find.widgetWithText(OutlinedButton,'Открыть смену'));
    await tester.tap(find.widgetWithText(OutlinedButton,'Открыть смену'));await tester.pumpAndSettle();
    expect((await TestStore.load()).active!['currentKm'],253546);
    await tester.ensureVisible(find.text('Завершить смену'));
    await tester.tap(find.text('Завершить смену'));await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first,'253670');
    await tester.ensureVisible(find.widgetWithText(OutlinedButton,'Завершить смену'));
    await tester.tap(find.widgetWithText(OutlinedButton,'Завершить смену'));await tester.pumpAndSettle();
    final b=await TestStore.load();expect(b.active,isNull);expect(b.mileage(b.shifts.single),124);expect(b.hours(b.shifts.single),8);
    expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
