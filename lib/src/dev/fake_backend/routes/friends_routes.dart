import 'package:doormer/src/dev/fake_backend/fake_backend_state.dart';
import 'package:doormer/src/dev/fake_backend/fake_decks.dart';
import 'package:doormer/src/dev/fake_backend/fake_levels.dart';
import 'package:doormer/src/dev/fake_backend/fake_friend_summary.dart';
import 'package:doormer/src/dev/fake_backend/fake_request.dart';
import 'package:doormer/src/dev/fake_backend/fake_response.dart';
import 'package:doormer/src/dev/fake_backend/fake_route.dart';

/// Friends, by `taka-api`'s rules for what the app sends: the student's
/// friend profile, two friends with collections, a request waiting, and a
/// code that can be found (`NEWS2345`). Refusals come back as plain text, as
/// the API sends them; the app shows its own words instead.
///
/// No other student ever answers: a request sent stays "Request sent".
/// Removing or blocking a friend ends every share between the two, and a
/// report can carry a question the friend shared.
class FriendsRoutes {
  /// The codes Reset code hands out, in turn.
  static const _newCodes = ['ZQ9X4W2T', 'MX3V7K8P', 'H6TB9C2W'];

  /// A few words of the API's blocked word list, to try its refusal.
  static const _blockedWords = ['tiktok', 'snap', 'insta'];

  static const _reasons = {'rude_nickname', 'bullying', 'pretending', 'other'};

  static const _badRequest = FakeResponse(400, 'Bad Request');
  static const _notFound = FakeResponse(404, "We couldn't find that.");
  static const _noProfile = FakeResponse(409, 'Set up your nickname first.');

  final FakeBackendState _state;
  int _codesMade = 0;

  FriendsRoutes(this._state);

  FakeFriends get _friends => _state.friends;

  List<FakeRoute> get routes => [
        FakeRoute('POST', '/v1/friends/profile', _profile),
        FakeRoute('POST', '/v1/friends/profile/save', _saveProfile),
        FakeRoute('POST', '/v1/friends/pictures', _pictures),
        FakeRoute('POST', '/v1/friends/code/reset', _withProfile(_resetCode)),
        FakeRoute('POST', '/v1/friends/find', _withProfile(_find)),
        FakeRoute('POST', '/v1/friends/requests', _withProfile(_requests)),
        FakeRoute('POST', '/v1/friends/requests/send', _withProfile(_send)),
        FakeRoute('POST', '/v1/friends/requests/accept', _withProfile(_accept)),
        FakeRoute(
            'POST', '/v1/friends/requests/decline', _withProfile(_decline)),
        FakeRoute('POST', '/v1/friends/list', _withProfile(_list)),
        FakeRoute('POST', '/v1/friends/remove', _withProfile(_remove)),
        FakeRoute('POST', '/v1/friends/block', _withProfile(_block)),
        FakeRoute('POST', '/v1/friends/unblock', _withProfile(_unblock)),
        FakeRoute('POST', '/v1/friends/blocked', _withProfile(_blocked)),
        FakeRoute('POST', '/v1/friends/report', _withProfile(_report)),
        FakeRoute('POST', '/v1/friends/decks', _withProfile(_decks)),
        FakeRoute('POST', '/v1/friends/cards', _withProfile(_cards)),
      ];

  /// Only `profile`, `profile/save` and `pictures` work before setup.
  FakeResponse Function(FakeRequest) _withProfile(
    FakeResponse Function(FakeRequest request, FakeFriendProfile profile)
        answer,
  ) =>
      (request) {
        final profile = _friends.profile;
        return profile == null ? _noProfile : answer(request, profile);
      };

  FakeResponse _profile(FakeRequest request) => FakeResponse.ok(_profileJson());

