import 'package:doormer/src/core/responsive/responsive_app_shell.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/profile/presentation/molecules/friend_request_row_molecule.dart';
import 'package:doormer/src/features/profile/presentation/molecules/friend_row_molecule.dart';
import 'package:doormer/src/features/profile/presentation/organisms/level_card_organism.dart';
import 'package:doormer/src/features/profile/presentation/organisms/profile_header_organism.dart';
import 'package:doormer/src/features/profile/presentation/params/friend_request_row_params.dart';
import 'package:doormer/src/features/profile/presentation/params/friend_row_params.dart';
import 'package:doormer/src/features/profile/presentation/params/level_card_params.dart';
import 'package:doormer/src/features/profile/presentation/params/profile_body_params.dart';
import 'package:doormer/src/features/profile/presentation/params/profile_header_params.dart';
import 'package:doormer/src/features/profile/presentation/templates/profile_template.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/glow_badge_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/surface_card_atom.dart';
import 'package:doormer/src/shared/levels/entity/level.dart';
import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A window whose content column is 760 wide: a computer's. It is tall
/// enough for the UI's largest scale, 1.45.
const _wide = Size(760, 1400);

/// A phone's window, 360 wide.
const _narrow = Size(360, 1400);

/// Loads the app's reading face, so labels take the room they take in the
/// app rather than the test font's 1 em a letter.
Future<void> _loadReadingFace() async {
  final face = FontLoader(kBodyFont);
  for (final weight in [400, 500, 600, 700]) {
    face.addFont(rootBundle.load('assets/fonts/SpaceGrotesk-$weight.ttf'));
  }
  await face.load();
}

/// Profile as the app shows it in a [window] of that size.
Future<void> _pump(
  WidgetTester tester, {
  required Size window,
  required ProfileBodyParams body,
  LevelCardParams? levelCard,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = window;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark,
    builder: (context, child) => ResponsiveAppShell(child: child!),
    home: ProfileTemplate(
      body: body,
      levelCard: levelCard,
      isSigningOut: false,
      onSignOut: () {},
    ),
  ));
}

/// Kai, set up, with [friends] and requests from [requesters]. Opening a
/// friend tells [onOpen] their nickname.
ProfileFriendsParams _kai({
  List<String> friends = const ['Alex', 'Sam'],
  List<String> requesters = const ['Rua', 'Nia'],
  void Function(String nickname)? onOpen,
}) =>
    ProfileFriendsParams(
      header: ProfileHeaderParams(
        nickname: 'Kai',
        artUrl: null,
        friendCode: 'K7QM-2XPA',
        onEdit: () {},
      ),
      onAddFriend: () {},
      requests: [
        for (final nickname in requesters)
          FriendRequestRowParams(
            nickname: nickname,
            artUrl: null,
            isBusy: false,
            onAccept: () {},
            onDecline: () {},
            onBlock: () {},
            onReport: () {},
          ),
      ],
      friends: [
        for (final nickname in friends)
          FriendRowParams(
            nickname: nickname,
            artUrl: null,
            isBusy: false,
            onOpen: () => onOpen?.call(nickname),
            onRemove: () {},
            onBlock: () {},
            onReport: () {},
          ),
      ],
      onOpenBlocked: () {},
    );

Finder _friendRow(String nickname) =>
    find.widgetWithText(FriendRowMolecule, nickname);
Finder _requestRow(String nickname) =>
    find.widgetWithText(FriendRequestRowMolecule, nickname);
Finder _button(String label) => find.widgetWithText(AppButtonAtom, label);

/// The tile holding [content], if it is in one.
Finder _tileAround(Finder content) =>
    find.ancestor(of: content, matching: find.byType(SurfaceCardAtom));

/// How many lines [text] takes.
int _linesOf(WidgetTester tester, Finder text) {
  final paragraph = tester.renderObject<RenderParagraph>(text);
  final length = paragraph.text.toPlainText().length;
  return paragraph
      .getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: length))
      .map((box) => box.top)
      .toSet()
      .length;
}

