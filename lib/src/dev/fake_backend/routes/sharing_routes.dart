import 'package:doormer/src/dev/fake_backend/fake_backend_state.dart';
import 'package:doormer/src/dev/fake_backend/fake_friend_summary.dart';
import 'package:doormer/src/dev/fake_backend/fake_request.dart';
import 'package:doormer/src/dev/fake_backend/fake_response.dart';
import 'package:doormer/src/dev/fake_backend/fake_route.dart';

/// Sharing questions, by `taka-api`'s rules for what the app sends: Share and
/// Stop sharing on the student's own questions, and Shared with me and Remove
/// for what friends shared. A share shows only while the two are friends.
/// Refusals come back as plain text, as the API sends them; the app shows its
/// own words instead.
///
/// `/questions/solution` and the friends routes that end shares or report a
/// question are answered with the rest of their kind.
class SharingRoutes {
  /// The most friends one share takes.
  static const _maxFriendsPerShare = 10;

  /// The most rows one page of Shared with me holds.
  static const _pageSize = 20;

  static const _badRequest = FakeResponse(400, 'Bad Request');
  static const _noProfile = FakeResponse(409, 'Set up your nickname first.');
  static const _notAFriend = FakeResponse(404, "We couldn't find that.");
  static const _noSuchQuestion =
      FakeResponse(404, "That question doesn't exist.");

  final FakeBackendState _state;
  final DateTime Function() _clock;

  SharingRoutes(this._state, {required DateTime Function() clock})
      : _clock = clock;

  FakeFriends get _friends => _state.friends;

  List<FakeRoute> get routes => [
        FakeRoute('POST', '/v1/questions/share', _share),
        FakeRoute('POST', '/v1/questions/share/stop', _stopSharing),
        FakeRoute('POST', '/v1/questions/shared', _sharedQuestions),
        FakeRoute('POST', '/v1/questions/shared/remove', _removeShared),
      ];

  /// Checks the body, the student's friend profile, each friend, then the
  /// question, and shares with no one unless all pass. Sharing again with a
  /// friend keeps that share.
  FakeResponse _share(FakeRequest request) {
    final questionId = request.fields['question_id'];
    final friendIds = request.fields['friend_ids'];
    if (!_isId(questionId) || friendIds is! List || !friendIds.every(_isId)) {
      return _badRequest;
    }
    final distinct = {for (final id in friendIds) id as String};
    if (distinct.isEmpty || distinct.length > _maxFriendsPerShare) {
      return _badRequest;
    }
    if (_friends.profile == null) return _noProfile;
    if (!distinct.every(_friends.friendIds.contains)) return _notAFriend;
    if (_state.solvedQuestion(questionId as String) == null) {
      return _noSuchQuestion;
    }
    for (final friendId in distinct) {
      _friends.share(
        questionId,
        fromId: FakeFriends.studentId,
        toId: friendId,
        at: _clock(),
      );
    }
    return FakeResponse.ok({
      'shared_with': [
        for (final friend in _friends.sharedWith(questionId))
          fakeFriendSummary(friend),
      ],
    });
  }

  FakeResponse _stopSharing(FakeRequest request) {
    final questionId = request.fields['question_id'];
    if (!_isId(questionId)) return _badRequest;
    if (_state.solvedQuestion(questionId as String) == null) {
      return _noSuchQuestion;
    }
    _friends.shares.removeWhere((share) =>
        share.questionId == questionId &&
        share.fromId == FakeFriends.studentId);
    return const FakeResponse.ok({});
  }

  /// What current friends shared with the student, newest share first, a
  /// page at a time. A page ends on a share ID, which the next request sends
  /// back as its cursor. Before setup there is nothing.
  FakeResponse _sharedQuestions(FakeRequest request) {
    final cursor = request.fields['cursor'];
    if (cursor != null && !_isId(cursor)) return _badRequest;
    final before = cursor == null ? null : int.parse(cursor as String);
    final rows = [
      if (_friends.profile != null)
        for (final share in _friends.shares)
          if (share.toId == FakeFriends.studentId &&
              _friends.friendIds.contains(share.fromId) &&
              (before == null || share.id < before))
            share,
    ];
    final page = rows.take(_pageSize).toList();
    return FakeResponse.ok({
      'questions': [for (final share in page) _sharedRow(share)],
      if (rows.length > page.length) 'next_cursor': '${page.last.id}',
    });
  }

  /// Removing a question that isn't in the list changes nothing.
  FakeResponse _removeShared(FakeRequest request) {
    final questionId = request.fields['question_id'];
    if (!_isId(questionId)) return _badRequest;
    _friends.shares.removeWhere((share) =>
        share.questionId == questionId && share.toId == FakeFriends.studentId);
    return const FakeResponse.ok({});
  }

  /// A solved question's fields, and who shared it and when, at one level.
  Map<String, Object?> _sharedRow(FakeShare share) {
    final asked = _friends.friendQuestion(share.questionId)!.question;
    return {
      'question_id': asked.id,
      'topic': asked.topic,
      'method': asked.method,
      'question_text': asked.questionText,
      'asked_at': asked.askedAt.toUtc().toIso8601String(),
      'shared_by': fakeFriendSummary(_friends.studentById(share.fromId)!),
      'shared_at': share.sharedAt.toUtc().toIso8601String(),
    };
  }

  /// IDs are numbers sent as strings.
  static bool _isId(Object? id) => id is String && int.tryParse(id) != null;
}