  FakeResponse _saveProfile(FakeRequest request) {
    final fields = request.fields;
    final nickname = fields['nickname'];
    final deckId = fields['picture_deck_id'] ?? '';
    final cardId = fields['picture_card_id'] ?? '';
    if (nickname is! String ||
        deckId is! String ||
        cardId is! String ||
        deckId.isEmpty != cardId.isEmpty) {
      return _badRequest;
    }
    final tidied = nickname.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (tidied.length < 3 || tidied.length > 16) {
      return const FakeResponse(422, 'Use 3 to 16 characters.');
    }
    if (_blockedWords.any(tidied.toLowerCase().contains)) {
      return const FakeResponse(422, 'Please pick a different nickname.');
    }
    final FakePicture? picture =
        deckId.isEmpty ? null : (deckId: deckId, cardId: cardId);
    if (picture != null && _copiesHeld(deckId, cardId) == 0) {
      return const FakeResponse(422, 'You can only pick a card you own.');
    }

    final profile = _friends.profile;
    if (profile == null) {
      _friends.profile = FakeFriendProfile(
        nickname: tidied,
        picture: picture,
        friendCode: 'K7QM2XPA',
      );
    } else {
      profile
        ..nickname = tidied
        ..picture = picture;
    }
    return FakeResponse.ok(_profileJson());
  }

  /// One per card the student holds, in catalog order.
  FakeResponse _pictures(FakeRequest request) => FakeResponse.ok({
        'pictures': [
          for (final deck in fakeDecks)
            for (final card in deck.cards)
              if (_copiesHeld(deck.id, card.id) > 0)
                {
                  'deck_id': deck.id,
                  'card_id': card.id,
                  'name': card.name,
                  'art_url': card.artUrl,
                },
        ],
      });

  FakeResponse _resetCode(FakeRequest request, FakeFriendProfile profile) {
    profile.friendCode = _newCodes[_codesMade++ % _newCodes.length];
    return FakeResponse.ok(_profileJson());
  }

  FakeResponse _find(FakeRequest request, FakeFriendProfile profile) {
    final code = request.fields['friend_code'];
    if (code is! String) return _badRequest;
    if (code == profile.friendCode) {
      return FakeResponse.ok({
        'student': {
          'friend_id': FakeFriends.studentId,
          'nickname': profile.nickname,
          ...fakePictureField(profile.picture),
        },
        'relation': 'you',
      });
    }
    final student = _friends.studentByCode(code);
    if (student == null) return _notFound;
    return FakeResponse.ok({
      'student': _summary(student),
      'relation': _relationTo(student),
    });
  }

  FakeResponse _requests(FakeRequest request, FakeFriendProfile profile) =>
      FakeResponse.ok({
        'requests': [
          for (final waiting in _friends.waitingRequests)
            {
              'request_id': waiting.id,
              'from': _summary(_friends.studentById(waiting.fromId)!),
              'sent_at': waiting.sentAt.toUtc().toIso8601String(),
            },
        ],
      });

  FakeResponse _send(FakeRequest request, FakeFriendProfile profile) {
    final code = request.fields['friend_code'];
    final via = request.fields['via'];
    if (code is! String || (via != 'code' && via != 'link')) {
      return _badRequest;
    }
    if (code == profile.friendCode) {
      return const FakeResponse(422, "That's your own code.");
    }
    final student = _friends.studentByCode(code);
    if (student == null) return _notFound;
    if (_friends.friendIds.contains(student.id)) {
      return const FakeResponse(409, "You're already friends.");
    }
    if (_friends.blockedIds.contains(student.id)) {
      return const FakeResponse(409, 'You blocked them. Unblock them first.');
    }

    final theirs = _friends.waitingRequests
        .where((waiting) => waiting.fromId == student.id)
        .firstOrNull;
    if (theirs != null) {
      _acceptWaiting(theirs);
      return const FakeResponse.ok({'result': 'now_friends'});
    }
    _friends.requestedIds.add(student.id);
    return const FakeResponse.ok({'result': 'sent'});
  }

