import 'dart:convert';
import 'dart:io';

import 'package:doormer/src/features/questions/data/model/photo_question_response_model.dart';
import 'package:doormer/src/features/questions/presentation/molecules/solution_trail_molecule.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/bloc/solution_reader_bloc.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_reader_presenter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Walks the bundled payload all the way from JSON to display copy.
///
/// `approach`, `verification` and `note` were parsed correctly for a long time
/// and rendered nowhere — every layer's own tests passed while the content
/// never reached a student. These assertions are deliberately end to end so
/// that a break anywhere along the chain shows up as content going missing.
void main() {
  late PhotoQuestionSolveOutcome outcome;

  setUpAll(() {
    final raw =
        File('assets/mock/mock_question_response.json').readAsStringSync();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    outcome = PhotoQuestionResponseModel.fromJson(json).toEntity();
  });

  test('the payload really does carry all three dark fields', () {
    final solution = outcome.solution!;

    expect(solution.approach.body, isNotEmpty);
    expect(solution.verification.body, isNotEmpty);
    expect(outcome.note, isNotEmpty);
  });

  test('the approach reaches the briefing screen whole', () {
    final content = solutionReaderContent(SolutionReaderReady(
      document: outcome.solution!,
      onBriefing: true,
      note: outcome.note,
    ));

    final source = outcome.solution!.approach.body
        .whereType<TextSolutionSegment>()
        .map((s) => s.value)
        .join();
    final rendered = content.briefingBody
        .map((o) => o.segment)
        .whereType<TextSolutionSegment>()
        .map((s) => s.value)
        .join();

    expect(content.onBriefing, isTrue);
    expect(rendered, source,
        reason: 'the approach is rendered whole, never truncated');
    expect(content.note, outcome.note);
  });

  test('the verification reaches the check once the answer is revealed', () {
    final document = outcome.solution!;
    final lastStep = document.steps.length - 1;

    final beforeReveal = solutionReaderContent(
      SolutionReaderReady(document: document, stepIndex: lastStep),
    );
    final afterReveal = solutionReaderContent(SolutionReaderReady(
      document: document,
      stepIndex: lastStep,
      answerRevealed: true,
    ));

    expect(beforeReveal.checkBody, isEmpty);
    expect(afterReveal.checkBody, hasLength(document.verification.body.length));
    expect(
      afterReveal.checkBody.map((o) => o.segment).whereType<MathSolutionSegment>(),
      isNotEmpty,
      reason: 'the verification math must survive the trip, not just its prose',
    );
  });

  test('the reader opens on the briefing for this payload', () {
    final content = solutionReaderContent(SolutionReaderReady(
      document: outcome.solution!,
      onBriefing: outcome.solution!.approach.body.isNotEmpty,
    ));

    expect(content.ctaLabel, 'Start solving');
    expect(content.trail.first.icon, isNotNull);
    // Briefing, then every step, then the vault: both ends are destinations.
    expect(content.trail, hasLength(outcome.solution!.steps.length + 2));
    expect(content.trail.first.shape, SolutionTrailNodeShape.marker);
    expect(content.trail.last.shape, SolutionTrailNodeShape.marker);
  });
}
