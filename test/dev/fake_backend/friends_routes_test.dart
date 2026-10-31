import 'package:dio/dio.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/dev/fake_backend/fake_backend.dart';
import 'package:doormer/src/features/collection/data/datasource/friend_collection_remote_datasource.dart';
import 'package:doormer/src/features/profile/data/datasource/friends_remote_datasource.dart';
import 'package:doormer/src/features/profile/domain/entity/found_student.dart';
import 'package:doormer/src/features/profile/domain/entity/friend_request.dart';
import 'package:doormer/src/features/profile/domain/entity/report_reason.dart';
import 'package:doormer/src/shared/friends/entity/card_picture.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher _refused(int status, String message) => throwsA(isA<RefusedFailure>()
    .having((f) => f.statusCode, 'statusCode', status)
    .having((f) => f.message, 'message', message));

void main() {
  setUpAll(AppLogger.disable);

  late Dio dio;
  late FriendsRemoteDataSource friends;
  late FriendCollectionRemoteDataSource collections;

  setUp(() {
    dio = Dio(BaseOptions(
      baseUrl: 'https://api.test',
      headers: {'Authorization': 'Bearer test-token'},
    ))
      ..httpClientAdapter = fakeBackend(
        delay: Duration.zero,
        solveDelay: Duration.zero,
        clock: () => DateTime.utc(2026, 10, 26, 9),
      );
    friends = FriendsRemoteDataSourceImpl(dio: dio);
    collections = FriendCollectionRemoteDataSourceImpl(dio: dio);
  });

  Future<List<String>> friendNames() async =>
      [for (final friend in await friends.friends()) friend.nickname];

  Future<FriendRelation> relationTo(String code) async =>
      (await friends.find(code)).toEntity().relation;

  Future<void> signUp() async {
    await dio.post('/v1/signup',
        data: {'email': 'mere@example.test', 'password': 'secret'});
  }

  Future<void> signIn() async {
    await dio.post('/v1/login',
        data: {'email': 'kai@example.test', 'password': 'secret'});
  }

  test('starts set up, with two friends and a request from Rua', () async {
    final profile = (await friends.profile()).toEntity();
    final requests = await friends.requests();

    expect(profile.hasProfile, isTrue);
    expect(profile.nickname, 'Kai');
    expect(profile.friendCode, 'K7QM2XPA');
    expect(profile.picture?.cardId, 'gnomon');
    expect(profile.waitingRequests, 1);
    expect(await friendNames(), ['Alex', 'Sam']);
    expect(requests.single.from.nickname, 'Rua');
    expect(requests.single.sentAt, DateTime.utc(2026, 10, 26, 7));
  });

  test('a student who signs up has no friend profile until their first save',
      () async {
    await signUp();

    final profile = (await friends.profile()).toEntity();

    expect(profile.hasProfile, isFalse);
    expect(profile.waitingRequests, 0);
    await expectLater(
      friends.friends(),
      throwsA(isA<ApiFailure>()
          .having((f) => f.statusCode, 'statusCode', 409)
          .having((f) => f.message, 'message',
              "Error 409: We couldn't load your friends.")),
    );

    final saved = (await friends.saveProfile(nickname: 'Mere')).toEntity();

    expect(saved.hasProfile, isTrue);
    expect(saved.nickname, 'Mere');
    expect(saved.friendCode, 'K7QM2XPA');
    expect(await relationTo(saved.friendCode), FriendRelation.you);
  });

  test("signing in, unlike signing up, keeps Kai's friend profile", () async {
    await signIn();

    expect((await friends.profile()).toEntity().nickname, 'Kai');
  });

  test("offers the student's own cards as pictures, in catalog order",
      () async {
    final pictures = await friends.pictures();

    expect([for (final picture in pictures) picture.name],
        ['Gnomon', 'Vernier', 'Astrolabe']);
  });

  test('saves a nickname and picture, and refuses a word on its list',
      () async {
    final saved = (await friends.saveProfile(
      nickname: 'Kai T',
      picture: const CardPicture(
        deckId: 'meridian-01',
        cardId: 'vernier',
        artUrl: '',
      ),
    ))
        .toEntity();

    expect(saved.nickname, 'Kai T');
    expect(saved.picture?.cardId, 'vernier');
    await expectLater(
      friends.saveProfile(nickname: 'tiktok fan'),
      _refused(422, 'Please pick a different nickname.'),
    );
  });

  test('a new code replaces the old one', () async {
    final reset = (await friends.resetCode()).toEntity();

    expect(reset.friendCode, isNot('K7QM2XPA'));
    expect(await relationTo(reset.friendCode), FriendRelation.you);
    await expectLater(
      friends.find('K7QM2XPA'),
      _refused(404, "We couldn't find that code. Check it and try again."),
    );
  });

  test('finds each student by code, and how the two are connected', () async {
    expect(await relationTo('NEWS2345'), FriendRelation.none);
    expect(await relationTo('RUAR5555'), FriendRelation.requestReceived);
    expect(await relationTo('SAMQ2345'), FriendRelation.friends);
    expect(await relationTo('K7QM2XPA'), FriendRelation.you);
    await expectLater(
      friends.find('ZZZZ2222'),
      _refused(404, "We couldn't find that code. Check it and try again."),
    );
  });

  test('a request to Nia stays sent', () async {
    final sent = await friends.sendRequest('NEWS2345', FriendRequestVia.code);

    expect(sent.result, SendFriendRequestResult.sent);
    expect(await relationTo('NEWS2345'), FriendRelation.requestSent);
    await expectLater(
      friends.sendRequest('K7QM2XPA', FriendRequestVia.code),
      _refused(422, "That's your own code."),
    );
  });

  test(
      "a request back to Rua accepts Rua's request, so the two are friends at "
      'once', () async {
    final sent = await friends.sendRequest('RUAR5555', FriendRequestVia.link);

    expect(sent.result, SendFriendRequestResult.nowFriends);
    expect(await friends.requests(), isEmpty);
    expect(await friendNames(), ['Alex', 'Rua', 'Sam']);
    expect((await friends.acceptRequest('501')).friend.nickname, 'Rua');
  });

  test(
      "accepting Rua's request makes them a friend, and accepting it again "
      'answers with Rua again', () async {
    final accepted = await friends.acceptRequest('501');

    expect(accepted.friend.nickname, 'Rua');
    expect(await friendNames(), contains('Rua'));

    final acceptedAgain = await friends.acceptRequest('501');

    expect(acceptedAgain.friend.nickname, 'Rua');
  });

  test('declining takes the request away', () async {
    await friends.declineRequest('501');

    expect(await friends.requests(), isEmpty);
    expect(await friendNames(), isNot(contains('Rua')));
  });

  test("removing Sam ends the friendship, and Sam's collection with it",
      () async {
    await friends.remove('201');

    expect(await friendNames(), ['Alex']);
    await expectLater(collections.decks('201'),
        _refused(404, "We couldn't find that friend."));
  });

  test('blocking Rua declines the request; unblocking leaves the two apart',
      () async {
    await friends.block('203');

    expect(await friends.requests(), isEmpty);
    expect([for (final s in await friends.blocked()) s.nickname], ['Rua']);
    expect(await relationTo('RUAR5555'), FriendRelation.blockedByYou);

    await friends.unblock('203');

    expect(await friends.blocked(), isEmpty);
    expect(await relationTo('RUAR5555'), FriendRelation.none);
  });

  test('block and report reach only friends and students who sent a request',
      () async {
    await friends.report('201', ReportReason.bullying, 'Mean in class.');

    await expectLater(
        friends.block('204'), _refused(404, "We couldn't find that student."));
    await expectLater(friends.report('204', ReportReason.other, ''),
        _refused(404, "We couldn't find that student."));
  });

  test("shows Sam's decks and cards, with nothing to shatter", () async {
    final decks = await collections.decks('201');
    final cinder = (await collections.cards('201', 'cinder-01')).toEntity();

    expect(decks.friend.nickname, 'Sam');
    expect(
      [for (final deck in decks.decks) (deck.name, deck.cardsHeld)],
      [('Cinder', 3), ('Meridian', 0)],
    );
    expect(cinder.holdingOf('flint')?.standardCopies, 2);
    expect(cinder.holdingOf('kiln')?.specialCopies, 1);
    expect(cinder.holdingOf('flint')?.card.standardShatterQuarks, 0);
  });

  test("a student who isn't a friend has no collection to see", () async {
    await expectLater(collections.decks('204'),
        _refused(404, "We couldn't find that friend."));
  });
}