  /// Accepting a request already accepted answers with its friend again, as
  /// `taka-api` does.
  FakeResponse _accept(FakeRequest request, FakeFriendProfile profile) {
    final requestId = request.fields['request_id'];
    if (requestId is! String) return _badRequest;
    final waiting = _friends.waitingRequests
        .where((waiting) => waiting.id == requestId)
        .firstOrNull;
    if (waiting != null) _acceptWaiting(waiting);
    final accepted = _friends.acceptedRequests
        .where((accepted) => accepted.id == requestId)
        .firstOrNull;
    if (accepted == null) return _notFound;
    return FakeResponse.ok({
      'friend': _friendSummary(_friends.studentById(accepted.fromId)!),
    });
  }

  /// Makes the sender of [waiting] a friend, and keeps the request as
  /// accepted.
  void _acceptWaiting(FakeFriendRequest waiting) {
    _friends.waitingRequests.remove(waiting);
    _friends.acceptedRequests.add(waiting);
    _friends.friendIds.add(waiting.fromId);
  }

  FakeResponse _decline(FakeRequest request, FakeFriendProfile profile) {
    final requestId = request.fields['request_id'];
    if (requestId is! String) return _badRequest;
    _friends.waitingRequests.removeWhere((waiting) => waiting.id == requestId);
    return const FakeResponse.ok({});
  }

  /// By nickname, ignoring case.
  FakeResponse _list(FakeRequest request, FakeFriendProfile profile) {
    final friends = [
      for (final id in _friends.friendIds) _friends.studentById(id)!,
    ]..sort(
        (a, b) => a.nickname.toLowerCase().compareTo(b.nickname.toLowerCase()));
    return FakeResponse.ok({
      'friends': [for (final friend in friends) _friendSummary(friend)],
    });
  }

  /// Ends the friendship, and every share between the two.
  FakeResponse _remove(FakeRequest request, FakeFriendProfile profile) {
    final friendId = request.fields['friend_id'];
    if (friendId is! String) return _badRequest;
    _friends.endSharesWith(friendId);
    _friends.friendIds.remove(friendId);
    return const FakeResponse.ok({});
  }

  /// Ends the friendship, every share between the two, and declines any
  /// requests between them.
  FakeResponse _block(FakeRequest request, FakeFriendProfile profile) {
    final student = _reachable(request.fields['friend_id']);
    if (student == null) return _notFound;
    _friends.endSharesWith(student.id);
    _friends.friendIds.remove(student.id);
    _friends.requestedIds.remove(student.id);
    _friends.waitingRequests
        .removeWhere((waiting) => waiting.fromId == student.id);
    _friends.blockedIds
      ..remove(student.id)
      ..insert(0, student.id);
    return const FakeResponse.ok({});
  }

  FakeResponse _unblock(FakeRequest request, FakeFriendProfile profile) {
    final friendId = request.fields['friend_id'];
    if (friendId is! String) return _badRequest;
    _friends.blockedIds.remove(friendId);
    return const FakeResponse.ok({});
  }

  FakeResponse _blocked(FakeRequest request, FakeFriendProfile profile) =>
      FakeResponse.ok({
        'blocked': [
          for (final id in _friends.blockedIds)
            _summary(_friends.studentById(id)!),
        ],
      });

  /// A report about a question must name one the student reported shared
  /// with this student, and the share must still stand. That is checked
  /// after the rest of the body, before who can be reported.
  FakeResponse _report(FakeRequest request, FakeFriendProfile profile) {
    final fields = request.fields;
    final reason = fields['reason'];
    final note = fields['note'] ?? '';
    final questionId = fields['question_id'] ?? '';
    // As the API counts it: code points, once trimmed.
    if (!_reasons.contains(reason) ||
        note is! String ||
        note.trim().runes.length > 500 ||
        questionId is! String ||
        (questionId.isNotEmpty && int.tryParse(questionId) == null)) {
      return _badRequest;
    }
    if (questionId.isNotEmpty &&
        _friends.sharerOf(questionId)?.id != fields['friend_id']) {
      return _notFound;
    }
    final student = _reachable(fields['friend_id']);
    if (student == null) return _notFound;
    _friends.reports.add((
      studentId: student.id,
      reason: reason as String,
      note: note,
      questionId: questionId.isEmpty ? null : questionId,
    ));
    return const FakeResponse.ok({});
  }

