import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/features/profile/data/datasource/friends_remote_datasource.dart';
import 'package:doormer/src/features/profile/data/model/friends_response_models.dart';
import 'package:doormer/src/features/profile/data/repository/friends_repository_impl.dart';
import 'package:doormer/src/features/profile/domain/entity/found_student.dart';
import 'package:doormer/src/features/profile/domain/entity/friend_request.dart';
import 'package:doormer/src/shared/friends/entity/card_picture.dart';
import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:doormer/src/shared/friends/entity/report_reason.dart';
import 'package:doormer/src/shared/friends/model/card_picture_model.dart';
import 'package:doormer/src/shared/friends/model/friend_summary_model.dart';
import 'package:flutter_test/flutter_test.dart';

const _gnomon = CardPictureModel(
  deckId: 'meridian-01',
  cardId: 'gnomon',
  artUrl: 'https://example.test/gnomon.png',
);
const _sam =
    FriendSummaryModel(friendId: '42', nickname: 'Sam', picture: _gnomon);

/// Answers like the API, and records what it was asked. Set [failure] to make
/// every call fail with it instead.
class _FakeRemoteDataSource implements FriendsRemoteDataSource {
  Failure? failure;
  final List<String> calls = [];

  void _record(String call) {
    calls.add(call);
    final failure = this.failure;
    if (failure != null) throw failure;
  }

  @override
  Future<FriendProfileModel> profile() async {
    _record('profile');
    return const FriendProfileModel(
      hasProfile: true,
      nickname: 'Kai',
      picture: _gnomon,
      friendCode: 'K7QM2XPA',
      friendsTurnedOff: false,
      waitingRequests: 1,
    );
  }

  @override
  Future<FriendProfileModel> saveProfile({
    required String nickname,
    CardPicture? picture,
  }) async {
    _record('saveProfile $nickname ${picture?.cardId}');
    return FriendProfileModel(
      hasProfile: true,
      nickname: nickname,
      friendCode: 'K7QM2XPA',
      friendsTurnedOff: false,
      waitingRequests: 0,
    );
  }

  @override
  Future<List<PictureChoiceModel>> pictures() async {
    _record('pictures');
    return const [PictureChoiceModel(picture: _gnomon, name: 'Gnomon')];
  }

  @override
  Future<FriendProfileModel> resetCode() async {
    _record('resetCode');
    return const FriendProfileModel(
      hasProfile: true,
      nickname: 'Kai',
      friendCode: 'NEWCODE2',
      friendsTurnedOff: false,
      waitingRequests: 0,
    );
  }

  @override
  Future<FoundStudentModel> find(String friendCode) async {
    _record('find $friendCode');
    return const FoundStudentModel(
        student: _sam, relation: FriendRelation.friends);
  }

  @override
  Future<List<FriendRequestModel>> requests() async {
    _record('requests');
    return [
      FriendRequestModel(
        requestId: '9',
        from: _sam,
        sentAt: DateTime.utc(2026, 10, 26),
      ),
    ];
  }

  @override
  Future<SendFriendRequestResponseModel> sendRequest(
    String friendCode,
    FriendRequestVia via,
  ) async {
    _record('sendRequest $friendCode ${via.name}');
    return const SendFriendRequestResponseModel(
        result: SendFriendRequestResult.nowFriends);
  }

  @override
  Future<AcceptFriendRequestResponseModel> acceptRequest(
      String requestId) async {
    _record('acceptRequest $requestId');
    return const AcceptFriendRequestResponseModel(friend: _sam);
  }

  @override
  Future<void> declineRequest(String requestId) async =>
      _record('declineRequest $requestId');

  @override
  Future<List<FriendSummaryModel>> friends() async {
    _record('friends');
    return const [_sam];
  }

  @override
  Future<void> remove(String friendId) async => _record('remove $friendId');

  @override
  Future<void> block(String friendId) async => _record('block $friendId');

  @override
  Future<void> unblock(String friendId) async => _record('unblock $friendId');

  @override
  Future<List<FriendSummaryModel>> blocked() async {
    _record('blocked');
    return const [_sam];
  }

  @override
  Future<void> report(
          String friendId, ReportReason reason, String note) async =>
      _record('report $friendId ${reason.name} $note');
}

const _samEntity = FriendSummary(
  friendId: '42',
  nickname: 'Sam',
  picture: CardPicture(
    deckId: 'meridian-01',
    cardId: 'gnomon',
    artUrl: 'https://example.test/gnomon.png',
  ),
);

void main() {
  late _FakeRemoteDataSource remote;
  late FriendsRepositoryImpl repository;

  setUp(() {
    remote = _FakeRemoteDataSource();
    repository = FriendsRepositoryImpl(remoteDataSource: remote);
  });

  test('the profile comes back in the domain terms', () async {
    final profile = await repository.loadProfile();

    expect(profile.nickname, 'Kai');
    expect(profile.picture, _samEntity.picture);
    expect(profile.friendCode, 'K7QM2XPA');
    expect(profile.waitingRequests, 1);
  });

  test('saving passes the nickname and picture through', () async {
    await repository.saveProfile(nickname: 'Kai', picture: _samEntity.picture);

    expect(remote.calls, ['saveProfile Kai gnomon']);
  });

  test('lists come back as entities', () async {
    expect((await repository.loadPictureChoices()).single.name, 'Gnomon');
    expect((await repository.loadRequests()).single.from, _samEntity);
    expect(await repository.loadFriends(), [_samEntity]);
    expect(await repository.loadBlockedStudents(), [_samEntity]);
  });

  test('finding, sending and accepting answer in the domain terms', () async {
    final found = await repository.findStudent('K7QM2XPA');
    final sent =
        await repository.sendRequest('K7QM2XPA', FriendRequestVia.link);
    final friend = await repository.acceptRequest('9');

    expect(found.student, _samEntity);
    expect(found.relation, FriendRelation.friends);
    expect(sent, SendFriendRequestResult.nowFriends);
    expect(friend, _samEntity);
    expect(remote.calls, [
      'find K7QM2XPA',
      'sendRequest K7QM2XPA link',
      'acceptRequest 9',
    ]);
  });

  test('actions pass their ids through', () async {
    await repository.declineRequest('9');
    await repository.removeFriend('42');
    await repository.blockStudent('42');
    await repository.unblockStudent('42');
    await repository.reportStudent('42',
        reason: ReportReason.pretending, note: 'Not them.');

    expect(remote.calls, [
      'declineRequest 9',
      'remove 42',
      'block 42',
      'unblock 42',
      'report 42 pretending Not them.',
    ]);
  });

  test('a failure reaches the caller unchanged', () async {
    final failure = RefusedFailure(404, "We couldn't find that student.");
    remote.failure = failure;

    await expectLater(repository.blockStudent('42'), throwsA(same(failure)));
  });
}
