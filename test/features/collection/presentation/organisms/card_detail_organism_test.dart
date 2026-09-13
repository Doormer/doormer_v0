import 'package:doormer/src/features/collection/domain/entity/card_rarity.dart';
import 'package:doormer/src/features/collection/domain/entity/collectible_card.dart';
import 'package:doormer/src/features/collection/domain/entity/holding.dart';
import 'package:doormer/src/features/collection/presentation/organisms/card_detail_organism.dart';
import 'package:doormer/src/features/collection/presentation/params/card_detail_params.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _card = CollectibleCard(
  id: 'astrolabe',
  name: 'Astrolabe',
  deckId: 'meridian',
  rarity: Rarity.uncommon,
  scaleLabel: 'Medium',
  artAsset: 'assets/cards/meridian/astrolabe.png',
  description: 'Unfolds into a ring wider than itself.',
);

Widget _host(Widget child, {double width = 1200}) => ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) =>
          MaterialApp(home: Scaffold(body: SizedBox(width: width, child: child))),
    );

void main() {
  testWidgets('shows the card, its facts and the held count', (tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(_host(CardDetailOrganism(
      params: CardDetailParams(
        holding: const Holding(card: _card, standardCopies: 2, specialCopies: 0),
        onConvert: (_) {},
        onClose: () {},
      ),
    )));
    expect(find.text('Astrolabe'), findsWidgets);
    expect(find.text('Uncommon'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('never stretches past 520 on a wide window', (tester) async {
    tester.view.physicalSize = const Size(540, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(_host(CardDetailOrganism(
      params: CardDetailParams(
        holding: const Holding(card: _card, standardCopies: 2, specialCopies: 0),
        onConvert: (_) {},
        onClose: () {},
      ),
    )));
    final box = tester.getSize(find.byKey(const Key('card-detail-body')));
    // Asserted against the literal as well as the constant, so a future drift
    // in the constant cannot quietly bless itself.
    expect(box.width, lessThanOrEqualTo(520));
    expect(box.width, lessThanOrEqualTo(CardDetailOrganism.maxWidth));
  });

  testWidgets('the convert action says Trade one and never says spare',
      (tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(_host(CardDetailOrganism(
      params: CardDetailParams(
        holding: const Holding(card: _card, standardCopies: 2, specialCopies: 0),
        onConvert: (_) {},
        onClose: () {},
      ),
    )));
    expect(find.text('Trade one'), findsOneWidget);
    expect(find.textContaining('spare'), findsNothing);
    expect(find.textContaining('Convert'), findsNothing);
  });

  testWidgets('a single copy cannot be traded away', (tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    var converts = 0;
    await tester.pumpWidget(_host(CardDetailOrganism(
      params: CardDetailParams(
        holding: const Holding(card: _card, standardCopies: 1, specialCopies: 0),
        onConvert: (_) => converts++,
        onClose: () {},
      ),
    )));
    await tester.tap(find.byType(AppButtonAtom));
    expect(converts, 0, reason: 'trading the only copy would empty the grid');
  });

  testWidgets('trading reports the variant', (tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    CardVariant? traded;
    await tester.pumpWidget(_host(CardDetailOrganism(
      params: CardDetailParams(
        holding: const Holding(card: _card, standardCopies: 3, specialCopies: 0),
        onConvert: (v) => traded = v,
        onClose: () {},
      ),
    )));
    await tester.tap(find.byType(AppButtonAtom));
    expect(traded, CardVariant.standard);
  });

  testWidgets('can be closed', (tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    var closed = 0;
    await tester.pumpWidget(_host(CardDetailOrganism(
      params: CardDetailParams(
        holding: const Holding(card: _card, standardCopies: 2, specialCopies: 0),
        onConvert: (_) {},
        onClose: () => closed++,
      ),
    )));
    await tester.tap(find.byKey(const Key('card-detail-close')));
    expect(closed, 1);
  });
}
