import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gazelle_android/models/app_role.dart';
import 'package:gazelle_android/screens/app_shell.dart';
import 'package:gazelle_android/services/session_service.dart';
import 'package:gazelle_android/services/test_store.dart';

void main(){
  setUp((){SharedPreferences.setMockInitialValues({});TestPreferences.resetCache();});
  for(final size in [const Size(360,640),const Size(412,915)]){
    testWidgets('Live work dashboard fits $size and keeps navigation', (tester) async{
      tester.view.devicePixelRatio=1;tester.view.physicalSize=size;
      addTearDown(tester.view.resetDevicePixelRatio);addTearDown(tester.view.resetPhysicalSize);
      await TestStore.seed();var page=-1;var additions=0;
      await tester.pumpWidget(MaterialApp(home:Scaffold(body:WorkPage(
        session:const AppSession(role:AppRole.driver,displayName:'Аркадий',login:'driver'),
        onNavigate:(v)=>page=v,onQuickAdd:()=>additions++))));
      await tester.pumpAndSettle();
      expect(tester.takeException(),isNull);
      expect(find.text('128 664'),findsOneWidget);
      expect(find.text('124 км'),findsWidgets);
      expect(find.text('Заработано за месяц'),findsNothing);
      expect(tester.getBottomRight(find.text('Главная')).dy,lessThanOrEqualTo(size.height));
      await tester.tap(find.text('Главная'));expect(page,0);
      await tester.tap(find.text('Накладные'));expect(page,3);
      await tester.tap(find.text('Добавить'));expect(additions,1);
      await TestStore.odometer((await TestStore.load()).active!['id'] as String,128700);
      await tester.pumpAndSettle();expect(find.text('128 700'),findsOneWidget);
      expect(tester.takeException(),isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
