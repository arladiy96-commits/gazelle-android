import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gazelle_android/widgets/keyboard_input.dart';
import 'package:gazelle_android/widgets/dormant_tab.dart';

void main() {
  testWidgets(
    'direct input keeps a single field and fixed header/menu while scrolling form',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => KeyboardScene(child: child!),
          home: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(title: const Text('Шапка')),
            bottomNavigationBar: const SizedBox(
              key: ValueKey('menu'),
              height: 56,
            ),
            body: KeyboardScrollArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 490),
                    KeyboardInput(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 200),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final header = tester.getRect(find.text('Шапка'));
      final menu = tester.getRect(find.byKey(const ValueKey('menu')));
      await tester.tap(find.byType(TextFormField));
      await tester.pump();
      for (final height in [100.0, 220.0, 300.0]) {
        tester.view.viewInsets = FakeViewPadding(bottom: height);
        await tester.pump();
        await tester.pump();
        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.byType(Dialog), findsNothing);
        expect(tester.getRect(find.text('Шапка')), header);
        expect(tester.getRect(find.byKey(const ValueKey('menu'))), menu);
        expect(
          tester.getBottomRight(find.byType(TextFormField)).dy,
          lessThanOrEqualTo(800 - height),
        );
        expect(tester.takeException(), isNull);
      }
      await tester.enterText(find.byType(TextFormField), '12x5');
      expect(controller.text, '125');
      tester.view.viewInsets = const FakeViewPadding();
      await tester.pumpAndSettle();
      expect(controller.text, '125');
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );

  testWidgets('tab retains its draft through hide and restore', (tester) async {
    var active = true;
    var layouts = 0;
    late StateSetter change;
    final controller = TextEditingController(text: 'Черновик');
    final child = LayoutBuilder(
      builder: (_, constraints) {
        layouts++;
        return TextField(controller: controller);
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (_, setState) {
            change = setState;
            return Scaffold(
              body: SizedBox.expand(
                child: DormantTab(active: active, child: child),
              ),
            );
          },
        ),
      ),
    );
    change(() => active = false);
    await tester.pump();
    change(() => active = true);
    await tester.pump();
    expect(controller.text, 'Черновик');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  testWidgets('system back reveals the retained tab after a pushed menu', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: const Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              DormantTab(active: false, child: Text('Hidden')),
              DormantTab(active: true, child: Center(child: Text('More menu'))),
            ],
          ),
        ),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Settings')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('More menu').hitTestable(), findsOneWidget);
    expect(find.text('Settings'), findsNothing);
    expect(navigator.currentState!.canPop(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mechanical counter edits the same field without another route', (
    tester,
  ) async {
    final controller = TextEditingController(text: '253546');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 90,
              child: DrumInput(controller: controller),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    expect(
      controller.selection,
      const TextSelection(baseOffset: 0, extentOffset: 6),
    );
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.enableInteractiveSelection, isFalse);
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '7',
        selection: TextSelection.collapsed(offset: 1),
      ),
    );
    await tester.pump();
    expect(controller.text, '7');
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '78',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.pump();
    expect(controller.text, '78');
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '7',
        selection: TextSelection.collapsed(offset: 1),
      ),
    );
    await tester.pump();
    expect(controller.text, '7');
    await tester.enterText(find.byType(TextFormField), '253547');
    await tester.pump();
    expect(controller.text, '253547');
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('7'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  testWidgets('keyboard does not scroll a field that is already visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => KeyboardScene(child: child!),
        home: const Scaffold(
          resizeToAvoidBottomInset: false,
          body: KeyboardScrollArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 180),
                  KeyboardInput(),
                  SizedBox(height: 800),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final before = tester.getRect(find.byType(TextFormField));
    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(TextFormField)), before);
    expect(tester.takeException(), isNull);
  });
}
