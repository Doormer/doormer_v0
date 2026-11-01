import 'dart:convert';
import 'dart:typed_data';

import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/card_picture_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 1x1 transparent PNG.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
  'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// Art whose link no longer works.
class _FailingImageProvider extends MemoryImage {
  _FailingImageProvider() : super(_png);

  @override
  ImageStreamCompleter loadImage(MemoryImage key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(
      Future<ImageInfo>.error(Exception('404 card art')),
    );
  }
}

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: Center(child: child)),
    );

const _letter = Key('card_picture_letter');

void main() {
  testWidgets('with no art, shows the first letter of the nickname',
      (tester) async {
    await tester.pumpWidget(
        _host(const CardPictureAtom(name: 'sam', artUrl: null, size: 40)));

    expect(find.byKey(_letter), findsOneWidget);
    expect(find.text('S'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('shows the card art when there is some', (tester) async {
    await tester.pumpWidget(_host(CardPictureAtom(
      name: 'Sam',
      artUrl: 'https://example.test/gnomon.png',
      size: 40,
      imageProviderBuilder: (_) => MemoryImage(_png),
    )));

    expect(find.byType(Image), findsOneWidget);
    expect(find.byKey(_letter), findsNothing);
  });

  testWidgets('shows the letter when the art fails to load', (tester) async {
    await tester.pumpWidget(_host(CardPictureAtom(
      name: 'Sam',
      artUrl: 'https://example.test/gone.png',
      size: 40,
      imageProviderBuilder: (_) => _FailingImageProvider(),
    )));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(_letter), findsOneWidget);
    expect(find.text('S'), findsOneWidget);
  });

  testWidgets('is a square of the size it is given', (tester) async {
    await tester.pumpWidget(
        _host(const CardPictureAtom(name: 'Sam', artUrl: null, size: 40)));

    expect(tester.getSize(find.byType(CardPictureAtom)), const Size(40, 40));
  });

  testWidgets(
      'the letter tile stands out on a card: its fill is not the card colour, '
      'and it has an edge with the same rounded corners', (tester) async {
    await tester.pumpWidget(
        _host(const CardPictureAtom(name: 'Nia', artUrl: null, size: 50)));

    expect(
      tester.widget(find.byKey(_letter)),
      isA<DecoratedBox>().having(
        (tile) => tile.decoration,
        'decoration',
        isA<BoxDecoration>()
            .having((looks) => looks.color, 'fill', isNot(QuestPalette.card))
            .having((looks) => looks.border?.top.width, 'edge width', 1)
            .having((looks) => looks.borderRadius, 'corners',
                BorderRadius.circular(50 * 0.22)),
      ),
    );
    expect(find.text('N'), findsOneWidget);
  });

  test('the letter keeps macrons and accents, in capitals', () {
    expect(CardPictureAtom.letterOf('āwhina'), 'Ā');
    expect(CardPictureAtom.letterOf('élodie'), 'É');
    expect(CardPictureAtom.letterOf('  kai'), 'K');
  });

  test('the letter skips anything before the first letter', () {
    expect(CardPictureAtom.letterOf('_kai'), 'K');
    expect(CardPictureAtom.letterOf('4ever'), 'E');
    expect(CardPictureAtom.letterOf('.sam'), 'S');
  });

  test('a blank name shows ?', () {
    expect(CardPictureAtom.letterOf(''), '?');
    expect(CardPictureAtom.letterOf('   '), '?');
  });
}
