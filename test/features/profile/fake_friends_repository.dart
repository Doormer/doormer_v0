import 'dart:async';

import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/features/profile/domain/entity/found_student.dart';
import 'package:doormer/src/features/profile/domain/entity/friend_profile.dart';
import 'package:doormer/src/features/profile/domain/entity/friend_request.dart';
import 'package:doormer/src/features/profile/domain/entity/picture_choice.dart';
import 'package:doormer/src/features/profile/domain/entity/report_reason.dart';
import 'package:doormer/src/features/profile/domain/repository/friends_repository.dart';
import 'package:doormer/src/shared/friends/entity/card_picture.dart';
import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:doormer/src/shared/friends/friends_messages.dart';

// Pictures with no art, so widget tests never wait on the network: each
// shows its first letter, as it would if its art failed to load.
const gnomon = CardPicture(deckId: 'meridian-01', cardId: 'gnomon', artUrl: '');
const vernier =
    CardPicture(deckId: 'meridian-01', cardId: 'vernier', artUrl: '');

const kai = FriendSummary(friendId: '1', nickname: 'Kai', picture: gnomon);
const alex = FriendSummary(friendId: '7', nickname: 'Alex');
const sam = FriendSummary(friendId: '42', nickname: 'Sam', picture: vernier);
const rua = FriendSummary(friendId: '55', nickname: 'Rua');
const tama = FriendSummary(friendId: '66', nickname: 'Tama');
const nia = FriendSummary(friendId: '88', nickname: 'Nia');

/// Kai's own friend code, and the codes of the students the fake knows.
const kaiCode = 'K7QM2XPA';
const alexCode = 'ALEX7777';
const ruaCode = 'RUAR5555';
const tamaCode = 'TAMA6666';
const niaCode = 'NEWS2345';

/// Kai's friend profile at the start.
const kaiProfile = FriendProfile(
  hasProfile: true,
  nickname: 'Kai',
  picture: gnomon,
  friendCode: kaiCode,
  friendsTurnedOff: false,
  waitingRequests: 1,
);

final ruaRequest = FriendRequest(
  requestId: '9',
  from: rua,
  sentAt: DateTime.utc(2026, 10, 26, 9),
);

/// Plays the friends API in memory for the profile feature's tests.
///
/// The student is Kai, set up, with two friends (Alex and Sam), a request
/// from Rua, Tama blocked, and two cards to pick a picture from. Nia can be
/// found by code. Every action changes what the next read returns, as the
/// API would. A test can make one kind of call fail, or hold every call open
/// until it lets them answer.
class FakeFriendsRepository implements FriendsRepository {
  FriendProfile profile = kaiProfile;
  List<FriendRequest> requests = [ruaRequest];
  List<FriendSummary> friends = [alex, sam];
  List<FriendSummary> blocked = [tama];
  List<PictureChoice> pictureChoices = const [
    PictureChoice(picture: gnomon, name: 'Gnomon'),
    PictureChoice(picture: vernier, name: 'Vernier'),
  ];
  final Map<String, FriendSummary> studentsByCode = {
    alexCode: alex,
    ruaCode: rua,
    tamaCode: tama,
    niaCode: nia,
  };

  /// The students Kai has a request waiting with.
  final Set<String> requestedIds = {};

  /// Every call, in order, with what it was given.
  final List<String> calls = [];

  /// The next call of each kind named here fails with its failure.
  final Map<String, Object> failNext = {};

  /// While set, every call waits for it before it answers.
  Completer<void>? hold;

  /// The codes [resetCode] hands out, in turn.
  static const newCodes = ['ZQ9X4W2T', 'MX3V7K8P'];
  int _codesMade = 0;

  Future<void> _call(String name, [String details = '']) async {
    calls.add(details.isEmpty ? name : '$name $details');
    final wait = hold;
    if (wait != null) await wait.future;
    final failure = failNext.remove(name);
    if (failure != null) throw failure;
  }

  /// A profile set up as Kai has it now, with [changes] made.
  FriendProfile _profileWith({
    String? nickname,
    CardPicture? picture,
    bool keepPicture = true,
    String? friendCode,
  }) =>
      FriendProfile(
        hasProfile: true,
        nickname: nickname ?? profile.nickname,
        picture: keepPicture ? profile.picture : picture,
        friendCode: friendCode ?? profile.friendCode,
        friendsTurnedOff: profile.friendsTurnedOff,
        waitingRequests: requests.length,
      );

