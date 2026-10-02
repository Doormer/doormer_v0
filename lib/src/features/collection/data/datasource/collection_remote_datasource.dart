import 'package:dio/dio.dart';
import 'package:doormer/src/core/connection/dio_exception_mapper.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';

import '../../domain/entity/card_rarity.dart';
import '../model/collection_response_models.dart';

/// The four collection endpoints, named as the API names them.
///
/// Every method throws a [Failure] whose message a student can read. What the
/// server said is logged, never shown.
abstract class CollectionRemoteDataSource {
  Future<DecksResponseModel> decks();

  Future<CardsResponseModel> cards(String deckId);

  Future<DrawResponseModel> draw(
    String deckId, {
    required String idempotencyKey,
  });

  Future<ShatterResponseModel> shatter(
    String deckId,
    String cardId,
    CardVariant variant, {
    required String idempotencyKey,
  });
}

class CollectionRemoteDataSourceImpl implements CollectionRemoteDataSource {
  static const _couldNotConnect =
      "We couldn't connect. Check your connection and try again.";
  static const _somethingWentWrong = 'Something went wrong. Try again.';
  static const _drawRefused = "You don't have enough quarks for a draw.";
  static const _shatterRefused = "You don't have a spare copy of that card.";

  final Dio dio;

  const CollectionRemoteDataSourceImpl({required this.dio});

  @override
  Future<DecksResponseModel> decks() =>
      _post('/v1/collection/decks', const {}, DecksResponseModel.fromJson);

  @override
  Future<CardsResponseModel> cards(String deckId) => _post(
        '/v1/collection/cards',
        {'deck_id': deckId},
        CardsResponseModel.fromJson,
      );

  @override
  Future<DrawResponseModel> draw(
    String deckId, {
    required String idempotencyKey,
  }) =>
      _post(
        '/v1/collection/draw',
        {'deck_id': deckId},
        DrawResponseModel.fromJson,
        idempotencyKey: idempotencyKey,
        refusedMessage: _drawRefused,
      );

  @override
  Future<ShatterResponseModel> shatter(
    String deckId,
    String cardId,
    CardVariant variant, {
    required String idempotencyKey,
  }) =>
      _post(
        '/v1/collection/shatter',
        {'deck_id': deckId, 'card_id': cardId, 'variant': variant.name},
        ShatterResponseModel.fromJson,
        idempotencyKey: idempotencyKey,
        refusedMessage: _shatterRefused,
      );

  /// Posts [body] to [path] and reads the answer with [parse].
  ///
  /// [refusedMessage] is what a 409 means for this action. A 409 is turned
  /// into a failure here, not by the shared mapper, which would make it an
  /// [ApiFailure] and put "Error 409:" in front of the message.
  Future<T> _post<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic> json) parse, {
    String? idempotencyKey,
    String? refusedMessage,
  }) async {
    final Response<dynamic> response;
    try {
      response = await dio.post(
        path,
        data: body,
        options: idempotencyKey == null
            ? null
            : Options(headers: {'Idempotency-Key': idempotencyKey}),
      );
    } on DioException catch (e, stackTrace) {
      AppLogger.error('$path failed', error: e, stackTrace: stackTrace);
      if (refusedMessage != null && e.response?.statusCode == 409) {
        throw ValidationFailure(refusedMessage);
      }
      throw dioExceptionToFailure(e, userFacingMessage: _messageFor(e.type));
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
      throw UnknownFailure(_somethingWentWrong);
    }
  }

  static String _messageFor(DioExceptionType type) => switch (type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError =>
          _couldNotConnect,
        _ => _somethingWentWrong,
      };
}
