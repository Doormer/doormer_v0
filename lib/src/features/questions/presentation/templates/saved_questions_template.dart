import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/presentation/atoms/photo_thumbnail_atom.dart';
import 'package:doormer/src/features/questions/presentation/molecules/saved_questions_empty_molecule.dart';
import 'package:doormer/src/features/questions/presentation/organisms/saved_question_list_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/saved_questions_body_params.dart';
import 'package:doormer/src/shared/design/atomic/molecules/error_with_retry_molecule.dart';
import 'package:doormer/src/shared/design/atomic/organisms/navigation_bar_organism.dart';
import 'package:doormer/src/shared/design/atomic/params/navigation_bar_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The Saved page: its heading, then whatever [body] holds, with the nav bar
/// at the foot. The Scaffold lays the body out above the bar, so the last row
/// is never hidden under it.
class SavedQuestionsTemplate extends StatelessWidget {
  final SavedQuestionsBodyParams body;
  final NavigationBarParams navigationBarParams;
  final PhotoImageProviderBuilder imageProviderBuilder;

  const SavedQuestionsTemplate({
    super.key,
    required this.body,
    required this.navigationBarParams,
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
          child: NavigationBarOrganism(params: navigationBarParams),
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
