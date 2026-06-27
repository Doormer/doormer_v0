import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/presentation/templates/solution_handoff_template.dart';
import 'package:flutter/material.dart';

class QuestionSolutionHandoffPage extends StatelessWidget {
  final String questionId;
  final AskByPhotoSolved? solvedState;

  const QuestionSolutionHandoffPage({
    super.key,
    required this.questionId,
    required this.solvedState,
  });

  @override
  Widget build(BuildContext context) {
    return SolutionHandoffTemplate(
      questionId: questionId,
      stepCount: solvedState?.solution.steps.length,
    );
  }
}