void main() {
  setUpAll(_loadReadingFace);

  group('on a wide screen', () {
    testWidgets('friends and requests sit two to a line, each in a tile',
        (tester) async {
      await _pump(tester, window: _wide, body: _kai());

      for (final (left, right) in [('Rua', 'Nia'), ('Alex', 'Sam')]) {
        final leftTile = tester.getRect(_tileAround(find.text(left)));
        final rightTile = tester.getRect(_tileAround(find.text(right)));
        expect(rightTile.top, leftTile.top, reason: 'on the same line');
        expect(rightTile.left, greaterThan(leftTile.right));
        expect(rightTile.width, moreOrLessEquals(leftTile.width));
      }
    });

    testWidgets(
        'at the largest UI scale, Accept and Decline share one line in a '
        'request tile', (tester) async {
      await _pump(tester, window: _wide, body: _kai());

      final row = _requestRow('Rua');
      final accept = find.descendant(of: row, matching: _button('Accept'));
      final decline = find.descendant(of: row, matching: _button('Decline'));
      expect(tester.getRect(decline).top,
          moreOrLessEquals(tester.getRect(accept).top),
          reason: 'on one line');
      expect(tester.getRect(decline).left,
          greaterThan(tester.getRect(accept).right));
      for (final (button, label) in [
        (accept, 'Accept'),
        (decline, 'Decline'),
      ]) {
        expect(
          _linesOf(
              tester, find.descendant(of: button, matching: find.text(label))),
          1,
          reason: '$label fits its button',
        );
      }
    });

    testWidgets(
        "a friend's whole tile opens them, its rim included, but its ⋮ opens "
        'only the menu', (tester) async {
      final opened = <String>[];
      await _pump(tester, window: _wide, body: _kai(onOpen: opened.add));

      final tile = tester.getRect(_tileAround(find.text('Sam')));
      await tester.tapAt(Offset(tile.left + 4, tile.center.dy));
      expect(opened, ['Sam']);

      await tester.tap(find.descendant(
        of: _friendRow('Sam'),
        matching: find.byIcon(Icons.more_vert),
      ));
      await tester.pumpAndSettle();
      expect(opened, ['Sam'], reason: 'the ⋮ opens its menu, not the friend');
      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets("each ⋮ is within one tile's width of its nickname",
        (tester) async {
      await _pump(tester, window: _wide, body: _kai());

      for (final (row, nickname) in [
        (_requestRow('Rua'), 'Rua'),
        (_requestRow('Nia'), 'Nia'),
        (_friendRow('Alex'), 'Alex'),
        (_friendRow('Sam'), 'Sam'),
      ]) {
        final menu = tester.getCenter(
            find.descendant(of: row, matching: find.byIcon(Icons.more_vert)));
        final name = tester
            .getRect(find.descendant(of: row, matching: find.text(nickname)));
        expect(menu.dx - name.left, lessThan(760 / 2), reason: nickname);
      }
    });

    testWidgets('Add a friend and Sign out keep their own width, on the left',
        (tester) async {
      await _pump(tester, window: _wide, body: _kai());

      final picture = tester.getRect(find.text('K').first);
      for (final label in ['Add a friend', 'Sign out']) {
        final button = tester.getRect(_button(label));
        expect(button.width, greaterThanOrEqualTo(240), reason: label);
        expect(button.width, lessThan(760 / 2), reason: label);
        expect(button.left, lessThanOrEqualTo(picture.left), reason: label);
      }
    });

    testWidgets('with no friends yet, says so across the column',
        (tester) async {
      await _pump(tester, window: _wide, body: _kai(friends: []));

      final line = find.text('No friends yet. Add one with their friend code.');
      expect(_tileAround(line), findsNothing);
      expect(tester.getSize(line).width, greaterThan(760 / 2));
    });
  });

  group('on a phone', () {
    testWidgets('friends and requests are rows, one under another, as before',
        (tester) async {
      await _pump(tester, window: _narrow, body: _kai());

      for (final (upper, lower) in [
        (_requestRow('Rua'), _requestRow('Nia')),
        (_friendRow('Alex'), _friendRow('Sam')),
      ]) {
        for (final row in [upper, lower]) {
          expect(_tileAround(row), findsNothing);
          expect(
              find.descendant(of: row, matching: find.byType(SurfaceCardAtom)),
              findsNothing);
        }
        expect(tester.getRect(lower).top,
            greaterThanOrEqualTo(tester.getRect(upper).bottom));
        expect(tester.getSize(upper).width, 320);
      }
    });

    testWidgets('Add a friend and Sign out are as wide as the column',
        (tester) async {
      await _pump(tester, window: _narrow, body: _kai());

      for (final label in ['Add a friend', 'Sign out']) {
        expect(tester.getSize(_button(label)).width, 320, reason: label);
      }
    });
  });

  group('before setup', () {
    const intro = "Add friends with a friend code and see each other's cards.";
    final card = find.byType(SurfaceCardAtom);
    final setUp = _button('Set up friends');

    testWidgets(
        'says what friends is on a card, under a badge and above Set up '
        'friends, with Sign out below the card', (tester) async {
      await _pump(tester,
          window: _narrow, body: ProfileNotSetUpParams(onSetUp: () {}));

      final badge = find.byType(GlowBadgeAtom);
      for (final part in [badge, find.text(intro), setUp]) {
        expect(find.descendant(of: card, matching: part), findsOneWidget);
      }
      expect(tester.widget<GlowBadgeAtom>(badge).icon, Icons.group_add_rounded);
      expect(tester.widget<GlowBadgeAtom>(badge).color, QuestPalette.violet);
      expect(tester.getRect(badge).bottom,
          lessThanOrEqualTo(tester.getRect(find.text(intro)).top));
      expect(tester.getRect(find.text(intro)).bottom,
          lessThanOrEqualTo(tester.getRect(setUp).top));
      expect(find.descendant(of: card, matching: _button('Sign out')),
          findsNothing);
      expect(tester.getRect(_button('Sign out')).top,
          greaterThan(tester.getRect(card).bottom));
    });

    testWidgets('on a phone, Set up friends fills the card', (tester) async {
      await _pump(tester,
          window: _narrow, body: ProfileNotSetUpParams(onSetUp: () {}));

      expect(tester.getSize(setUp).width,
          greaterThan(tester.getSize(card).width * 0.8));
    });

    testWidgets('on a wide screen, Set up friends keeps its own width',
        (tester) async {
      await _pump(tester,
          window: _wide, body: ProfileNotSetUpParams(onSetUp: () {}));

      expect(tester.getSize(setUp).width,
          lessThan(tester.getSize(card).width / 2));
      expect(tester.getCenter(setUp).dx,
          moreOrLessEquals(tester.getCenter(card).dx));
    });
  });

  group('the level card', () {
    final card = LevelCardParams(
      level: const Level(number: 21, suns: 1, moons: 1, stars: 1),
      title: 'Level 21',
      barFill: 23 / 47,
      nextLevelIcon: LevelIcon.star,
      activeDaysLabel: '548 active days',
      daysToGoLabel: '24 days',
      toNextIconLabel: 'to your next star',
      onExplain: () {},
    );
    final shown = find.byType(LevelCardOrganism);

    testWidgets(
        'sits under the picture, nickname and friend code once friends is '
        'set up, above Add a friend', (tester) async {
      await _pump(tester, window: _narrow, body: _kai(), levelCard: card);

      final rect = tester.getRect(shown);
      expect(rect.top,
          greaterThanOrEqualTo(tester.getRect(find.text('K7QM-2XPA')).bottom));
      expect(rect.bottom,
          lessThanOrEqualTo(tester.getRect(_button('Add a friend')).top));
    });

    testWidgets(
        'on a wide screen sits beside the picture, nickname and friend code, '
        'the two splitting the line as the friend tiles below do',
        (tester) async {
      await _pump(tester, window: _wide, body: _kai(), levelCard: card);

      final rect = tester.getRect(shown);
      final header = tester.getRect(find.byType(ProfileHeaderOrganism));
      final leftTile = tester.getRect(_tileAround(find.text('Alex')));
      final rightTile = tester.getRect(_tileAround(find.text('Sam')));
      expect(header.center.dy, moreOrLessEquals(rect.center.dy),
          reason: 'on one row, the header centred against the card');
      expect(header.left, moreOrLessEquals(leftTile.left));
      expect(header.right, moreOrLessEquals(leftTile.right));
      expect(rect.left, moreOrLessEquals(rightTile.left));
      expect(rect.right, moreOrLessEquals(rightTile.right));
      expect(rect.bottom,
          lessThanOrEqualTo(tester.getRect(_button('Add a friend')).top));
    });

    testWidgets(
        'on a wide screen, screen readers still hear the card on its own, '
        'not as part of the header', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, window: _wide, body: _kai(), levelCard: card);

      expect(
          find.bySemanticsLabel(RegExp(r'Kai[\s\S]*Level 21')), findsNothing);
      expect(find.bySemanticsLabel(RegExp(r'^Level 21')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets(
        'on a wide screen, before a count brings the card, the header keeps '
        'the whole line', (tester) async {
      await _pump(tester, window: _wide, body: _kai());

      final header = tester.getRect(find.byType(ProfileHeaderOrganism));
      expect(
          header.right,
          moreOrLessEquals(
              tester.getRect(_tileAround(find.text('Sam'))).right));
    });

    testWidgets('sits above the friends intro before setup', (tester) async {
      await _pump(
        tester,
        window: _narrow,
        body: ProfileNotSetUpParams(onSetUp: () {}),
        levelCard: card,
      );

      const intro =
          "Add friends with a friend code and see each other's cards.";
      expect(tester.getRect(shown).bottom,
          lessThanOrEqualTo(tester.getRect(find.text(intro)).top));
    });

    testWidgets('sits above the message when friends is turned off',
        (tester) async {
      const turnedOff = 'Friends is turned off for your account.';
      await _pump(
        tester,
        window: _narrow,
        body: const ProfileTurnedOffParams(message: turnedOff),
        levelCard: card,
      );

      expect(tester.getRect(shown).bottom,
          lessThanOrEqualTo(tester.getRect(find.text(turnedOff)).top));
    });

    testWidgets("sits above the error when friends can't load", (tester) async {
      const error = "We couldn't load your friends.";
      await _pump(
        tester,
        window: _narrow,
        body: ProfileErrorParams(message: error, onRetry: () {}),
        levelCard: card,
      );

      expect(tester.getRect(shown).bottom,
          lessThanOrEqualTo(tester.getRect(find.text(error)).top));
    });

    testWidgets('is not there without a level', (tester) async {
      await _pump(tester, window: _narrow, body: _kai());

      expect(shown, findsNothing);
    });
  });
}
