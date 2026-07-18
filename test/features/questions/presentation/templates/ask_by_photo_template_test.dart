import 'package:doormer/src/features/questions/presentation/mapper/solve_status_presenter.dart';
import 'package:doormer/src/features/questions/presentation/molecules/user_status_molecule.dart';
import 'package:doormer/src/features/questions/presentation/organisms/bottom_action_bar_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/bottom_action_bar_params.dart';
import 'package:doormer/src/features/questions/presentation/params/photo_upload_panel_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solve_status_panel_params.dart';
import 'package:doormer/src/features/questions/presentation/params/user_status_params.dart';
import 'package:doormer/src/features/questions/presentation/templates/ask_by_photo_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'composes user status and bottom actions while preserving the upload CTA',
      (tester) async {
    var pickCount = 0;
    var submitCount = 0;

    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp(
          home: AskByPhotoTemplate(
            userStatusParams: const UserStatusParams(
              levelLabel: 'LV.xx',
              collectedCount: 12,
              totalCount: 50,
            ),
            uploadParams: PhotoUploadPanelParams(
              isLoading: false,
              onPickPhoto: () => pickCount++,
              onSubmit: () => submitCount++,
              onClear: () {},
            ),
            statusParams: const SolveStatusPanelParams(
              content: SolveStatusContent(
                title: '',
                body: '',
                showActions: false,
              ),
              onRetake: _noop,
              onTypeInstead: _noop,
            ),
            bottomBarParams: BottomActionBarParams(
              onCopy: () {},
              onAiChat: () {},
              onUpload: () {},
              onChat: () {},
              onProfile: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(UserStatusMolecule), findsOneWidget);
    expect(find.text('Characters collected: 12/50'), findsOneWidget);
    expect(find.byType(BottomActionBarOrganism), findsOneWidget);

    await tester.tap(find.text('UPLOAD & SOLVE'));
    expect(pickCount, 1);
    expect(submitCount, 0);
  });
}

void _noop() {}
