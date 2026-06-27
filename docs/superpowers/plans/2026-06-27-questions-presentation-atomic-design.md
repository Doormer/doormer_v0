# Questions Presentation Layer → Atomic Design Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Decompose the `questions` feature's two presentation pages into a Brad-Frost Atomic Design hierarchy (Tokens → Atoms → Molecules → Organisms → Templates → Pages), promoting two generic atoms into a new `shared/design/atomic/` seam, with behavior preserved and only light visual polish.

**Architecture:** Build bottom-up so every commit compiles. Add the `accent` token, then shared atoms (`AppButtonAtom`, `SurfaceCardAtom`), a local decorative atom (`ViewfinderCornersAtom`), a pure state→copy mapper, molecules, then param objects + organisms, two param-driven templates, and finally rewrite the two pages to derive plain data + callbacks, pack them into param objects, and delegate to the templates. The organism/template layer uses the **Parameter Object** pattern from the reference article (`PhotoUploadPanelParams`, `SolveStatusPanelParams`) to group each organism's data + callbacks; atoms and molecules keep flat constructors. Every layer below `Page` is a pure presentational widget — no `flutter_bloc` import, no bloc access. The page is the only bloc-aware layer and the only caller of the mapper.

**Tech Stack:** Flutter 3.27.1 / Dart ^3.5.3 (web-first), `flutter_bloc`, `flutter_screenutil` (`.w`/`.h`/`.r`/`.sp`), `go_router`, `file_picker`, `toastification`. Styling via `AppColors` / `AppTextStyles` tokens.

**Testing note (adaptation):** This repo has **no test suite** and the spec makes new tests a non-goal. The TDD red/green loop is therefore replaced per task by a static-analysis gate: **`flutter analyze` must be clean with no new warnings**. A single manual smoke test runs at the end (Task 16). Intermediate public widget classes that are not yet wired in do **not** trigger analyzer warnings, so bottom-up commits stay green.

**Spec:** `docs/superpowers/specs/2026-06-27-questions-presentation-atomic-design-design.md` is the source of truth. Read it before starting.

---

## File Structure

Created:

```
lib/src/shared/design/atomic/atoms/
  app_button_atom.dart            # AppButtonAtom + AppButtonVariant
  surface_card_atom.dart          # SurfaceCardAtom

lib/src/features/questions/presentation/
  atoms/
    viewfinder_corners_atom.dart      # ViewfinderCornersAtom
  molecules/
    ask_by_photo_header_molecule.dart # AskByPhotoHeaderMolecule
    photo_preview_molecule.dart       # PhotoPreviewMolecule
    photo_action_row_molecule.dart    # PhotoActionRowMolecule
    status_action_row_molecule.dart   # StatusActionRowMolecule
  organisms/
    photo_upload_panel_organism.dart  # PhotoUploadPanelOrganism
    solve_status_panel_organism.dart  # SolveStatusPanelOrganism
  params/
    photo_upload_panel_params.dart    # PhotoUploadPanelParams (upload organism inputs)
    solve_status_panel_params.dart    # SolveStatusPanelParams (status organism inputs)
  templates/
    ask_by_photo_template.dart        # AskByPhotoTemplate
    solution_handoff_template.dart    # SolutionHandoffTemplate
  mapper/
    solve_status_presenter.dart       # SolveStatusContent + solveStatusContentFor(state)
```

Modified:

```
lib/src/core/theme/app_colors.dart                                  # add `accent`, alias `uploadButton`
lib/src/features/questions/presentation/pages/ask_by_photo_page.dart            # rewrite: derive data + delegate to template
lib/src/features/questions/presentation/pages/question_solution_handoff_page.dart # rewrite: delegate to template
```

Untouched (verify they still work, do **not** edit): `core/routes/web_router.dart`, the bloc/event/state files, DI registration, `candidate_registration.dart` (keeps using `AppColors.uploadButton`).

---

### Task 0: Baseline

**Files:** none (verification only)

- [ ] **Step 1: Confirm clean analyzer baseline**

Run: `flutter analyze`
Expected: completes; note any **pre-existing** warnings so they are not mistaken for regressions later. The plan's success bar is "no *new* warnings."

- [ ] **Step 2: Confirm the current pages compile and the bloc states are as expected**

Run: `flutter analyze lib/src/features/questions`
Expected: no errors. (Reference: `AskByPhotoPhotoSelected.imageBytes` is `Uint8List`, `fileName` is `String`; `AskByPhotoSolved.solution.steps` is a list.)

---

### Task 1: Add the `accent` semantic token

**Files:**
- Modify: `lib/src/core/theme/app_colors.dart:29-30`

- [ ] **Step 1: Add `accent` and make `uploadButton` a plain alias**

Replace the `// Buttons` block at the end of the class:

