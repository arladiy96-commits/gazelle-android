import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gazelle_android/widgets/keyboard_input.dart';

void main() {
  Future<void> screen(WidgetTester tester, Widget field) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => KeyboardScene(child: child!),
        home: Scaffold(
          appBar: AppBar(title: const Text('Неподвижная шапка')),
          body: Column(
            children: [
              const SizedBox(height: 120),
              field,
              const Expanded(child: SizedBox()),
              const SizedBox(
                key: ValueKey('bottom-menu'),
                height: 60,
                child: Text('Меню'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder editor() => find.byType(TextField).last;
  testWidgets(
    'IME affects editor only; header, menu and source field stay fixed',
    (tester) async {
      final c = TextEditingController(text: '12');
      addTearDown(c.dispose);
      await screen(
        tester,
        KeyboardInput(
          controller: c,
          decoration: const InputDecoration(labelText: 'Вес'),
        ),
      );
      final header = tester.getRect(find.text('Неподвижная шапка'));
      final menu = tester.getRect(find.byKey(const ValueKey('bottom-menu')));
      final source = tester.getRect(find.byType(KeyboardInput));
      await tester.tap(find.byType(KeyboardInput));
      await tester.pumpAndSettle();
      final inputTop = tester.getTopLeft(editor()).dy;
      for (final height in [80.0, 160.0, 300.0, 0.0]) {
        tester.view.viewInsets = FakeViewPadding(bottom: height);
        await tester.pump();
        expect(
          tester.getRect(find.text('Неподвижная шапка', skipOffstage: false)),
          header,
        );
        expect(
          tester.getRect(
            find.byKey(const ValueKey('bottom-menu'), skipOffstage: false),
          ),
          menu,
        );
        expect(
          tester.getRect(find.byType(KeyboardInput, skipOffstage: false)),
          source,
        );
        expect(tester.getTopLeft(editor()).dy, inputTop);
        expect(tester.takeException(), isNull);
      }
      await tester.enterText(editor(), '125');
      await tester.tap(find.text('Готово'));
      await tester.pumpAndSettle();
      expect(c.text, '125');
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'validation keeps editor open and submission happens after closing',
    (tester) async {
      String? submitted;
      await screen(
        tester,
        KeyboardInput(
          initialValue: '',
          validator: (s) => s == '7' ? null : 'Введите 7',
          onSubmitted: (s) => submitted = s,
        ),
      );
      await tester.tap(find.byType(KeyboardInput));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Готово'));
      await tester.pumpAndSettle();
      expect(find.text('Введите 7'), findsOneWidget);
      expect(submitted, isNull);
      await tester.enterText(editor(), '7');
      await tester.tap(find.text('Готово'));
      await tester.pumpAndSettle();
      expect(submitted, '7');
      expect(find.text('Готово'), findsNothing);
    },
  );
  testWidgets('closing keeps typed text and does not submit', (tester) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    var submits = 0;
    String? changed;
    await screen(
      tester,
      KeyboardInput(
        controller: c,
        onChanged: (s) => changed = s,
        onSubmitted: (_) => submits++,
      ),
    );
    await tester.tap(find.byType(KeyboardInput));
    await tester.pumpAndSettle();
    await tester.enterText(editor(), 'Черновик');
    await tester.tap(find.byTooltip('Закрыть'));
    await tester.pumpAndSettle();
    expect(c.text, 'Черновик');
    expect(changed, 'Черновик');
    expect(submits, 0);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('disabled input does not open keyboard editor', (tester) async {
    await screen(tester, const KeyboardInput(enabled: false));
    await tester.tap(find.byType(KeyboardInput), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Готово'), findsNothing);
  });
}
