import 'package:doormer/src/features/questions/presentation/molecules/user_status_molecule.dart';
import 'package:doormer/src/features/questions/presentation/params/user_status_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders level and collected character count once',
      (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => const MaterialApp(
          home: Scaffold(
            body: UserStatusMolecule(
              params: UserStatusParams(
                levelLabel: 'LV.7',
                collectedCount: 12,
                totalCount: 50,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('LV.7'), findsOneWidget);
    expect(find.text('Characters collected: 12/50'), findsOneWidget);
  });
}