```dart
  // Buttons
  static const Color uploadButton = Colors.deepOrangeAccent;
```

with:

```dart
  // Buttons
  static const Color accent = Colors.deepOrangeAccent; // semantic token consumed by shared atoms
  static const Color uploadButton = accent; // plain alias — still used by the registration feature
```

Do **not** add `@Deprecated` — `candidate_registration.dart:223` still references `AppColors.uploadButton` and must not produce warnings.

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/src/core/theme/app_colors.dart lib/src/features/registration/presentation/pages/candidate_registration.dart`
Expected: no new warnings. Both `accent` and `uploadButton` resolve to `Colors.deepOrangeAccent`.

- [ ] **Step 3: Commit**

```bash
git add lib/src/core/theme/app_colors.dart
git commit -m "feat(theme): add semantic accent token aliasing uploadButton

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 2: `AppButtonAtom` (shared atom)

**Files:**
- Create: `lib/src/shared/design/atomic/atoms/app_button_atom.dart`

Collapses the three duplicated button styles + spinner. Padding standardised to `14.h` (the only intentional spacing polish — was 13/14/15.h). Radius stays `8.r`. `borderColor` preserves the two different outlined borders.

- [ ] **Step 1: Create the atom**

```dart
import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum AppButtonVariant { filled, accent, outlined }

class AppButtonAtom extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expand;
  final Color? borderColor;

  const AppButtonAtom({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.symmetric(vertical: 14.h);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.r),
    );

    final Widget content = isLoading
        ? SizedBox(
            height: 20.h,
            width: 20.w,
            child: CircularProgressIndicator(
              strokeWidth: 2.w,
              color: AppColors.onPrimary,
            ),
          )
        : Text(label);

    final VoidCallback? effectiveOnPressed = isLoading ? null : onPressed;

    Widget button;
    if (variant == AppButtonVariant.outlined) {
      final style = OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: borderColor ?? AppColors.borders),
        padding: padding,
        shape: shape,
      );
      button = icon == null
          ? OutlinedButton(
              onPressed: effectiveOnPressed,
              style: style,
              child: content,
            )
          : OutlinedButton.icon(
              onPressed: effectiveOnPressed,
              style: style,
              icon: Icon(icon),
              label: content,
            );
    } else {
      final backgroundColor = variant == AppButtonVariant.accent
          ? AppColors.accent
          : AppColors.primary;
      final style = ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: AppColors.onPrimary,
        padding: padding,
        shape: shape,
      );
      button = icon == null
          ? ElevatedButton(
              onPressed: effectiveOnPressed,
              style: style,
              child: content,
            )
          : ElevatedButton.icon(
              onPressed: effectiveOnPressed,
              style: style,
              icon: Icon(icon),
              label: content,
            );
    }

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/src/shared/design/atomic/atoms/app_button_atom.dart`
Expected: no errors, no warnings.

- [ ] **Step 3: Commit**

```bash
git add lib/src/shared/design/atomic/atoms/app_button_atom.dart
git commit -m "feat(design): add shared AppButtonAtom

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 3: `SurfaceCardAtom` (shared atom)

**Files:**
- Create: `lib/src/shared/design/atomic/atoms/surface_card_atom.dart`

Pure visual primitive: bordered/rounded surface around an arbitrary `child`. Defaults are nullable and resolved in `build()` because `.w`/`.r` are runtime (not const). **No semantic slots** (no title/subtitle/actions) — guardrail from the three-model review.

- [ ] **Step 1: Create the atom**

```dart
import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SurfaceCardAtom extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;

  const SurfaceCardAtom({
    super.key,
    required this.child,
    this.padding,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borders),
        borderRadius: BorderRadius.circular(radius ?? 18.r),
      ),
      child: child,
    );
  }
}
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/src/shared/design/atomic/atoms/surface_card_atom.dart`
Expected: no errors, no warnings.

- [ ] **Step 3: Commit**

```bash
git add lib/src/shared/design/atomic/atoms/surface_card_atom.dart
git commit -m "feat(design): add shared SurfaceCardAtom

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 4: `ViewfinderCornersAtom` (questions-local atom)

**Files:**
- Create: `lib/src/features/questions/presentation/atoms/viewfinder_corners_atom.dart`

Pure move of `_ViewfinderCorners` from the page. The only change: corner color migrates from `AppColors.uploadButton` to `AppColors.accent`. Add a `const` constructor.

- [ ] **Step 1: Create the atom**

