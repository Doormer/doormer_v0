import 'package:dio/dio.dart';
import 'package:doormer/src/core/services/sessions/session_service.dart';
import 'package:doormer/src/features/profile/di/profile_module.dart';
import 'package:doormer/src/features/profile/domain/usecase/accept_friend_request_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/block_student_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/decline_friend_request_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/find_student_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/load_blocked_students_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/load_friend_profile_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/load_friend_requests_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/load_friends_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/load_picture_choices_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/remove_friend_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/report_student_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/reset_friend_code_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/save_friend_profile_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/send_friend_request_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/unblock_student_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

class _FakeSessionService implements SessionService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final locator = GetIt.instance;

  setUp(() {
    locator.registerSingleton<Dio>(Dio());
    locator.registerSingleton<SessionService>(_FakeSessionService());
    initProfileModule();
  });

  tearDown(() => locator.reset());

  test('every friends use case resolves', () {
    expect(locator<LoadFriendProfileUseCase>(), isNotNull);
    expect(locator<SaveFriendProfileUseCase>(), isNotNull);
    expect(locator<LoadPictureChoicesUseCase>(), isNotNull);
    expect(locator<ResetFriendCodeUseCase>(), isNotNull);
    expect(locator<FindStudentUseCase>(), isNotNull);
    expect(locator<LoadFriendRequestsUseCase>(), isNotNull);
    expect(locator<SendFriendRequestUseCase>(), isNotNull);
    expect(locator<AcceptFriendRequestUseCase>(), isNotNull);
    expect(locator<DeclineFriendRequestUseCase>(), isNotNull);
    expect(locator<LoadFriendsUseCase>(), isNotNull);
    expect(locator<RemoveFriendUseCase>(), isNotNull);
    expect(locator<BlockStudentUseCase>(), isNotNull);
    expect(locator<UnblockStudentUseCase>(), isNotNull);
    expect(locator<LoadBlockedStudentsUseCase>(), isNotNull);
    expect(locator<ReportStudentUseCase>(), isNotNull);
  });
}