  void _addFriend(FriendSummary friend) {
    friends = [
      ...friends.where((f) => f.friendId != friend.friendId),
      friend
    ]..sort(
        (a, b) => a.nickname.toLowerCase().compareTo(b.nickname.toLowerCase()));
  }

  @override
  Future<FriendProfile> loadProfile() async {
    await _call('loadProfile');
    return profile;
  }

  @override
  Future<FriendProfile> saveProfile({
    required String nickname,
    CardPicture? picture,
  }) async {
    await _call('saveProfile', '$nickname ${picture?.cardId}');
    return profile = _profileWith(
      nickname: nickname,
      picture: picture,
      keepPicture: false,
      friendCode: profile.hasProfile ? null : kaiCode,
    );
  }

  @override
  Future<List<PictureChoice>> loadPictureChoices() async {
    await _call('loadPictureChoices');
    return pictureChoices;
  }

  @override
  Future<FriendProfile> resetCode() async {
    await _call('resetCode');
    return profile = _profileWith(
      friendCode: newCodes[_codesMade++ % newCodes.length],
    );
  }

  @override
  Future<FoundStudent> findStudent(String friendCode) async {
    await _call('findStudent', friendCode);
    if (friendCode == profile.friendCode) {
      return const FoundStudent(student: kai, relation: FriendRelation.you);
    }
    final student = studentsByCode[friendCode];
    if (student == null) {
      throw RefusedFailure(404, FriendsMessages.codeNotFound);
    }
    return FoundStudent(student: student, relation: _relationTo(student));
  }

  FriendRelation _relationTo(FriendSummary student) {
    bool isIn(List<FriendSummary> list) =>
        list.any((other) => other.friendId == student.friendId);
    if (isIn(friends)) return FriendRelation.friends;
    if (isIn(blocked)) return FriendRelation.blockedByYou;
    if (requests.any((r) => r.from.friendId == student.friendId)) {
      return FriendRelation.requestReceived;
    }
    if (requestedIds.contains(student.friendId)) {
      return FriendRelation.requestSent;
    }
    return FriendRelation.none;
  }

  @override
  Future<List<FriendRequest>> loadRequests() async {
    await _call('loadRequests');
    return requests;
  }

  @override
  Future<SendFriendRequestResult> sendRequest(
    String friendCode,
    FriendRequestVia via,
  ) async {
    await _call('sendRequest', '$friendCode ${via.name}');
    final student = studentsByCode[friendCode];
    if (student == null) {
      throw RefusedFailure(404, FriendsMessages.codeNotFound);
    }
    final theirs =
        requests.where((r) => r.from.friendId == student.friendId).firstOrNull;
    if (theirs != null) {
      requests = [...requests]..remove(theirs);
      _addFriend(student);
      return SendFriendRequestResult.nowFriends;
    }
    requestedIds.add(student.friendId);
    return SendFriendRequestResult.sent;
  }

  @override
  Future<FriendSummary> acceptRequest(String requestId) async {
    await _call('acceptRequest', requestId);
    final request = requests.firstWhere((r) => r.requestId == requestId);
    requests = [...requests]..remove(request);
    _addFriend(request.from);
    return request.from;
  }

  @override
  Future<void> declineRequest(String requestId) async {
    await _call('declineRequest', requestId);
    requests = [...requests.where((r) => r.requestId != requestId)];
  }

  @override
  Future<List<FriendSummary>> loadFriends() async {
    await _call('loadFriends');
    return friends;
  }

  @override
  Future<void> removeFriend(String friendId) async {
    await _call('removeFriend', friendId);
    friends = [...friends.where((f) => f.friendId != friendId)];
  }

  @override
  Future<void> blockStudent(String friendId) async {
    await _call('blockStudent', friendId);
    final student = [...friends, for (final r in requests) r.from]
        .firstWhere((s) => s.friendId == friendId);
    friends = [...friends.where((f) => f.friendId != friendId)];
    requests = [...requests.where((r) => r.from.friendId != friendId)];
    blocked = [student, ...blocked];
  }

  @override
  Future<void> unblockStudent(String friendId) async {
    await _call('unblockStudent', friendId);
    blocked = [...blocked.where((s) => s.friendId != friendId)];
  }

  @override
  Future<List<FriendSummary>> loadBlockedStudents() async {
    await _call('loadBlockedStudents');
    return blocked;
  }

  @override
  Future<void> reportStudent(
    String friendId, {
    required ReportReason reason,
    required String note,
  }) async {
    await _call('reportStudent', '$friendId ${reason.name} $note'.trim());
  }
}
