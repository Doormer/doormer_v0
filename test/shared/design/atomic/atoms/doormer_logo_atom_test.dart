import 'package:doormer/src/shared/design/atomic/atoms/doormer_logo_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('shows the app icon at the size it is given', (tester) async {
    await tester.pumpWidget(_host(const DoormerLogoAtom(size: 88)));

    final image = tester.widget<Image>(find.descendant(
      of: find.byType(DoormerLogoAtom),
      matching: find.byType(Image),
    ));
    expect(
      image.image,
      isA<AssetImage>().having((asset) => asset.assetName, 'assetName',
          'assets/images/brand/doormer_icon.png'),
    );
    expect(tester.getSize(find.byType(DoormerLogoAtom)), const Size(88, 88));
  });

  testWidgets('screen readers hear "Doormer"', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_host(const DoormerLogoAtom(size: 88)));

    expect(
      tester.getSemantics(find.byType(DoormerLogoAtom)),
      containsSemantics(label: 'Doormer', isImage: true),
    );
    semantics.dispose();
  });

  testWidgets('stays silent where a heading already names Doormer',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
        _host(const DoormerLogoAtom(size: 88, excludeFromSemantics: true)));

    expect(find.bySemanticsLabel('Doormer'), findsNothing);
    semantics.dispose();
  });
}
