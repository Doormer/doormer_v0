import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/presentation/atoms/photo_thumbnail_atom.dart';
import 'package:doormer/src/features/questions/presentation/molecules/saved_questions_empty_molecule.dart';
import 'package:doormer/src/features/questions/presentation/organisms/saved_question_list_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/saved_questions_body_params.dart';
import 'package:doormer/src/shared/design/atomic/molecules/error_with_retry_molecule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The Saved page: its heading, then whatever [body] holds. The destination
/// shell lays the page out above the nav bar, so the last row is never hidden
/// under it.
class SavedQuestionsTemplate extends StatelessWidget {
  final SavedQuestionsBodyParams body;
  final PhotoImageProviderBuilder imageProviderBuilder;

  const SavedQuestionsTemplate({
    super.key,
    required this.body,
    this.imageProviderBuilder = networkPhotoImageProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 12.h),
              child: Semantics(
                header: true,
                child: Text(
                  'Saved',
                  style: TextStyle(
                    fontFamily: kDisplayFont,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w600,
                    color: QuestPalette.cream,
                  ),
                ),
              ),
            ),
            Expanded(child: _content()),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    return switch (body) {
      SavedQuestionsLoadingParams() => const Center(
          child: CircularProgressIndicator(color: QuestPalette.violet),
        ),
      SavedQuestionsEmptyParams(:final onSolve) => Center(
          child: SingleChildScrollView(
            child: SavedQuestionsEmptyMolecule(onSolve: onSolve),
          ),
        ),
      SavedQuestionsErrorParams(:final message, :final onRetry) => Center(
          child: ErrorWithRetryMolecule(
            message: message,
            onRetry: onRetry,
            retryLabel: 'Try again',
          ),
        ),
      SavedQuestionListParams list => SavedQuestionListOrganism(
          params: list,
          imageProviderBuilder: imageProviderBuilder,
        ),
    };
  }
}
