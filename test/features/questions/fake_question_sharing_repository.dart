import 'dart:async';

import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/features/questions/domain/entity/shared_question_summary.dart';
import 'package:doormer/src/features/questions/domain/entity/shared_questions_page.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_question_summary.dart';
import 'package:doormer/src/features/questions/domain/repository/question_sharing_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/block_friend_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_friends_to_share_with_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_shared_questions_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/remove_shared_question_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/report_shared_question_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/share_question_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/stop_sharing_question_usecase.dart';
import 'package:doormer/src/features/questions/presentation/bloc/friend_question_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/share_question_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/shared_questions_bloc.dart';
import 'package:doormer/src/shared/friends/entity/card_picture.dart';
import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:doormer/src/shared/friends/entity/report_reason.dart';
import 'package:doormer/src/shared/friends/friends_messages.dart';

// A picture with no art, so widget tests never wait on the network: it shows
// its first letter, as it would if its art failed to load.
const flint = CardPicture(deckId: 'cinder-01', cardId: 'flint', artUrl: '');

const alex = FriendSummary(friendId: '11', nickname: 'Alex');
const kate = FriendSummary(friendId: '13', nickname: 'Kate', picture: flint);
const sam = FriendSummary(friendId: '7', nickname: 'Sam');

/// The student's own question that the tests share.
const ownQuestionId = '501';

/// The question Sam shared with the student.
final samsQuestion = SharedQuestionSummary(
  question: SolvedQuestionSummary(
    questionId: '301',
    topic: 'Algebra - Simultaneous equations',
    method: 'Elimination',
    questionText: 'Solve 2x + y = 7 and x - y = 2.',
    askedAt: DateTime.utc(2026, 10, 30, 8),
  ),
  sharedBy: sam,
  sharedAt: DateTime.utc(2026, 11, 1, 5, 30),
);

/// Plays the sharing API in memory for the questions feature's tests.
///
/// The student has three friends, Alex, Kate and Sam, by nickname, and Sam
/// has shared one question with them. Every action changes what the next
/// read returns, as the API would: sharing with someone who is no longer a
/// friend is refused with 404, and nothing is shared. A test can make one
/// kind of call fail, hold every call open until it lets them all answer, or
/// hold calls one at a time and let each answer in its own turn.
class FakeQuestionSharingRepository implements QuestionSharingRepository {
  List<FriendSummary> friends = [alex, kate, sam];

  /// Who each of the student's own questions is shared with, by question ID.
  final Map<String, List<FriendSummary>> sharedWith = {};

  /// Shared with me, as the pages each cursor asks for. No cursor asks for
  /// the first.
  Map<String?, SharedQuestionsPage> sharedPages = {
    null: SharedQuestionsPage(questions: [samsQuestion]),
  };

  /// Every call, in order, with what it was given.
  final List<String> calls = [];

  /// The next call of each kind named here fails with its failure.
  final Map<String, Object> failNext = {};

  /// While set, every call waits for it before it answers.
  Completer<void>? hold;

  /// The next calls each wait for one of these before they answer, in turn:
  /// the first call for the first, the second for the second, and so on. A
  /// test then lets each call answer when it chooses. A call that finds none
  /// left waits for [hold], if it is set.
  final List<Completer<void>> holdInTurn = [];

  Future<void> _call(String name, [String details = '']) async {
    calls.add(details.isEmpty ? name : '$name $details');
    final wait = holdInTurn.isNotEmpty ? holdInTurn.removeAt(0) : hold;
    if (wait != null) await wait.future;
    final failure = failNext.remove(name);
    if (failure != null) throw failure;
  }

  @override
  Future<List<FriendSummary>> loadFriends() async {
    await _call('loadFriends');
    return friends;
  }

  @override
  Future<List<FriendSummary>> share(
    String questionId,
    List<String> friendIds,
  ) async {
    await _call('share', '$questionId ${friendIds.join(',')}');
    final current = {for (final friend in friends) friend.friendId: friend};
    if (!friendIds.every(current.containsKey)) {
      throw RefusedFailure(404, FriendsMessages.friendsListChanged);
    }
    final ids = {
      for (final friend in sharedWith[questionId] ?? const <FriendSummary>[])
        friend.friendId,
      ...friendIds,
    };
    return sharedWith[questionId] = [
      for (final friend in friends)
        if (ids.contains(friend.friendId)) friend,
    ];
  }

  @override
  Future<void> stopSharing(String questionId) async {
    await _call('stopSharing', questionId);
    sharedWith.remove(questionId);
  }

  @override
  Future<SharedQuestionsPage> loadSharedQuestions({String? cursor}) async {
    await _call('loadSharedQuestions', cursor ?? '');
    final page = sharedPages[cursor];
    if (page == null) throw StateError('no page for cursor $cursor');
    return page;
  }

  @override
  Future<void> removeSharedQuestion(String questionId) async {
    await _call('removeSharedQuestion', questionId);
    _dropShared((shared) => shared.question.questionId == questionId);
  }

  @override
  Future<void> reportSharedQuestion({
    required String friendId,
    required String questionId,
    required ReportReason reason,
    required String note,
  }) =>
      _call(
          'reportSharedQuestion', '$friendId $questionId ${reason.name} $note');

  /// Blocking ends every share between the two, and the friendship.
  @override
  Future<void> blockFriend(String friendId) async {
    await _call('blockFriend', friendId);
    friends = [
      for (final friend in friends)
        if (friend.friendId != friendId) friend,
    ];
    _dropShared((shared) => shared.sharedBy.friendId == friendId);
  }

  void _dropShared(bool Function(SharedQuestionSummary shared) dropped) {
    sharedPages = {
      for (final MapEntry(key: cursor, value: page) in sharedPages.entries)
        cursor: SharedQuestionsPage(
          questions: [
            for (final shared in page.questions)
              if (!dropped(shared)) shared,
          ],
          nextCursor: page.nextCursor,
        ),
    };
  }
}

/// Registers the sharing blocs a page asks GetIt for, playing [repository]:
/// the reader shares the student's own question, and acts on a question a
/// friend shared, and Saved lists Shared with me.
void registerQuestionSharingBlocs(FakeQuestionSharingRepository repository) {
  serviceLocator.registerFactory<ShareQuestionBloc>(
    () => ShareQuestionBloc(
      loadFriends: LoadFriendsToShareWithUseCase(repository),
      shareQuestion: ShareQuestionUseCase(repository),
      stopSharing: StopSharingQuestionUseCase(repository),
    ),
  );
  serviceLocator.registerFactory<FriendQuestionBloc>(
    () => FriendQuestionBloc(
      removeSharedQuestion: RemoveSharedQuestionUseCase(repository),
      reportSharedQuestion: ReportSharedQuestionUseCase(repository),
      blockFriend: BlockFriendUseCase(repository),
    ),
  );
  serviceLocator.registerFactory<SharedQuestionsBloc>(
    () => SharedQuestionsBloc(
      loadSharedQuestions: LoadSharedQuestionsUseCase(repository),
    ),
  );
}
