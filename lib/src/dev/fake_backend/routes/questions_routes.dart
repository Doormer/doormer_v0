import 'dart:convert';

import 'package:doormer/src/dev/fake_backend/fake_backend_state.dart';
import 'package:doormer/src/dev/fake_backend/fake_diagram.dart';
import 'package:doormer/src/dev/fake_backend/fake_request.dart';
import 'package:doormer/src/dev/fake_backend/fake_response.dart';
import 'package:doormer/src/dev/fake_backend/fake_route.dart';
import 'package:flutter/services.dart';

/// Solving photos, saved questions, revealing answers and the quark balance.
/// Every question opens the same worked solution.
class QuestionsRoutes {
  /// A real solved question, already bundled with the app.
  static const solutionAsset = 'assets/mock/mock_question_response.json';

  /// The question in that solution's photo.
  static const photoQuestionText = 'Find the area of the printed rectangle.';

  /// What revealing an answer pays the first time: the real "Standard" band.
  static const revealReward = 3;

  final FakeBackendState _state;
  final AssetBundle _bundle;
  final DateTime Function() _clock;
  final Duration _solveDelay;

  QuestionsRoutes(
    this._state, {
    required AssetBundle bundle,
    required DateTime Function() clock,
    required Duration solveDelay,
  })  : _bundle = bundle,
        _clock = clock,
        _solveDelay = solveDelay;

  List<FakeRoute> get routes => [
        FakeRoute('POST', '/v1/questions/photo', _solvePhoto),
        FakeRoute('POST', '/v1/questions/solution', _solution),
        FakeRoute('POST', '/v1/questions/solved', _solvedQuestions),
        FakeRoute('POST', '/v1/questions/reveal-answer', _revealAnswer),
        FakeRoute('POST', '/v1/quarks/balance', _quarkBalance),
      ];

  Future<FakeResponse> _solvePhoto(FakeRequest request) async {
    await Future<void>.delayed(_solveDelay);
    final solution = await _workedSolution();
    final question = FakeSolvedQuestion(
      id: _state.newQuestionId(),
      topic: solution['topic'] as String,
      method: solution['method'] as String,
      questionText: photoQuestionText,
      askedAt: _clock(),
    );
    _state.solvedQuestions.insert(0, question);
    return FakeResponse.ok(_answerTo(question, solution));
  }

  Future<FakeResponse> _solution(FakeRequest request) async {
    final question = _questionIn(request);
    if (question == null) return const FakeResponse(404, 'question not found');
    return FakeResponse.ok(_answerTo(question, await _workedSolution()));
  }

  FakeResponse _solvedQuestions(FakeRequest request) => FakeResponse.ok({
        'questions': [
          for (final question in _state.solvedQuestions)
            {
              'question_id': question.id,
              'topic': question.topic,
              'method': question.method,
              'question_text': question.questionText,
              'asked_at': question.askedAt.toUtc().toIso8601String(),
            },
        ],
      });

  FakeResponse _revealAnswer(FakeRequest request) {
    final question = _questionIn(request);
    if (question == null) return const FakeResponse(404, 'question not found');
    final quarksEarned = question.answerRevealed ? 0 : revealReward;
    question.answerRevealed = true;
    _state.quarkBalance += quarksEarned;
    return FakeResponse.ok({
      'quarks_earned': quarksEarned,
      'quark_balance': _state.quarkBalance,
    });
  }

  FakeResponse _quarkBalance(FakeRequest request) =>
      FakeResponse.ok({'quark_balance': _state.quarkBalance});

  FakeSolvedQuestion? _questionIn(FakeRequest request) =>
      _state.solvedQuestion(request.fields['question_id']?.toString());

  /// The worked solution, as the answer about [question].
  Map<String, Object?> _answerTo(
          FakeSolvedQuestion question, Map<String, dynamic> solution) =>
      {
        ...solution,
        'question_id': question.id,
        'topic': question.topic,
        'method': question.method,
      };

  /// The bundled solution, with its diagrams swapped for [fakeDiagramUrl].
  Future<Map<String, dynamic>> _workedSolution() async =>
      _withPlaceholderDiagrams(
              jsonDecode(await _bundle.loadString(solutionAsset)))
          as Map<String, dynamic>;

  static Object? _withPlaceholderDiagrams(Object? json) => switch (json) {
        Map<String, dynamic>() when json['type'] == 'visual' => {
            ...json,
            'url': fakeDiagramUrl,
          },
        Map<String, dynamic>() => {
            for (final field in json.entries)
              field.key: _withPlaceholderDiagrams(field.value),
          },
        List<dynamic>() => [
            for (final item in json) _withPlaceholderDiagrams(item),
          ],
        _ => json,
      };
}
