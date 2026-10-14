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

  testWidgets('hidden tab retains state and is not laid out on tab switch', (
    tester,
  ) async {
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
    final initialLayouts = layouts;
    change(() => active = false);
    await tester.pump();
    expect(layouts, initialLayouts);
    change(() => active = true);
    await tester.pump();
    expect(controller.text, 'Черновик');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
