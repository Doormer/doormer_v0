import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/atoms/edge_fade_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _pump(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: Center(child: child)),
  );
}

const _child = SizedBox(width: 200, height: 60, child: ColoredBox(
  color: Colors.white,
));

void main() {
  testWidgets('an unfaded trail is handed through untouched', (tester) async {
    await tester.pumpWidget(_pump(const EdgeFadeAtom(
      start: false,
      end: false,
      child: _child,
    )));

    expect(find.byType(ShaderMask), findsNothing,
        reason: 'a trail with nothing beyond either end needs no mask');
  });

  testWidgets('fades when there is trail beyond an end', (tester) async {
    await tester.pumpWidget(_pump(const EdgeFadeAtom(
      start: true,
      end: false,
      child: _child,
    )));

    expect(find.byType(ShaderMask), findsOneWidget);
  });

  testWidgets('fades across the trail, horizontally by default',
      (tester) async {
    await tester.pumpWidget(_pump(const EdgeFadeAtom(
      start: true,
      end: true,
      child: _child,
    )));

    final mask = tester.widget<ShaderMask>(find.byType(ShaderMask));
    final gradient = mask.shaderCallback(const Rect.fromLTWH(0, 0, 200, 60));

    // A gradient is opaque about its own direction, so compare the shader it
    // produces against one built along each axis.
    expect(
      gradient.toString(),
      _shaderFor(Alignment.centerLeft, Alignment.centerRight, 200).toString(),
    );
  });

  testWidgets('fades along the rail when vertical', (tester) async {
    await tester.pumpWidget(_pump(const EdgeFadeAtom(
      start: true,
      end: true,
      axis: Axis.vertical,
      child: _child,
    )));

    final mask = tester.widget<ShaderMask>(find.byType(ShaderMask));
    final gradient = mask.shaderCallback(const Rect.fromLTWH(0, 0, 200, 60));

    expect(
      gradient.toString(),
      _shaderFor(Alignment.topCenter, Alignment.bottomCenter, 60).toString(),
    );
  });
}

/// The gradient the atom is expected to build, given the axis it runs along and
/// the extent it measures the fade against.
Shader _shaderFor(Alignment begin, Alignment end, double extent) {
  const fade = EdgeFadeAtom.fade;
  return LinearGradient(
    begin: begin,
    end: end,
    colors: const [
      Colors.transparent,
      Colors.black,
      Colors.black,
      Colors.transparent,
    ],
    stops: [0, fade / extent, 1 - fade / extent, 1],
  ).createShader(const Rect.fromLTWH(0, 0, 200, 60));
}
