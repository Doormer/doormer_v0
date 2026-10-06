import 'package:doormer/src/features/questions/di/questions_module.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_solved_questions_usecase.dart';
import 'package:doormer/src/features/questions/presentation/bloc/saved_questions_bloc.dart';
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
}
