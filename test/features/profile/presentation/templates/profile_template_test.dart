import 'package:doormer/src/core/responsive/responsive_app_shell.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/profile/presentation/molecules/friend_request_row_molecule.dart';
import 'package:doormer/src/features/profile/presentation/molecules/friend_row_molecule.dart';
import 'package:doormer/src/features/profile/presentation/params/friend_request_row_params.dart';
import 'package:doormer/src/features/profile/presentation/params/friend_row_params.dart';
import 'package:doormer/src/features/profile/presentation/params/profile_body_params.dart';
import 'package:doormer/src/features/profile/presentation/params/profile_header_params.dart';
import 'package:doormer/src/features/profile/presentation/templates/profile_template.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/glow_badge_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/surface_card_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A window whose content column is 760 wide: a computer's.
const _wide = Size(760, 1400);

/// A phone's window, 360 wide.
const _narrow = Size(360, 1400);

/// Profile as the app shows it in a [window] of that size.
Future<void> _pump(
  WidgetTester tester, {
  required Size window,
  required ProfileBodyParams body,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = window;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark,
    builder: (context, child) => ResponsiveAppShell(child: child!),
    home: ProfileTemplate(body: body, isSigningOut: false, onSignOut: () {}),
  ));
}

/// Kai, set up, with [friends] and requests from [requesters].
ProfileFriendsParams _kai({
  List<String> friends = const ['Alex', 'Sam'],
  List<String> requesters = const ['Rua', 'Nia'],
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
            onOpen: () {},
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

/// The tile around [row], if it has one.
Finder _tileAround(Finder row) =>
    find.ancestor(of: row, matching: find.byType(SurfaceCardAtom));

void main() {
  group('on a wide screen', () {
    testWidgets('friends and requests sit two to a line, each in a tile',
        (tester) async {
      await _pump(tester, window: _wide, body: _kai());

      for (final (left, right) in [
        (_requestRow('Rua'), _requestRow('Nia')),
        (_friendRow('Alex'), _friendRow('Sam')),
      ]) {
        final leftTile = tester.getRect(_tileAround(left));
        final rightTile = tester.getRect(_tileAround(right));
        expect(rightTile.top, leftTile.top, reason: 'on the same line');
        expect(rightTile.left, greaterThan(leftTile.right));
        expect(rightTile.width, moreOrLessEquals(leftTile.width));
      }
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
        expect(_tileAround(upper), findsNothing);
        expect(_tileAround(lower), findsNothing);
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
}
