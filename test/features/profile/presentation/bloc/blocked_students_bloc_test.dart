import 'package:bloc_test/bloc_test.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/profile/domain/usecase/load_blocked_students_usecase.dart';
import 'package:doormer/src/features/profile/domain/usecase/unblock_student_usecase.dart';
import 'package:doormer/src/features/profile/presentation/bloc/blocked_students_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_friends_repository.dart';

void main() {
  setUpAll(AppLogger.disable);

  late FakeFriendsRepository repository;

  setUp(() => repository = FakeFriendsRepository());

  BlockedStudentsBloc build() => BlockedStudentsBloc(
        loadBlockedStudents: LoadBlockedStudentsUseCase(repository),
        unblockStudent: UnblockStudentUseCase(repository),
      );

  blocTest<BlockedStudentsBloc, BlockedStudentsState>(
    'lists the blocked students',
    build: build,
    act: (bloc) => bloc.add(const BlockedStudentsStarted()),
    expect: () => [
      const BlockedStudentsReady(students: [tama]),
    ],
  );

  blocTest<BlockedStudentsBloc, BlockedStudentsState>(
    'a load that fails says why, and Try again loads with the spinner',
    build: build,
    setUp: () => repository.failNext['loadBlockedStudents'] =
        NetworkFailure("We couldn't load the students you've blocked."),
    act: (bloc) async {
      bloc.add(const BlockedStudentsStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const BlockedStudentsRetried());
    },
    expect: () => [
      const BlockedStudentsError(
          "We couldn't load the students you've blocked."),
      const BlockedStudentsLoading(),
      const BlockedStudentsReady(students: [tama]),
    ],
  );

  blocTest<BlockedStudentsBloc, BlockedStudentsState>(
    'Unblock waits for the answer, then the student goes from the list',
    build: build,
    seed: () => const BlockedStudentsReady(students: [tama]),
    act: (bloc) => bloc.add(const StudentUnblocked('66')),
    expect: () => [
      const BlockedStudentsReady(students: [tama], unblockingIds: {'66'}),
      const BlockedStudentsReady(students: []),
    ],
    verify: (_) => expect(repository.calls, ['unblockStudent 66']),
  );

  blocTest<BlockedStudentsBloc, BlockedStudentsState>(
    'an Unblock that fails says why, and keeps the student',
    build: build,
    seed: () => const BlockedStudentsReady(students: [tama]),
    setUp: () => repository.failNext['unblockStudent'] =
        NetworkFailure("We couldn't unblock that student. Try again."),
    act: (bloc) => bloc.add(const StudentUnblocked('66')),
    expect: () => [
      const BlockedStudentsReady(students: [tama], unblockingIds: {'66'}),
      const BlockedStudentsReady(
        students: [tama],
        errorMessage: "We couldn't unblock that student. Try again.",
      ),
    ],
  );
}
