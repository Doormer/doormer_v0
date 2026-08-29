import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/params/camera_capture_params.dart';
import 'package:doormer/src/features/questions/presentation/templates/camera_capture_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _pump(CameraCaptureParams params) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: CameraCaptureTemplate(params: params),
  );
}

CameraCaptureParams _params({
  required CameraCaptureStatus status,
  Widget? preview,
  String failureMessage = 'Unable to open camera',
  VoidCallback? onCapture,
}) {
  return CameraCaptureParams(
    status: status,
    preview: preview,
    title: 'Take a photo',
    failureMessage: failureMessage,
    onCapture: onCapture ?? () {},
  );
}

void main() {
  testWidgets('owns the screen chrome so the page does not have to',
      (tester) async {
    await tester.pumpWidget(
      _pump(_params(status: CameraCaptureStatus.starting)),
    );

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.byKey(const Key('camera_shutter')), findsOneWidget);
  });

  testWidgets('waits while the camera is still coming up', (tester) async {
    await tester.pumpWidget(
      _pump(_params(status: CameraCaptureStatus.starting)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('camera_preview')), findsNothing);
  });

  testWidgets('shows the preview once the camera is ready', (tester) async {
    await tester.pumpWidget(_pump(_params(
      status: CameraCaptureStatus.ready,
      preview: const ColoredBox(color: Color(0xFF123456)),
    )));

    expect(find.byKey(const Key('camera_preview')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('holds the spinner even with a preview in hand, until the camera '
      'says it is ready', (tester) async {
    await tester.pumpWidget(_pump(_params(
      status: CameraCaptureStatus.starting,
      preview: const ColoredBox(color: Color(0xFF123456)),
    )));

    expect(find.byKey(const Key('camera_preview')), findsNothing,
        reason: 'the status is the authority; a preview left over from a '
            'previous controller would otherwise show as a frozen frame');
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('says so when the camera will not open', (tester) async {
    await tester.pumpWidget(_pump(_params(
      status: CameraCaptureStatus.failed,
      failureMessage: 'Unable to open camera',
    )));

    expect(find.text('Unable to open camera'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('the shutter reports upward', (tester) async {
    var shots = 0;
    await tester.pumpWidget(_pump(_params(
      status: CameraCaptureStatus.ready,
      preview: const SizedBox.expand(),
      onCapture: () => shots++,
    )));

    await tester.tap(find.byKey(const Key('camera_shutter')));
    await tester.pump();

    expect(shots, 1);
  });
}
