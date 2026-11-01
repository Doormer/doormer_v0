import 'package:dio/dio.dart';
import 'package:doormer/src/core/connection/dio_exception_mapper.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';

import '../model/count_active_day_response_model.dart';

/// Tells the API the signed-in student is here, with `/levels/active-day`.
///
/// Throws a [Failure] whose message a student could read, though the app
/// never shows it: counting a day fails quietly. What the server said is
/// logged, never shown.
abstract class LevelsRemoteDataSource {
  Future<CountActiveDayResponseModel> countActiveDay();
}

class LevelsRemoteDataSourceImpl implements LevelsRemoteDataSource {
  /// The words of every failure this data source throws.
  static const couldNotCount = "We couldn't count today as an active day.";

  static const _path = '/v1/levels/active-day';

  final Dio dio;

  const LevelsRemoteDataSourceImpl({required this.dio});

  @override
  Future<CountActiveDayResponseModel> countActiveDay() async {
    final Response<dynamic> response;
    try {
      response = await dio.post(_path, data: const <String, dynamic>{});
    } on DioException catch (e, stackTrace) {
      AppLogger.error('$_path failed', error: e, stackTrace: stackTrace);
      throw dioExceptionToFailure(e, userFacingMessage: couldNotCount);
    }

    try {
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const FormatException('The response is not a JSON object');
      }
      return CountActiveDayResponseModel.fromJson(data);
    } catch (e, stackTrace) {
      AppLogger.error('$_path answered with a response the app cannot read',
          error: e, stackTrace: stackTrace);
      throw UnknownFailure(couldNotCount);
    }
  }
}
