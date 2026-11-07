import 'package:dio/dio.dart';
import 'package:doormer/src/core/connection/dio_exception_mapper.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/shared/friends/entity/report_reason.dart';
import 'package:doormer/src/shared/friends/friends_messages.dart';
import 'package:doormer/src/shared/friends/model/friend_summary_model.dart';
import 'package:doormer/src/shared/friends/model/report_reason_model.dart';

import '../model/shared_questions_response_model.dart';

/// The routes for sharing questions, and the friends routes sharing needs:
/// the friends to share with, and Report and Block on a question a friend
/// shared.
///
/// Every method throws a [Failure] whose message a student can read. What the
/// server said is logged, never shown.
abstract class QuestionSharingRemoteDataSource {
  /// The student's friends, by nickname, ignoring case.
  Future<List<FriendSummaryModel>> friends();

  /// Shares [questionId] with [friendIds], and answers with every friend it
  /// is now shared with.
  Future<List<FriendSummaryModel>> share(
    String questionId,
    List<String> friendIds,
  );

  /// Takes [questionId] out of every friend's Shared with me.
  Future<void> stopSharing(String questionId);

  /// One page of the questions friends shared with the student, newest share
  /// first. No cursor asks for the first page.
  Future<SharedQuestionsResponseModel> sharedQuestions({String? cursor});

  /// Takes [questionId] out of the student's own Shared with me.
  Future<void> removeSharedQuestion(String questionId);

  /// Reports [friendId], with [questionId], which they shared with the
  /// student.
  Future<void> report({
    required String friendId,
    required String questionId,
    required ReportReason reason,
    required String note,
  });

  Future<void> block(String friendId);
}

class QuestionSharingRemoteDataSourceImpl
    implements QuestionSharingRemoteDataSource {
  final Dio dio;

  const QuestionSharingRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<FriendSummaryModel>> friends() => _post(
        '/v1/friends/list',
        const {},
        (json) => FriendSummaryModel.listFromJson(json, 'friends'),
        callMessage: FriendsMessages.couldNotLoadFriends,
        refusals: const {409: FriendsMessages.addFriendsToShare},
      );

  @override
  Future<List<FriendSummaryModel>> share(
    String questionId,
    List<String> friendIds,
  ) =>
      _post(
        '/v1/questions/share',
        {'question_id': questionId, 'friend_ids': friendIds},
        (json) => FriendSummaryModel.listFromJson(json, 'shared_with'),
        callMessage: FriendsMessages.couldNotShare,
        refusals: const {
          // A friend ID that is no longer a friend's. The question is the
          // student's own, so it is never the question that is missing.
          404: FriendsMessages.friendsListChanged,
          409: FriendsMessages.addFriendsToShare,
          422: FriendsMessages.onlySolvedCanBeShared,
        },
      );

  @override
  Future<void> stopSharing(String questionId) => _send(
        '/v1/questions/share/stop',
        {'question_id': questionId},
        callMessage: FriendsMessages.couldNotStopSharing,
        refusals: const {404: FriendsMessages.questionNotFound},
      );

  @override
  Future<SharedQuestionsResponseModel> sharedQuestions({String? cursor}) =>
      _post(
        '/v1/questions/shared',
        {if (cursor != null) 'cursor': cursor},
        SharedQuestionsResponseModel.fromJson,
        callMessage: FriendsMessages.couldNotLoadSharedQuestions,
      );

  @override
  Future<void> removeSharedQuestion(String questionId) => _send(
        '/v1/questions/shared/remove',
        {'question_id': questionId},
        callMessage: FriendsMessages.couldNotRemoveSharedQuestion,
      );

  @override
  Future<void> report({
    required String friendId,
    required String questionId,
    required ReportReason reason,
    required String note,
  }) =>
      _send(
        '/v1/friends/report',
        {
          'friend_id': friendId,
          'reason': ReportReasonModel.toJson(reason),
          if (note.isNotEmpty) 'note': note,
          'question_id': questionId,
        },
        callMessage: FriendsMessages.couldNotReport,
        refusals: const {404: FriendsMessages.noLongerShared},
      );

  @override
  Future<void> block(String friendId) => _send(
        '/v1/friends/block',
        {'friend_id': friendId},
        callMessage: FriendsMessages.couldNotBlock,
        refusals: const {404: FriendsMessages.studentNotFound},
      );

  /// Posts [body] to [path] and reads the answer with [parse]. An answer it
  /// cannot read fails with [callMessage].
  Future<T> _post<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic> json) parse, {
    required String callMessage,
    Map<int, String> refusals = const {},
  }) async {
    final response =
        await _send(path, body, callMessage: callMessage, refusals: refusals);
    try {
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const FormatException('The response is not a JSON object');
      }
      return parse(data);
    } catch (e, stackTrace) {
      AppLogger.error('$path answered with a response the app cannot read',
          error: e, stackTrace: stackTrace);
      throw UnknownFailure(callMessage);
    }
  }

  /// Posts [body] to [path]. A status in [refusals], or one any call can
  /// answer with, fails with its own words; anything else fails with
  /// [callMessage].
  Future<Response<dynamic>> _send(
    String path,
    Map<String, dynamic> body, {
    required String callMessage,
    Map<int, String> refusals = const {},
  }) async {
    try {
      return await dio.post(path, data: body);
    } on DioException catch (e, stackTrace) {
      AppLogger.error('$path failed', error: e, stackTrace: stackTrace);
      final status = e.response?.statusCode;
      final words = e.type == DioExceptionType.badResponse
          ? {...FriendsMessages.anyCallRefusals, ...refusals}[status]
          : null;
      if (status != null && words != null) throw RefusedFailure(status, words);
      throw dioExceptionToFailure(e, userFacingMessage: callMessage);
    }
  }
}
