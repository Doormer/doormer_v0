import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:doormer/src/features/questions/di/questions_module.dart';
import 'package:doormer/src/features/questions/domain/usecase/block_friend_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_daily_limit_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_friends_to_share_with_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_shared_questions_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_solved_questions_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/remove_shared_question_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/report_shared_question_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/share_question_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/stop_sharing_question_usecase.dart';
import 'package:doormer/src/features/questions/presentation/bloc/daily_limit_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/friend_question_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/saved_questions_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/share_question_bloc.dart';
import 'package:doormer/src/features/questions/presentation/bloc/shared_questions_bloc.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_file_input.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_preparer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  tearDown(() => GetIt.instance.reset());

  test('registers the photo file input and the photo preparer', () {
    initQuestionsModule();

    expect(GetIt.instance.isRegistered<PhotoFileInput>(), isTrue);
    expect(GetIt.instance.isRegistered<PhotoPreparer>(), isTrue);
  });

  test('registers the solved questions use case', () {
    initQuestionsModule();

    expect(GetIt.instance.isRegistered<LoadSolvedQuestionsUseCase>(), isTrue);
  });

  test('registers the Saved list bloc', () {
    initQuestionsModule();

    expect(GetIt.instance.isRegistered<SavedQuestionsBloc>(), isTrue);
  });

  test('registers the daily limit use case', () {
    initQuestionsModule();

    expect(GetIt.instance.isRegistered<LoadDailyLimitUseCase>(), isTrue);
  });

  test('registers the daily limit bloc', () {
    initQuestionsModule();

    expect(GetIt.instance.isRegistered<DailyLimitBloc>(), isTrue);
  });

  test('every sharing use case resolves', () {
    GetIt.instance.registerSingleton<Dio>(Dio());
    initQuestionsModule();

    expect(GetIt.instance<LoadFriendsToShareWithUseCase>(), isNotNull);
    expect(GetIt.instance<ShareQuestionUseCase>(), isNotNull);
    expect(GetIt.instance<StopSharingQuestionUseCase>(), isNotNull);
    expect(GetIt.instance<LoadSharedQuestionsUseCase>(), isNotNull);
    expect(GetIt.instance<RemoveSharedQuestionUseCase>(), isNotNull);
    expect(GetIt.instance<ReportSharedQuestionUseCase>(), isNotNull);
    expect(GetIt.instance<BlockFriendUseCase>(), isNotNull);
  });

  test('registers the bloc that shares a question', () {
    GetIt.instance.registerSingleton<Dio>(Dio());
    initQuestionsModule();

    expect(GetIt.instance<ShareQuestionBloc>(), isNotNull);
  });

  test("registers the bloc that acts on a friend's question", () {
    GetIt.instance.registerSingleton<Dio>(Dio());
    initQuestionsModule();

    expect(GetIt.instance<FriendQuestionBloc>(), isNotNull);
  });

  test('registers the Shared with me list bloc', () {
    GetIt.instance.registerSingleton<Dio>(Dio());
    initQuestionsModule();

    expect(GetIt.instance<SharedQuestionsBloc>(), isNotNull);
  });

  test(
      'one repository takes every Remove, Block and read of Shared with me, '
      'so the reads can wait for the changes', () {
    GetIt.instance.registerSingleton<Dio>(Dio());
    initQuestionsModule();

    final repository = GetIt.instance<RemoveSharedQuestionUseCase>().repository;

    expect(GetIt.instance<BlockFriendUseCase>().repository, same(repository));
    expect(GetIt.instance<LoadSharedQuestionsUseCase>().repository,
        same(repository));
  });

  test('each sharing bloc is made afresh for every page that asks', () async {
    GetIt.instance.registerSingleton<Dio>(Dio());
    initQuestionsModule();

    Future<void> expectMadeAfresh<T extends BlocBase<Object?>>() async {
      final first = GetIt.instance<T>();
      final second = GetIt.instance<T>();
      expect(second, isNot(same(first)), reason: '$T');
      await first.close();
      await second.close();
    }

    await expectMadeAfresh<ShareQuestionBloc>();
    await expectMadeAfresh<FriendQuestionBloc>();
    await expectMadeAfresh<SharedQuestionsBloc>();
  });
}
