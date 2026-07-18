import 'package:doormer/src/features/questions/presentation/organisms/bottom_action_bar_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/bottom_action_bar_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('composes the five bottom actions with their callbacks',
      (tester) async {
    final tapped = <String>[];

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: BottomActionBarOrganism(
              params: BottomActionBarParams(
                onCopy: () => tapped.add('copy'),
                onAiChat: () => tapped.add('aiChat'),
                onUpload: () => tapped.add('upload'),
                onChat: () => tapped.add('chat'),
                onProfile: () => tapped.add('profile'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(IconButton), findsNWidgets(5));

    await tester.tap(find.byIcon(Icons.copy));
    await tester.tap(find.byIcon(Icons.smart_toy_outlined));
    await tester.tap(find.byIcon(Icons.camera_alt_outlined));
    await tester.tap(find.byIcon(Icons.chat_bubble_outline));
    await tester.tap(find.byIcon(Icons.person_outline));

    expect(tapped, ['copy', 'aiChat', 'upload', 'chat', 'profile']);
  });
}
