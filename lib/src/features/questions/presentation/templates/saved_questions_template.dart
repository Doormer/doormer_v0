import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/presentation/atoms/photo_thumbnail_atom.dart';
import 'package:doormer/src/features/questions/presentation/molecules/saved_list_switch_molecule.dart';
import 'package:doormer/src/features/questions/presentation/molecules/saved_questions_empty_molecule.dart';
import 'package:doormer/src/features/questions/presentation/molecules/shared_questions_empty_molecule.dart';
import 'package:doormer/src/features/questions/presentation/organisms/saved_question_list_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/saved_list_switch_params.dart';
import 'package:doormer/src/features/questions/presentation/params/saved_questions_body_params.dart';
import 'package:doormer/src/shared/design/atomic/molecules/error_with_retry_molecule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The Saved page: Mine and Shared with me at the top, then whatever [body]
/// holds for the list shown. The nav bar already names the page, so it has no
/// visible heading. The destination shell lays the page out above the nav
/// bar, so the last row is never hidden under it.
class SavedQuestionsTemplate extends StatelessWidget {
  final SavedListSwitchParams listSwitch;
  final SavedQuestionsBodyParams body;
  final PhotoImageProviderBuilder imageProviderBuilder;

  const SavedQuestionsTemplate({
    super.key,
    required this.listSwitch,
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
              child: Align(
                alignment: Alignment.centerLeft,
                // On the web, the nav bar reads each tab out without saying
                // which one is selected, so the switch names the page.
                child: Semantics(
                  container: true,
                  label: 'Saved',
                  child: SavedListSwitchMolecule(params: listSwitch),
                ),
              ),
            ),
            // Each list keeps its own place: switching starts the other one
            // at its top, not where this one was scrolled to.
            Expanded(
              child: KeyedSubtree(
                key: ValueKey(listSwitch.selected),
                child: _content(),
              ),
            ),
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
      SharedQuestionsEmptyParams() => const Center(
          child: SingleChildScrollView(
            child: SharedQuestionsEmptyMolecule(),
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
