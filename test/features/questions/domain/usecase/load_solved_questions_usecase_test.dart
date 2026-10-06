import 'package:doormer/src/features/questions/domain/entity/solved_questions_page.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_solved_questions_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every list request with [page] and remembers the cursor it was given.
class _RecordingRepository implements QuestionsRepository {
  final page = const SolvedQuestionsPage(questions: []);
  int calls = 0;
  String? cursor;

  @override
  Future<SolvedQuestionsPage> loadSolvedQuestions({String? cursor}) async {
    calls++;
    this.cursor = cursor;
    return page;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  test('reads the first page with no cursor', () async {
    final repository = _RecordingRepository();

    final page = await LoadSolvedQuestionsUseCase(repository)();

    expect(repository.calls, 1);
    expect(repository.cursor, isNull);
    expect(page, same(repository.page));
  });

  test('passes the cursor through', () async {
    final repository = _RecordingRepository();

    await LoadSolvedQuestionsUseCase(repository)(cursor: '42');

    expect(repository.cursor, '42');
  });
}
