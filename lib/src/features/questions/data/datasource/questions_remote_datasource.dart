import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:doormer/src/core/connection/dio_exception_mapper.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/data/model/answer_reward_model.dart';
import 'package:doormer/src/features/questions/data/model/photo_question_response_model.dart';
import 'package:doormer/src/features/questions/data/model/quark_balance_model.dart';

abstract class QuestionsRemoteDataSource {
  Future<PhotoQuestionResponseModel> submitPhotoQuestion({
    required Uint8List imageBytes,
    required String contentType,
    required String idempotencyKey,
  });

  Future<PhotoQuestionResponseModel> loadQuestion(String questionId);

  Future<AnswerRewardModel> revealAnswer(String questionId);

  Future<QuarkBalanceModel> loadQuarkBalance();
}

class QuestionsRemoteDataSourceImpl implements QuestionsRemoteDataSource {
  static const _couldNotConnect =
      "We couldn't connect. Check your connection and try again.";
  static const _somethingWentWrong = 'Something went wrong. Try again.';

  final Dio dio;

  const QuestionsRemoteDataSourceImpl({required this.dio});

  @override
  Future<PhotoQuestionResponseModel> submitPhotoQuestion({
    required Uint8List imageBytes,
    required String contentType,
    required String idempotencyKey,
  }) async {
    try {
      final response = await dio.post(
        '/v1/questions/photo',
        data: imageBytes,
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Idempotency-Key': idempotencyKey,
          },
        ),
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        AppLogger.error('Photo question response had an unexpected shape');
        throw ServerFailure(
            'We could not read the solver response. Try again.');
      }

      return PhotoQuestionResponseModel.fromJson(data);
    } on DioException catch (e, stackTrace) {
      AppLogger.error('Photo question submission failed',
          error: e, stackTrace: stackTrace);
      throw dioExceptionToFailure(
        e,
        userFacingMessage: 'We could not submit your photo. Please try again.',
      );
    } on Failure catch (f, stackTrace) {
      AppLogger.error('Photo question submission failed',
          error: f, stackTrace: stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error('Photo question response parsing failed',
          error: e, stackTrace: stackTrace);
      throw ServerFailure('We could not read the solver response. Try again.');
    }
  }

  @override
  Future<PhotoQuestionResponseModel> loadQuestion(String questionId) => _post(
        '/v1/questions/solution',
        {'question_id': questionId},
        PhotoQuestionResponseModel.fromJson,
      );

  @override
  Future<AnswerRewardModel> revealAnswer(String questionId) => _post(
        '/v1/questions/reveal-answer',
        {'question_id': questionId},
        AnswerRewardModel.fromJson,
      );

  @override
  Future<QuarkBalanceModel> loadQuarkBalance() => _post(
        '/v1/quarks/balance',
        const {},
        QuarkBalanceModel.fromJson,
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
