import 'dart:convert';
import 'dart:typed_data';

import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/atoms/math_block_atom.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_segment_order.dart';
import 'package:doormer/src/features/questions/presentation/molecules/diagram_figure_molecule.dart';
import 'package:doormer/src/features/questions/presentation/molecules/segment_list_molecule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

final Uint8List _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
  'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

const _visual = VisualSolutionSegment(
  mediaType: 'image/png',
  url: 'https://example.test/step1.png',
  width: 1600,
  height: 1067,
  caption: 'caption',
  alt: 'alt',
);

void main() {
  testWidgets('renders one widget per segment in the order it is given',
      (tester) async {
    VisualSolutionSegment? enlarged;

    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 358,
              child: SegmentListMolecule(
                segments: diagramFirstOrder(const [
                  TextSolutionSegment('Let theta be the angle.'),
                  _visual,
                  MathSolutionSegment(
                    latex: r'\tan\theta=\frac{3}{4}',
                    alt: 'tangent theta',
                  ),
                ]),
                onEnlargeVisual: (visual) => enlarged = visual,
                imageProviderBuilder: (_) => MemoryImage(_pngBytes),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(find.byType(DiagramFigureMolecule), findsOneWidget);
    expect(find.text('Let theta be the angle.'), findsOneWidget);
    expect(find.byType(MathBlockAtom), findsOneWidget);

    await tester.tap(find.byKey(const Key('diagram_figure')));
    await tester.pump();

    expect(enlarged, same(_visual));
  });
}
