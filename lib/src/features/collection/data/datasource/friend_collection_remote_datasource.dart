import 'package:dio/dio.dart';
import 'package:doormer/src/core/connection/dio_exception_mapper.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/shared/friends/friends_messages.dart';

import '../model/collection_response_models.dart';

/// A friend's collection, read with `/friends/decks` and `/friends/cards`.
/// Only a friend's can be read: anyone else's is a 404, as a student who
/// doesn't exist is.
///
/// Every method throws a [Failure] whose message a student can read. What the
/// server said is logged, never shown.
abstract class FriendCollectionRemoteDataSource {
  Future<FriendDecksResponseModel> decks(String friendId);

  Future<FriendCardsResponseModel> cards(String friendId, String deckId);
}

class FriendCollectionRemoteDataSourceImpl
    implements FriendCollectionRemoteDataSource {
  /// The words for each status the API refuses with.
  static const _refusals = {
    403: FriendsMessages.turnedOff,
    404: FriendsMessages.friendNotFound,
    429: FriendsMessages.doneTooOftenToday,
  };

  final Dio dio;

  const FriendCollectionRemoteDataSourceImpl({required this.dio});

  @override
  Future<FriendDecksResponseModel> decks(String friendId) => _post(
        '/v1/friends/decks',
        {'friend_id': friendId},
        FriendDecksResponseModel.fromJson,
      );

  @override
  Future<FriendCardsResponseModel> cards(String friendId, String deckId) =>
      _post(
        '/v1/friends/cards',
        {'friend_id': friendId, 'deck_id': deckId},
        FriendCardsResponseModel.fromJson,
      );

  Future<T> _post<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic> json) parse,
  ) async {
    final Response<dynamic> response;
    try {
      response = await dio.post(path, data: body);
    } on DioException catch (e, stackTrace) {
      AppLogger.error('$path failed', error: e, stackTrace: stackTrace);
      final status = e.response?.statusCode;
      final words =
          e.type == DioExceptionType.badResponse ? _refusals[status] : null;
      if (status != null && words != null) throw RefusedFailure(status, words);
      throw dioExceptionToFailure(e,
          userFacingMessage: FriendsMessages.couldNotLoadFriendCards);
    }

    try {
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const FormatException('The response is not a JSON object');
      }
      return parse(data);
    } catch (e, stackTrace) {
      AppLogger.error('$path answered with a response the app cannot read',
          error: e, stackTrace: stackTrace);
      throw UnknownFailure(FriendsMessages.couldNotLoadFriendCards);
    }
  }
}