```dart
import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ViewfinderCornersAtom extends StatelessWidget {
  const ViewfinderCornersAtom({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _corner(top: 12.h, left: 12.w),
        _corner(top: 12.h, right: 12.w, flipX: true),
        _corner(bottom: 12.h, left: 12.w, flipY: true),
        _corner(bottom: 12.h, right: 12.w, flipX: true, flipY: true),
      ],
    );
  }

  Widget _corner({
    double? top,
    double? right,
    double? bottom,
    double? left,
    bool flipX = false,
    bool flipY = false,
  }) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: SizedBox(
        width: 32.w,
        height: 32.h,
        child: Stack(
          children: [
            Positioned(
              top: flipY ? null : 0,
              bottom: flipY ? 0 : null,
              left: 0,
              right: 0,
              child: Container(height: 3.h, color: AppColors.accent),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: flipX ? null : 0,
              right: flipX ? 0 : null,
              child: Container(width: 3.w, color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/src/features/questions/presentation/atoms/viewfinder_corners_atom.dart`
Expected: no errors, no warnings.

- [ ] **Step 3: Commit**

```bash
git add lib/src/features/questions/presentation/atoms/viewfinder_corners_atom.dart
git commit -m "feat(questions): extract ViewfinderCornersAtom

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 5: `AskByPhotoHeaderMolecule`

**Files:**
- Create: `lib/src/features/questions/presentation/molecules/ask_by_photo_header_molecule.dart`

Pure move of `_Header` (title + supporting text). Molecule, not organism (three-model consensus: a two-`Text` `<hgroup>` is below the organism complexity bar).

- [ ] **Step 1: Create the molecule**

```dart
import 'package:doormer/src/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AskByPhotoHeaderMolecule extends StatelessWidget {
  const AskByPhotoHeaderMolecule({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ask Scarlet a question by photo',
          style: AppTextStyles.displayMedium.copyWith(fontSize: 32.sp),
        ),
        SizedBox(height: 8.h),
        Text(
          'Snap or upload a clear JPEG or PNG question. We will sort it into solved, unreadable, not-a-question, or timeout.',
          style: AppTextStyles.bodyLarge.copyWith(fontSize: 16.sp),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/src/features/questions/presentation/molecules/ask_by_photo_header_molecule.dart`
Expected: no errors, no warnings.

- [ ] **Step 3: Commit**

```bash
git add lib/src/features/questions/presentation/molecules/ask_by_photo_header_molecule.dart
git commit -m "feat(questions): extract AskByPhotoHeaderMolecule

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 6: `PhotoPreviewMolecule`

**Files:**
- Create: `lib/src/features/questions/presentation/molecules/photo_preview_molecule.dart`

Combines `_PreviewFrame` + `_EmptyPreview`. Takes `Uint8List? imageBytes`; `null` → empty hint state. Composes `ViewfinderCornersAtom`. (Original passed `Uint8List.fromList(...)` over an already-`Uint8List` value; passing the bytes directly is equivalent and removes a redundant copy.)

- [ ] **Step 1: Create the molecule**

```dart
import 'dart:typed_data';

import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:doormer/src/core/theme/app_text_styles.dart';
import 'package:doormer/src/features/questions/presentation/atoms/viewfinder_corners_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PhotoPreviewMolecule extends StatelessWidget {
  final Uint8List? imageBytes;

  const PhotoPreviewMolecule({super.key, this.imageBytes});

  @override
  Widget build(BuildContext context) {
    final bytes = imageBytes;

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.focusedBorders),
          borderRadius: BorderRadius.circular(16.r),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bytes == null)
              _buildEmptyHint()
            else
              Image.memory(bytes, fit: BoxFit.cover),
            const ViewfinderCornersAtom(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHint() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.document_scanner_outlined,
          size: 44.sp,
          color: AppColors.primary,
        ),
        SizedBox(height: 10.h),
        Text(
          'JPEG or PNG · max 10 MB',
          style: AppTextStyles.bodyMedium.copyWith(fontSize: 14.sp),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/src/features/questions/presentation/molecules/photo_preview_molecule.dart`
Expected: no errors, no warnings.

- [ ] **Step 3: Commit**

```bash
git add lib/src/features/questions/presentation/molecules/photo_preview_molecule.dart
git commit -m "feat(questions): extract PhotoPreviewMolecule

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 7: `PhotoActionRowMolecule`

**Files:**
- Create: `lib/src/features/questions/presentation/molecules/photo_action_row_molecule.dart`

Choose/Retake (`filled`, full-width via `Expanded`) + conditional Clear (`outlined`, border `AppColors.borders`, natural width). Preserves the original layout exactly.

- [ ] **Step 1: Create the molecule**

```dart
import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PhotoActionRowMolecule extends StatelessWidget {
  final bool hasPhoto;
  final bool isLoading;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  const PhotoActionRowMolecule({
    super.key,
    required this.hasPhoto,
    required this.isLoading,
    required this.onPick,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButtonAtom(
            label: hasPhoto ? 'Retake' : 'Choose photo',
            icon: Icons.photo_camera_outlined,
            onPressed: isLoading ? null : onPick,
          ),
        ),
        if (hasPhoto) ...[
          SizedBox(width: 12.w),
          AppButtonAtom(
            label: 'Clear',
            variant: AppButtonVariant.outlined,
            borderColor: AppColors.borders,
            onPressed: isLoading ? null : onClear,
          ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/src/features/questions/presentation/molecules/photo_action_row_molecule.dart`
Expected: no errors, no warnings.

- [ ] **Step 3: Commit**

```bash
git add lib/src/features/questions/presentation/molecules/photo_action_row_molecule.dart
git commit -m "feat(questions): extract PhotoActionRowMolecule

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 8: `StatusActionRowMolecule`

**Files:**
- Create: `lib/src/features/questions/presentation/molecules/status_action_row_molecule.dart`

Retake (`filled`) + Type instead (`outlined`, border `AppColors.focusedBorders`) — both in `Expanded`, matching the original status panel row.

- [ ] **Step 1: Create the molecule**

```dart
import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StatusActionRowMolecule extends StatelessWidget {
  final VoidCallback onRetake;
  final VoidCallback onTypeInstead;

  const StatusActionRowMolecule({
    super.key,
    required this.onRetake,
    required this.onTypeInstead,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButtonAtom(
            label: 'Retake',
            onPressed: onRetake,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: AppButtonAtom(
            label: 'Type instead',
            variant: AppButtonVariant.outlined,
            borderColor: AppColors.focusedBorders,
            onPressed: onTypeInstead,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/src/features/questions/presentation/molecules/status_action_row_molecule.dart`
Expected: no errors, no warnings.

- [ ] **Step 3: Commit**

```bash
git add lib/src/features/questions/presentation/molecules/status_action_row_molecule.dart
git commit -m "feat(questions): extract StatusActionRowMolecule

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 9: `solve_status_presenter` mapper

**Files:**
- Create: `lib/src/features/questions/presentation/mapper/solve_status_presenter.dart`

The old `_StatusContent` value object + `_contentFor` switch, now a pure value object + pure function. Imports the bloc only for state types. **Not a widget. Page-invoked only** — no widget layer may import this.

- [ ] **Step 1: Create the mapper**

```dart
import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';

class SolveStatusContent {
  final String title;
  final String body;
  final bool showActions;

  const SolveStatusContent({
    required this.title,
    required this.body,
    required this.showActions,
  });
}

/// Pure function mapping a bloc state to the status-panel display copy.
/// Page-invoked only — no presentational widget imports this.
SolveStatusContent solveStatusContentFor(AskByPhotoState state) {
  if (state is AskByPhotoUnreadable) {
    return const SolveStatusContent(
      title: 'We could not read it',
      body:
          'The photo was accepted, but the question was too blurry, cropped, or dark to solve. Retake it with the whole question in frame.',
      showActions: true,
    );
  }
  if (state is AskByPhotoNotAQuestion) {
    return const SolveStatusContent(
      title: 'This does not look like a question',
      body:
          'The image was received, but it did not contain a question we can solve. Retake with the question visible or type it manually.',
      showActions: true,
    );
  }
  if (state is AskByPhotoTimeout) {
    return const SolveStatusContent(
      title: 'Solver timed out',
      body:
          'The solver took too long on this photo. You can retake a sharper image or type the question instead.',
      showActions: true,
    );
  }
  if (state is AskByPhotoValidationError) {
    return SolveStatusContent(
      title: 'Photo needs a quick fix',
      body: state.message,
      showActions: true,
    );
  }
  if (state is AskByPhotoNetworkError) {
    return SolveStatusContent(
      title: 'Could not reach the solver',
      body: state.message,
      showActions: true,
    );
  }
  if (state is AskByPhotoLoading) {
    return const SolveStatusContent(
      title: 'Solving your photo',
      body:
          'Uploading raw image bytes securely and waiting for the solver response.',
      showActions: false,
    );
  }
  return const SolveStatusContent(
    title: 'Ready when the page is readable',
    body:
        'Use bright light, keep the question flat, and include every line of the problem. HEIC is not supported for this MVP.',
    showActions: false,
  );
}
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/src/features/questions/presentation/mapper/solve_status_presenter.dart`
Expected: no errors, no warnings.

- [ ] **Step 3: Commit**

```bash
git add lib/src/features/questions/presentation/mapper/solve_status_presenter.dart
git commit -m "feat(questions): add solve status presenter mapper

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 10: `PhotoUploadPanelParams` + `PhotoUploadPanelOrganism`

**Files:**
- Create: `lib/src/features/questions/presentation/params/photo_upload_panel_params.dart`
- Create: `lib/src/features/questions/presentation/organisms/photo_upload_panel_organism.dart`

The organism's inputs are grouped into a `PhotoUploadPanelParams` value object (article's Parameter Object pattern). The param is a **plain holder, not `Equatable`** (it carries `VoidCallback`s). The organism reads everything from `params`: `SurfaceCardAtom` + "Photo input" title + `PhotoPreviewMolecule` + filename + `PhotoActionRowMolecule` + accent submit. **No bloc access.** Submit enabled only when `hasPhoto && !isLoading`.

- [ ] **Step 1: Create the param object**

```dart
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

class PhotoUploadPanelParams {
  final Uint8List? imageBytes;
  final String? fileName;
  final bool isLoading;
  final VoidCallback onPickPhoto;
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  const PhotoUploadPanelParams({
    this.imageBytes,
    this.fileName,
    required this.isLoading,
    required this.onPickPhoto,
    required this.onSubmit,
    required this.onClear,
  });
}
```

- [ ] **Step 2: Create the organism**

```dart
import 'package:doormer/src/core/theme/app_text_styles.dart';
import 'package:doormer/src/features/questions/presentation/molecules/photo_action_row_molecule.dart';
import 'package:doormer/src/features/questions/presentation/molecules/photo_preview_molecule.dart';
import 'package:doormer/src/features/questions/presentation/params/photo_upload_panel_params.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/surface_card_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PhotoUploadPanelOrganism extends StatelessWidget {
  final PhotoUploadPanelParams params;

  const PhotoUploadPanelOrganism({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = params.imageBytes != null;
    final name = params.fileName;

    return SurfaceCardAtom(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Photo input',
            style: AppTextStyles.titleLarge.copyWith(fontSize: 20.sp),
          ),
          SizedBox(height: 16.h),
          PhotoPreviewMolecule(imageBytes: params.imageBytes),
          if (hasPhoto && name != null) ...[
            SizedBox(height: 12.h),
            Text(
              name,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 12.sp),
            ),
          ],
          SizedBox(height: 22.h),
          PhotoActionRowMolecule(
            hasPhoto: hasPhoto,
            isLoading: params.isLoading,
            onPick: params.onPickPhoto,
            onClear: params.onClear,
          ),
          SizedBox(height: 12.h),
          AppButtonAtom(
            label: 'Submit to solver',
            variant: AppButtonVariant.accent,
            expand: true,
            isLoading: params.isLoading,
            onPressed: hasPhoto && !params.isLoading ? params.onSubmit : null,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/src/features/questions/presentation/params/photo_upload_panel_params.dart lib/src/features/questions/presentation/organisms/photo_upload_panel_organism.dart`
Expected: no errors, no warnings.

- [ ] **Step 4: Commit**

```bash
git add lib/src/features/questions/presentation/params/photo_upload_panel_params.dart lib/src/features/questions/presentation/organisms/photo_upload_panel_organism.dart
git commit -m "feat(questions): extract PhotoUploadPanelOrganism with params object

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 11: `SolveStatusPanelParams` + `SolveStatusPanelOrganism`

**Files:**
- Create: `lib/src/features/questions/presentation/params/solve_status_panel_params.dart`
- Create: `lib/src/features/questions/presentation/organisms/solve_status_panel_organism.dart`

The organism's inputs are grouped into a `SolveStatusPanelParams` value object holding the already-resolved `SolveStatusContent` + callbacks. Plain holder, not `Equatable`. The organism renders `params.content.title` / `params.content.body` + conditional `StatusActionRowMolecule`. **No bloc, no mapper call.**

- [ ] **Step 1: Create the param object**

```dart
import 'package:doormer/src/features/questions/presentation/mapper/solve_status_presenter.dart';
import 'package:flutter/foundation.dart';

class SolveStatusPanelParams {
  final SolveStatusContent content;
  final VoidCallback onRetake;
  final VoidCallback onTypeInstead;

  const SolveStatusPanelParams({
    required this.content,
    required this.onRetake,
    required this.onTypeInstead,
  });
}
```

- [ ] **Step 2: Create the organism**

```dart
import 'package:doormer/src/core/theme/app_text_styles.dart';
import 'package:doormer/src/features/questions/presentation/molecules/status_action_row_molecule.dart';
import 'package:doormer/src/features/questions/presentation/params/solve_status_panel_params.dart';
import 'package:doormer/src/shared/design/atomic/atoms/surface_card_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SolveStatusPanelOrganism extends StatelessWidget {
  final SolveStatusPanelParams params;

  const SolveStatusPanelOrganism({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    final content = params.content;

    return SurfaceCardAtom(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content.title,
            style: AppTextStyles.titleLarge.copyWith(fontSize: 20.sp),
          ),
          SizedBox(height: 10.h),
          Text(
            content.body,
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 14.sp),
          ),
          if (content.showActions) ...[
            SizedBox(height: 20.h),
            StatusActionRowMolecule(
              onRetake: params.onRetake,
              onTypeInstead: params.onTypeInstead,
            ),
          ],
        ],
      ),
    );
  }
}
```

> Note: `SolveStatusPanelParams` imports `solve_status_presenter.dart` only for the `SolveStatusContent` **type**, never to *call* `solveStatusContentFor`. The page resolves the content and injects it via the param. This satisfies the "page-invoked only" guardrail (the mapping function is never called below the page).

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/src/features/questions/presentation/params/solve_status_panel_params.dart lib/src/features/questions/presentation/organisms/solve_status_panel_organism.dart`
Expected: no errors, no warnings.

- [ ] **Step 4: Commit**

```bash
git add lib/src/features/questions/presentation/params/solve_status_panel_params.dart lib/src/features/questions/presentation/organisms/solve_status_panel_organism.dart
git commit -m "feat(questions): extract SolveStatusPanelOrganism with params object

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 12: `AskByPhotoTemplate`

**Files:**
- Create: `lib/src/features/questions/presentation/templates/ask_by_photo_template.dart`

Owns `Scaffold` + `SafeArea` + `SingleChildScrollView` + `ConstrainedBox` + the `LayoutBuilder` 1col/2col layout (was `_AskByPhotoContent`). Takes the two param objects and forwards each whole to its organism; composes the header molecule itself. **No bloc, no `flutter_bloc` import, no content derivation** — it only arranges; the page resolves `statusContent` and packs the params.

- [ ] **Step 1: Create the template**

```dart
import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:doormer/src/features/questions/presentation/molecules/ask_by_photo_header_molecule.dart';
import 'package:doormer/src/features/questions/presentation/organisms/photo_upload_panel_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solve_status_panel_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/photo_upload_panel_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solve_status_panel_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AskByPhotoTemplate extends StatelessWidget {
  final PhotoUploadPanelParams uploadParams;
  final SolveStatusPanelParams statusParams;

  const AskByPhotoTemplate({
    super.key,
    required this.uploadParams,
    required this.statusParams,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 32.h),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 980.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AskByPhotoHeaderMolecule(),
                  SizedBox(height: 28.h),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 720.w;
                      final uploadPanel =
                          PhotoUploadPanelOrganism(params: uploadParams);
                      final statusPanel =
                          SolveStatusPanelOrganism(params: statusParams);

                      if (!isWide) {
                        return Column(
                          children: [
                            uploadPanel,
                            SizedBox(height: 20.h),
                            statusPanel,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: uploadPanel),
                          SizedBox(width: 24.w),
                          Expanded(flex: 4, child: statusPanel),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/src/features/questions/presentation/templates/ask_by_photo_template.dart`
Expected: no errors, no warnings.

- [ ] **Step 3: Commit**

```bash
git add lib/src/features/questions/presentation/templates/ask_by_photo_template.dart
git commit -m "feat(questions): add AskByPhotoTemplate

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 13: `SolutionHandoffTemplate`

**Files:**
- Create: `lib/src/features/questions/presentation/templates/solution_handoff_template.dart`

The handoff card layout built on `SurfaceCardAtom(padding: 24.w, radius: 16.r)` to preserve the current spacing/corner exactly. Fed plain primitives (`questionId`, `stepCount`) instead of the `AskByPhotoSolved` state.

- [ ] **Step 1: Create the template**

```dart
import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:doormer/src/core/theme/app_text_styles.dart';
import 'package:doormer/src/shared/design/atomic/atoms/surface_card_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SolutionHandoffTemplate extends StatelessWidget {
  final String questionId;
  final int? stepCount;

  const SolutionHandoffTemplate({
    super.key,
    required this.questionId,
    this.stepCount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 520.w),
            child: Padding(
              padding: EdgeInsets.all(28.w),
              child: SurfaceCardAtom(
                padding: EdgeInsets.all(24.w),
                radius: 16.r,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solution ready',
                      style: AppTextStyles.titleLarge.copyWith(fontSize: 22.sp),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'Question ID: $questionId',
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 14.sp),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'The solved payload is attached to this route for the US-3 solution view. This screen does not render math.',
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 14.sp),
                    ),
                    if (stepCount != null) ...[
                      SizedBox(height: 12.h),
                      Text(
                        'Steps received: $stepCount',
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 12.sp),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/src/features/questions/presentation/templates/solution_handoff_template.dart`
Expected: no errors, no warnings.

- [ ] **Step 3: Commit**

```bash
git add lib/src/features/questions/presentation/templates/solution_handoff_template.dart
git commit -m "feat(questions): add SolutionHandoffTemplate

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 14: Rewrite `AskByPhotoPage` to delegate to the template

**Files:**
- Modify (full rewrite): `lib/src/features/questions/presentation/pages/ask_by_photo_page.dart`

The page keeps the bloc provider, the `BlocConsumer` listener (toast + navigation, verbatim), and `_pickPhoto`. The builder now derives plain values, calls the mapper for `statusContent`, packs everything into `PhotoUploadPanelParams` + `SolveStatusPanelParams`, and passes the two params to `AskByPhotoTemplate`. All inline `_*` widget classes and `_StatusContent` are deleted. **Do not import `dart:typed_data`** — `Uint8List` is never named here (inferred via `selected?.imageBytes`), so importing it would be an unused-import warning.

- [ ] **Step 1: Replace the entire file contents**

```dart
import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solve_status_presenter.dart';
import 'package:doormer/src/features/questions/presentation/params/photo_upload_panel_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solve_status_panel_params.dart';
import 'package:doormer/src/features/questions/presentation/templates/ask_by_photo_template.dart';
import 'package:doormer/src/shared/widget/custom_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

class AskByPhotoPage extends StatelessWidget {
  const AskByPhotoPage({super.key});

  Future<void> _pickPhoto(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'heic', 'heif'],
        allowMultiple: false,
        withData: true,
      );

      if (!context.mounted) return;

      if (result == null || result.files.isEmpty) {
        context.read<AskByPhotoBloc>().add(const AskByPhotoPickCancelled());
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        context.read<AskByPhotoBloc>().add(
              const AskByPhotoPickUnavailable(
                'We could not read that photo. Please try again.',
              ),
            );
        return;
      }

      context.read<AskByPhotoBloc>().add(
            AskByPhotoPhotoPicked(
              imageBytes: bytes,
              fileName: file.name,
            ),
          );
    } catch (e, stackTrace) {
      AppLogger.error('Photo picker failed', error: e, stackTrace: stackTrace);
      if (!context.mounted) return;
      context.read<AskByPhotoBloc>().add(
            const AskByPhotoPickUnavailable(
              'Camera or photo picker is unavailable. Please upload a JPEG or PNG instead.',
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AskByPhotoBloc>(
      create: (_) => serviceLocator<AskByPhotoBloc>(),
      child: BlocConsumer<AskByPhotoBloc, AskByPhotoState>(
        listener: (context, state) {
          if (state is AskByPhotoNotice) {
            CustomToast.show(
              context,
              message: state.message,
              type: ToastificationType.info,
            );
          } else if (state is AskByPhotoValidationError) {
            CustomToast.show(
              context,
              message: state.message,
              type: ToastificationType.warning,
            );
          } else if (state is AskByPhotoNetworkError) {
            CustomToast.show(
              context,
              message: state.message,
              type: ToastificationType.error,
            );
          } else if (state is AskByPhotoTypeInstead) {
            CustomToast.show(
              context,
              message: 'Typed question entry is coming soon.',
              type: ToastificationType.info,
            );
          } else if (state is AskByPhotoSolved) {
            final questionId = Uri.encodeComponent(state.questionId);
            GoRouter.of(context).go(
              '/questions/$questionId/solution',
              extra: state,
            );
          }
        },
        builder: (context, state) {
          final selected =
              state is AskByPhotoPhotoSelected ? state : null;
          final isLoading = state is AskByPhotoLoading;

          return AskByPhotoTemplate(
            uploadParams: PhotoUploadPanelParams(
              imageBytes: selected?.imageBytes,
              fileName: selected?.fileName,
              isLoading: isLoading,
              onPickPhoto: () => _pickPhoto(context),
              onSubmit: () => context
                  .read<AskByPhotoBloc>()
                  .add(const AskByPhotoSubmitted()),
              onClear: () => context
                  .read<AskByPhotoBloc>()
                  .add(const AskByPhotoClearRequested()),
            ),
            statusParams: SolveStatusPanelParams(
              content: solveStatusContentFor(state),
              onRetake: () {
                context
                    .read<AskByPhotoBloc>()
                    .add(const AskByPhotoClearRequested());
                _pickPhoto(context);
              },
              onTypeInstead: () => context
                  .read<AskByPhotoBloc>()
                  .add(const AskByPhotoTypeInsteadRequested()),
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/src/features/questions`
Expected: no errors, no new warnings. In particular, no "unused import" for `dart:typed_data` (it must not be present) and no leftover references to the deleted `_*` classes.

- [ ] **Step 3: Commit**

```bash
git add lib/src/features/questions/presentation/pages/ask_by_photo_page.dart
git commit -m "refactor(questions): delegate AskByPhotoPage to atomic template

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 15: Rewrite `QuestionSolutionHandoffPage` to delegate to the template

**Files:**
- Modify (full rewrite): `lib/src/features/questions/presentation/pages/question_solution_handoff_page.dart`

Keeps its class name and constructor (`questionId`, `solvedState`) so the router is untouched. Maps `solvedState` → `SolutionHandoffTemplate`. Still imports the bloc for the `AskByPhotoSolved` field type.

- [ ] **Step 1: Replace the entire file contents**

```dart
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
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/src/features/questions lib/src/core/routes/web_router.dart`
Expected: no errors, no new warnings. The router still constructs `QuestionSolutionHandoffPage(questionId:, solvedState:)` unchanged.

- [ ] **Step 3: Commit**

```bash
git add lib/src/features/questions/presentation/pages/question_solution_handoff_page.dart
git commit -m "refactor(questions): delegate QuestionSolutionHandoffPage to template

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 16: Full verification & manual smoke test

**Files:** none (verification only)

- [ ] **Step 1: Full static analysis**

Run: `flutter analyze`
Expected: clean — no new warnings versus the Task 0 baseline.

- [ ] **Step 2: Confirm no stray bloc/mapper coupling below the page**

Run: `grep -rn "flutter_bloc" lib/src/features/questions/presentation/{atoms,molecules,organisms,templates,params}`
Expected: **no matches** (no presentational layer or param object imports `flutter_bloc`).

Run: `grep -rn "solveStatusContentFor" lib/src/features/questions/presentation/{atoms,molecules,organisms,templates,params}`
Expected: **no matches** (the mapper *function* is called only by the page; `SolveStatusPanelParams` and the organism may reference the `SolveStatusContent` *type* but never call the function).

- [ ] **Step 3: Manual smoke test (web)**

Run: `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8888`

Confirm the ask-by-photo screen behaves identically to before:
- Empty state: scanner icon + "JPEG or PNG · max 10 MB" hint, viewfinder corners in deep-orange accent.
- Choose photo → preview renders, filename shows, Clear + Submit appear.
- Submit while loading → accent button shows the spinner and is disabled.
- Each outcome state (unreadable / not-a-question / timeout / validation error / network error / loading / initial) shows the correct title/body, and Retake + Type instead appear only when expected.
- Responsive: narrow viewport stacks the two panels; wide (≥720) shows the 5:4 two-column row.
- Navigate to a solved state → `/questions/<id>/solution` renders the handoff card ("Solution ready", question id, steps received).

Expected: visually identical except buttons now share a single `14.h` vertical padding (intentional polish).

- [ ] **Step 4: Final confirmation commit (only if any touch-ups were needed)**

If Steps 1–3 surfaced fixes, commit them:

```bash
git add -A
git commit -m "fix(questions): smoke-test touch-ups for atomic refactor

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

If nothing needed fixing, no commit is required — the refactor is complete.

---

## Self-Review Checklist (completed during planning)

**Spec coverage:** every spec component has a task — AppButtonAtom (T2), SurfaceCardAtom (T3), ViewfinderCornersAtom (T4), AskByPhotoHeaderMolecule (T5), PhotoPreviewMolecule (T6), PhotoActionRowMolecule (T7), StatusActionRowMolecule (T8), SolveStatusContent/mapper (T9), PhotoUploadPanelParams + PhotoUploadPanelOrganism (T10), SolveStatusPanelParams + SolveStatusPanelOrganism (T11), AskByPhotoTemplate (T12), SolutionHandoffTemplate (T13), page rewrites (T14, T15), accent token (T1), verification (T0, T16). Token alias, padding normalisation, surface-padding preservation (24.w/16.r handoff), outlined border colors (borders vs focusedBorders), the Parameter Object pattern at the organism/template layer, and the "no bloc/mapper below page" guardrail are all encoded.

**Type consistency:** `SolveStatusContent` (fields `title`/`body`/`showActions`) and `solveStatusContentFor(AskByPhotoState)` are defined in T9; `SolveStatusContent` is wrapped by `SolveStatusPanelParams` (T11) and resolved in the page (T14). `PhotoUploadPanelParams` (fields `imageBytes`/`fileName`/`isLoading`/`onPickPhoto`/`onSubmit`/`onClear`, T10) and `SolveStatusPanelParams` (fields `content`/`onRetake`/`onTypeInstead`, T11) are consumed by their organisms (T10/T11), forwarded whole by the template (T12), and constructed by the page (T14) — field names match across all sites. `AppButtonVariant.{filled,accent,outlined}` defined in T2, used consistently in T7/T8/T10. `imageBytes` is `Uint8List?` everywhere it appears (T6/T10); the template (T12) and page (T14) never name the type. Param objects are plain holders (not `Equatable`).

**No placeholders:** every code step contains complete, compilable code.
