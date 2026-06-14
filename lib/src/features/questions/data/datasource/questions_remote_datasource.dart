import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:doormer/src/core/connection/dio_exception_mapper.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/data/model/photo_question_response_model.dart';

abstract class QuestionsRemoteDataSource {
  Future<PhotoQuestionResponseModel> submitPhotoQuestion({
    required Uint8List imageBytes,
    required String contentType,
    required String idempotencyKey,
  });
}

class QuestionsRemoteDataSourceImpl implements QuestionsRemoteDataSource {
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
}
