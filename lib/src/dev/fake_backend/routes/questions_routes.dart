import 'dart:convert';
import 'dart:math';

import 'package:doormer/src/dev/fake_backend/fake_backend_state.dart';
import 'package:doormer/src/dev/fake_backend/fake_diagram.dart';
import 'package:doormer/src/dev/fake_backend/fake_request.dart';
import 'package:doormer/src/dev/fake_backend/fake_response.dart';
import 'package:doormer/src/dev/fake_backend/fake_route.dart';
import 'package:flutter/services.dart';

/// Solving photos within the daily limits, saved questions, revealing answers
/// and the quark balance. Every question opens the same worked solution.
class QuestionsRoutes {
  /// A real solved question, already bundled with the app.
  static const solutionAsset = 'assets/mock/mock_question_response.json';

  /// The question in that solution's photo.
  static const photoQuestionText = 'Find the area of the printed rectangle.';

  /// What revealing an answer pays the first time: the real "Standard" band.
  static const revealReward = 3;

  /// The API's default limits.
  static const questionsPerDay = 5;
  static const photosPerDay = 20;

  static const _stillSolving =
      'Your last photo is still being solved. Try again in a moment.';
  static const _missingKey =
      'This request is missing a valid Idempotency-Key header.';

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
        FakeRoute('POST', '/v1/questions/daily-limit', _dailyLimit),
        FakeRoute('POST', '/v1/quarks/balance', _quarkBalance),
      ];

  /// Solves a photo within the day's limits, as `taka-api` does. A photo sent
  /// while one is being solved gets a 409, and one sent with no questions
  /// left a 429. The adapter replays a repeated key's answer before this
  /// runs.
  Future<FakeResponse> _solvePhoto(FakeRequest request) async {
    final key = request.header('Idempotency-Key') ?? '';
    if (key.isEmpty) return const FakeResponse(400, _missingKey);
    _startNewDayIfDue();
    // A retry of the photo being solved: its answer is coming.
    if (_state.solvingKey == key) return const FakeResponse(409, _stillSolving);
    if (_questionsLeft == 0) return FakeResponse(429, _limitReached());
    if (_state.solvingKey != null) {
      return const FakeResponse(409, _stillSolving);
    }

    _state.photosSentToday++;
    _state.solvingKey = key;
    try {
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
      _state.questionsSolvedToday++;
      return FakeResponse.ok({
        ..._answerTo(question, solution),
        'daily_limit': _dailyLimitJson(),
      });
    } finally {
      _state.solvingKey = null;
    }
  }

  FakeResponse _dailyLimit(FakeRequest request) {
    _startNewDayIfDue();
    return FakeResponse.ok(_dailyLimitJson());
  }

  int get _questionsLeft => max(
        0,
        min(questionsPerDay - _state.questionsSolvedToday,
            photosPerDay - _state.photosSentToday),
      );

  Map<String, Object?> _dailyLimitJson() => {
        'questions_left': _questionsLeft,
        // The API's day is Auckland's. The fake's is the device's own.
        'resets_at': _state.dayEndsAt!.toUtc().toIso8601String(),
      };

  Map<String, Object?> _limitReached() => {
        'reason': _state.questionsSolvedToday >= questionsPerDay
            ? 'daily_question_limit'
            : 'daily_photo_limit',
        'daily_limit': _dailyLimitJson(),
        'next_steps': <Object?>[],
      };

  /// Starts a new day once the last one has ended.
  void _startNewDayIfDue() => _state.startNewDayIfDue(_clock());

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
