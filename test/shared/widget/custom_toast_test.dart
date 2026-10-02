import 'package:doormer/src/shared/widget/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';

void main() {
  test('errors stay longer than other toasts', () {
    expect(CustomToast.defaultDurationFor(ToastificationType.error),
        const Duration(seconds: 4));
    expect(CustomToast.defaultDurationFor(ToastificationType.info),
        const Duration(seconds: 2));
    expect(CustomToast.defaultDurationFor(ToastificationType.warning),
        const Duration(seconds: 2));
    expect(CustomToast.defaultDurationFor(ToastificationType.success),
        const Duration(seconds: 2));
  });

  testWidgets('an error toast opens and closes without throwing',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => CustomToast.show(context,
              message: 'Nope', type: ToastificationType.error),
          child: const Text('go'),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Nope'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Nope'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Nope'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
