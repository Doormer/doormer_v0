import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:doormer/src/core/services/sessions/session_service.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/dev/fake_backend/fake_backend.dart';
import 'package:doormer/src/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:doormer/src/features/registration/data/datasource/registration_remote_datasource.dart';
import 'package:doormer/src/features/registration/data/model/candidate_registration_request_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Signing in never uses the session service.
class _UnusedSessionService implements SessionService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  setUpAll(AppLogger.disable);

  late RegistrationRemoteDataSource registration;
  late AuthRemoteDataSource auth;

  setUp(() {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://api.test',
      headers: {'Authorization': 'Bearer test-token'},
    ))
      ..httpClientAdapter =
          fakeBackend(delay: Duration.zero, solveDelay: Duration.zero);
    registration = RegistrationRemoteDataSource(dio: dio);
    auth = AuthRemoteDataSource(
      sessionService: _UnusedSessionService(),
      googleSignIn: GoogleSignIn(),
      dio: dio,
    );
  });

  test('hands out an upload address that never leaves the browser', () async {
    final address = await registration.getSasUploadUrl('cv.pdf');

    expect(Uri.parse(address).host, 'fake-storage.invalid');
  });

  test('takes a CV and preferences uploaded to that address', () async {
    final address = await registration.getSasUploadUrl('cv.pdf');

    await expectLater(
      registration.uploadFileToSasUrl(Uint8List.fromList([1, 2, 3]), address),
      completes,
    );
    await expectLater(
        registration.uploadJsonToSasUrl('{"roles":[]}', address), completes);
  });

  test('after registering, signing in gives a registered student', () async {
    await auth.signup('ana@example.test', 'secret');
    final beforeRegistering = await auth.login('ana@example.test', 'secret');

    await registration.registerCandidate(CandidateRegistrationRequestModel(
      mobileNumber: '021 555 0100',
      firstName: 'Ana',
      lastName: 'Lee',
    ));
    final afterRegistering = await auth.login('ana@example.test', 'secret');

    expect(beforeRegistering.user?.userRegistrationStatus, 0);
    expect(afterRegistering.user?.userRegistrationStatus, 1);
  });
}
