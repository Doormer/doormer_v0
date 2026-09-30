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
  rarity: Rarity.uncommon,
  scaleLabel: 'Medium',
  artUrl: 'https://example.test/astrolabe.jpg',
  standardShatterQuarks: 11,
  specialShatterQuarks: 22,
  description: 'Unfolds into a ring wider than itself.',
);

const _noConnection =
    "We couldn't connect. Check your connection and try again.";

CardDetailParams _params({
  int standardCopies = 2,
  int specialCopies = 0,
  int quarkBalance = 600,
  bool isShattering = false,
  String? errorMessage,
  void Function(CardVariant variant)? onShatter,
  VoidCallback? onClose,
}) =>
    CardDetailParams(
      holding: Holding(
        card: _card,
        standardCopies: standardCopies,
        specialCopies: specialCopies,
      ),
      quarkBalance: quarkBalance,
      isShattering: isShattering,
      errorMessage: errorMessage,
      onShatter: onShatter ?? (_) {},
      onClose: onClose ?? () {},
    );

Widget _host(Widget child, {double width = 1200}) => ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
          home: Scaffold(body: SizedBox(width: width, child: child))),
    );

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 690);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('shows the card, its facts and the held count', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_host(CardDetailOrganism(params: _params())));

    expect(find.text('Astrolabe'), findsWidgets);
    expect(find.text('Uncommon'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('never stretches past 520 on a wide window', (tester) async {
    tester.view.physicalSize = const Size(540, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(CardDetailOrganism(params: _params())));

    final box = tester.getSize(find.byKey(const Key('card-detail-body')));
    // Asserted against the literal as well as the constant, so a future drift
    // in the constant cannot quietly bless itself.
    expect(box.width, lessThanOrEqualTo(520));
    expect(box.width, lessThanOrEqualTo(CardDetailOrganism.maxWidth));
  });

  testWidgets('stacks the card above its facts on a phone, without overflowing',
      (tester) async {
    _phone(tester);

    // A Dialog's own insets are what make this tight: side by side, the facts
    // column is left about 94px, which a label and its value overflow.
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: Dialog(
            backgroundColor: Colors.transparent,
            child: CardDetailOrganism(params: _params()),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull,
        reason: 'a RenderFlex overflow paints a stripe a student would see');
    expect(find.text('Uncommon'), findsOneWidget);
    expect(find.text('Shatter one'), findsOneWidget);
  });

  testWidgets('the action says Shatter one and never says spare',
      (tester) async {
    _phone(tester);
    await tester.pumpWidget(_host(CardDetailOrganism(params: _params())));

    expect(find.text('Shatter one'), findsOneWidget);
    expect(find.textContaining('spare'), findsNothing);
  });

  group('heldLabel', () {
    Holding held(int standard, int special) => Holding(
          card: _card,
          standardCopies: standard,
          specialCopies: special,
        );

    test('a plain holding is just the count', () {
      expect(CardDetailOrganism.heldLabel(held(1, 0)), '1');
      expect(CardDetailOrganism.heldLabel(held(3, 0)), '3');
    });

    test('a mixed holding names how many are special', () {
      expect(CardDetailOrganism.heldLabel(held(1, 1)), '2 · 1 special');
      expect(CardDetailOrganism.heldLabel(held(2, 2)), '4 · 2 special');
    });

    test('an all-special holding does not say the number twice', () {
      // "3 · 3 special" repeats the count for no reason.
      expect(CardDetailOrganism.heldLabel(held(0, 3)), '3 special');
      expect(CardDetailOrganism.heldLabel(held(0, 1)), '1 special');
    });
  });

  testWidgets('a mixed holding can still be shattered, and says it is special',
      (tester) async {
    // 540 wide, matching the sibling width test: a 1200-wide viewport makes
    // ScreenUtil scale ~3.3x (no ResponsiveAppShell clamp in tests) and the
    // content then overflows vertically, putting the button out of reach.
    tester.view.physicalSize = const Size(540, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // 1 standard + 1 special. Judging whether a copy can be shattered on
    // standardCopies alone left this showing "Held 2" with the only action
    // dead.
    CardVariant? shattered;
    await tester.pumpWidget(_host(
      width: 500,
      CardDetailOrganism(
        params: _params(
          standardCopies: 1,
          specialCopies: 1,
          onShatter: (variant) => shattered = variant,
        ),
      ),
    ));

    expect(find.textContaining('1 special'), findsOneWidget,
        reason: '"Now special" must remain visible after the reveal');

    await tester.tap(find.byType(AppButtonAtom));
    expect(shattered, CardVariant.standard,
        reason: 'shatter the plainer printing, keep the special one');
  });

  testWidgets('a holding of only special copies shatters a special one',
      (tester) async {
    tester.view.physicalSize = const Size(540, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    CardVariant? shattered;
    await tester.pumpWidget(_host(
      width: 500,
      CardDetailOrganism(
        params: _params(
          standardCopies: 0,
          specialCopies: 2,
          onShatter: (variant) => shattered = variant,
        ),
      ),
    ));

    await tester.tap(find.byType(AppButtonAtom));
    expect(shattered, CardVariant.special);
    // An uncommon special is worth double: 11 -> 22.
    expect(find.textContaining('22'), findsOneWidget);
  });

  testWidgets('a single copy cannot be shattered, and says why',
      (tester) async {
    _phone(tester);
    var shatters = 0;
    await tester.pumpWidget(_host(CardDetailOrganism(
      params: _params(standardCopies: 1, onShatter: (_) => shatters++),
    )));

    await tester.tap(find.byType(AppButtonAtom));
    expect(shatters, 0,
        reason: 'shattering the only copy would empty the grid');
    expect(find.text("You can't shatter your only copy."), findsOneWidget,
        reason: 'a greyed-out button with no reason reads as broken');
  });

  testWidgets('shattering reports the variant', (tester) async {
    _phone(tester);
    CardVariant? shattered;
    await tester.pumpWidget(_host(CardDetailOrganism(
      params: _params(
        standardCopies: 3,
        onShatter: (variant) => shattered = variant,
      ),
    )));

    await tester.tap(find.byType(AppButtonAtom));
    expect(shattered, CardVariant.standard);
  });

  testWidgets('can be closed', (tester) async {
    _phone(tester);
    var closed = 0;
    await tester.pumpWidget(_host(CardDetailOrganism(
      params: _params(onClose: () => closed++),
    )));

    await tester.tap(find.byKey(const Key('card-detail-close')));
    expect(closed, 1);
  });

  testWidgets('shows the quark balance, because the page is behind it',
      (tester) async {
    _phone(tester);
    await tester.pumpWidget(_host(CardDetailOrganism(params: _params())));

    expect(find.text('600 quarks'), findsOneWidget);
  });

  testWidgets('the button spins while a shatter waits for its answer',
      (tester) async {
    _phone(tester);
    var shatters = 0;
    await tester.pumpWidget(_host(CardDetailOrganism(
      params: _params(isShattering: true, onShatter: (_) => shatters++),
    )));

    expect(tester.widget<AppButtonAtom>(find.byType(AppButtonAtom)).isLoading,
        isTrue);
    await tester.tap(find.byType(AppButtonAtom));
    expect(shatters, 0, reason: 'one shatter at a time');
  });

  testWidgets('a failed shatter says why under the button', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_host(CardDetailOrganism(
      params: _params(errorMessage: _noConnection),
    )));

    expect(find.text(_noConnection), findsOneWidget);
    expect(find.text('+11 quarks'), findsNothing,
        reason: 'the line under the button says one thing at a time');
  });

  testWidgets(
      'the window keeps its height, whatever the line under the '
      'button says', (tester) async {
    _phone(tester);
    Future<double> heightWith(CardDetailParams params) async {
      await tester.pumpWidget(_host(CardDetailOrganism(params: params)));
      return tester.getSize(find.byKey(const Key('card-detail-body'))).height;
    }

    final paying = await heightWith(_params());
    expect(await heightWith(_params(errorMessage: _noConnection)), paying,
        reason: 'a long message must not wrap onto a second line');
    expect(await heightWith(_params(standardCopies: 1)), paying,
        reason: 'the reason takes the place of "+11 quarks"');
  });
}