  /// The friend's decks, as `/collection/decks` sends them, without the
  /// quark balance.
  FakeResponse _decks(FakeRequest request, FakeFriendProfile profile) {
    final friend = _friendIn(request);
    if (friend == null) return _notFound;
    return FakeResponse.ok({
      'friend': _summary(friend),
      'decks': [
        for (final deck in fakeDecks)
          {
            'deck_id': deck.id,
            'name': deck.name,
            'draw_cost': fakeDrawCost,
            'cards_total': deck.cards.length,
            'cards_held': deck.cards
                .where((card) => _copiesOf(friend, deck.id, card.id) > 0)
                .length,
          },
      ],
    });
  }

  /// The friend's cards in one deck, without shatter values.
  FakeResponse _cards(FakeRequest request, FakeFriendProfile profile) {
    final friend = _friendIn(request);
    final deck = fakeDeckById(request.fields['deck_id']?.toString());
    if (friend == null || deck == null) return _notFound;
    return FakeResponse.ok({
      'friend': _summary(friend),
      'deck': {'deck_id': deck.id, 'name': deck.name},
      'cards': [
        for (final card in deck.cards)
          {
            'card_id': card.id,
            'name': card.name,
            'rarity': card.rarity.name,
            'art_url': card.artUrl,
            'attributes': {
              'scale_label': card.scaleLabel,
              'description': card.description,
            },
            'standard_copies':
                friend.holdings[deck.id]?[card.id]?.standardCopies ?? 0,
            'special_copies':
                friend.holdings[deck.id]?[card.id]?.specialCopies ?? 0,
          },
      ],
    });
  }

  Map<String, Object?> _profileJson() {
    final profile = _friends.profile;
    if (profile == null) {
      return {
        'has_profile': false,
        'friends_turned_off': false,
        'waiting_requests': 0,
      };
    }
    return {
      'has_profile': true,
      'nickname': profile.nickname,
      ...fakePictureField(profile.picture),
      'friend_code': profile.friendCode,
      'friends_turned_off': false,
      'waiting_requests': _friends.waitingRequests.length,
    };
  }

  Map<String, Object?> _summary(FakeStudent student) =>
      fakeFriendSummary(student);

  /// A friend as the friends list and an accepted request send them:
  /// [_summary], with their level from level 1. Finding a code, requests,
  /// Blocked, and a friend's decks and cards show students, never a level.
  Map<String, Object?> _friendSummary(FakeStudent student) {
    final level = fakeLevelFor(student.activeDays);
    return {
      ..._summary(student),
      if (level > 0) 'level': fakeLevelJson(level),
    };
  }

  String _relationTo(FakeStudent student) {
    if (_friends.friendIds.contains(student.id)) return 'friends';
    if (_friends.blockedIds.contains(student.id)) return 'blocked_by_you';
    if (_friends.waitingRequests
        .any((waiting) => waiting.fromId == student.id)) {
      return 'request_received';
    }
    if (_friends.requestedIds.contains(student.id)) return 'request_sent';
    return 'none';
  }

  /// A friend, a student who sent a request, or a student blocked: the only
  /// students Block and Report reach.
  FakeStudent? _reachable(Object? friendId) {
    final student = _friends.studentById(friendId?.toString());
    if (student == null) return null;
    final isReachable = _friends.friendIds.contains(student.id) ||
        _friends.blockedIds.contains(student.id) ||
        _friends.waitingRequests.any((waiting) => waiting.fromId == student.id);
    return isReachable ? student : null;
  }

  /// The friend a collection is asked for. Anyone else is no one.
  FakeStudent? _friendIn(FakeRequest request) {
    final friendId = request.fields['friend_id']?.toString();
    if (!_friends.friendIds.contains(friendId)) return null;
    return _friends.studentById(friendId);
  }

  int _copiesHeld(String deckId, String cardId) =>
      _state.holdings[deckId]?[cardId]?.totalCopies ?? 0;

  int _copiesOf(FakeStudent student, String deckId, String cardId) =>
      student.holdings[deckId]?[cardId]?.totalCopies ?? 0;
}
