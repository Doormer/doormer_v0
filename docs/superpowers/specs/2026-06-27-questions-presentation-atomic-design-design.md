# Refactor: Questions Presentation Layer → Atomic Design

**Date:** 2026-06-27
**Status:** Approved (design)
**Scope:** `lib/src/features/questions/presentation/` + a new shared design-system seam under `lib/src/shared/design/`

## Problem

The questions feature's presentation layer is structurally flat and monolithic:

- `ask_by_photo_page.dart` is **577 lines** holding **9 widget classes** (`_AskByPhotoContent`, `_Header`, `_UploadPanel`, `_PreviewFrame`, `_EmptyPreview`, `_ViewfinderCorners`, `_StatusPanel`, plus the `_StatusContent` data holder) inside one file. Layout, presentation, and bloc wiring are tangled together.
- `question_solution_handoff_page.dart` mixes layout with page concerns.
- Button styling (filled / accent / outlined, padding, radius, loading spinner) is **copy-pasted** across the upload panel and status panel.
- Nothing below the page is testable without instantiating the bloc, because the widgets read the bloc via `context.read` internally.

We want to reorganise this into an **Atomic Design** hierarchy (Brad Frost: Tokens → Atoms → Molecules → Organisms → Templates → Pages), promoting genuinely generic pieces into a **shared design system** and keeping feature-specific pieces local. While doing so, apply **light visual polish** (option B) that falls naturally out of building consistent atoms — no layout overhaul.

## Goals

1. Decompose the two pages into named atomic layers, one widget per file.
2. Introduce a small shared design-system seam (`shared/design/atomic/atoms/`) for reusable atoms.
3. Make every layer below `Page` a **pure presentational widget** — it receives data + callbacks, never reads the bloc.
4. Keep the existing Tokens (`AppColors`, `AppTextStyles`) as the styling source of truth — do **not** wrap them in redundant atoms.
5. Light visual polish: unified button styling, consistent spacing/radius/elevation, tidy empty/loading/error states. No behavioural or routing changes.

## Non-Goals

- No visual refresh or layout redesign (options C/D were explicitly deferred).
- No changes to `domain/`, `data/`, the bloc's logic, events/states, routing, or DI registration behaviour.
- No new tests (the repo has no test suite yet; infra exists but is out of scope here).
- No conversion of older auth/registration widgets to atomic naming.

## Naming Convention

**Layer suffix on both file and class** (matches the referenced article, self-documenting, AI-navigable):

- `app_button_atom.dart` → `AppButtonAtom`
- `photo_preview_molecule.dart` → `PhotoPreviewMolecule`
- `photo_upload_panel_organism.dart` → `PhotoUploadPanelOrganism`
- `ask_by_photo_template.dart` → `AskByPhotoTemplate`
- Pages keep their existing names (`AskByPhotoPage`, `QuestionSolutionHandoffPage`) — no `_page` rename, to avoid churn in the router.

Files are `snake_case.dart` per repo convention; the folder conveys the layer and the suffix reinforces it in code.

## Tokens (unchanged)

The existing `core/theme/AppColors` and `core/theme/AppTextStyles` **are** the token layer. Atoms consume them. We do not create `SectionTitleAtom` / `BodyTextAtom` wrappers — that would be redundant indirection over `AppTextStyles`.

## Target Structure

```
lib/src/shared/design/atomic/atoms/
  app_button_atom.dart          # AppButtonAtom

lib/src/features/questions/presentation/
  atoms/
    viewfinder_corners_atom.dart      # ViewfinderCornersAtom (questions-specific decorative atom)
  molecules/
    photo_preview_molecule.dart       # PhotoPreviewMolecule  (was _PreviewFrame + _EmptyPreview)
    photo_action_row_molecule.dart    # PhotoActionRowMolecule (choose/retake + clear)
    status_action_row_molecule.dart   # StatusActionRowMolecule (retake + type-instead)
    solve_status_content.dart         # SolveStatusContent (the title/body/showActions value object, was _StatusContent)
  organisms/
    ask_by_photo_header_organism.dart # AskByPhotoHeaderOrganism (was _Header)
    photo_upload_panel_organism.dart  # PhotoUploadPanelOrganism (was _UploadPanel)
    solve_status_panel_organism.dart  # SolveStatusPanelOrganism (was _StatusPanel + _contentFor mapping)
  templates/
    ask_by_photo_template.dart        # AskByPhotoTemplate (was _AskByPhotoContent: responsive 1col/2col)
    solution_handoff_template.dart    # SolutionHandoffTemplate (was the handoff page body)
  pages/
    ask_by_photo_page.dart            # AskByPhotoPage (bloc provider/consumer/events only)
    question_solution_handoff_page.dart # QuestionSolutionHandoffPage (maps route data → template)
  bloc/                               # unchanged
```

### Layer placement rationale

- **`AppButtonAtom` is shared** — generic, purpose-agnostic, reused across both panels and reusable by future features. Lives in `shared/design/atomic/atoms/`.
- **`ViewfinderCornersAtom` is questions-local** — it is purely decorative and meaningless outside the photo viewfinder, so it is a feature-local atom, not a shared one.
- The `SolveStatusContent` value object (formerly `_StatusContent`) lives under `molecules/` as a plain data holder used by the status organism. It is not a widget.

## Component Contracts

### `AppButtonAtom` (shared atom)

Collapses the three duplicated button styles + spinner into one configurable atom.

```dart
enum AppButtonVariant { filled, accent, outlined }

class AppButtonAtom extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;     // null disables
  final AppButtonVariant variant;    // default filled
  final IconData? icon;              // optional leading icon
  final bool isLoading;              // shows spinner, absorbs the old inline CircularProgressIndicator
  final bool expand;                 // full-width (double.infinity) when true
}
```

- `filled` → `AppColors.primary` / `onPrimary` (the "Choose photo", "Retake" buttons).
- `accent` → `AppColors.uploadButton` / `onPrimary` (the "Submit to solver" button).
- `outlined` → transparent with `AppColors.borders`/`focusedBorders` side, `AppColors.primary` foreground (the "Clear", "Type instead" buttons).
- `isLoading` renders the sized `CircularProgressIndicator` exactly as today.
- Consistent padding/radius become the atom's defaults (the **light polish**): one radius (`8.r`), consistent vertical padding.

### `ViewfinderCornersAtom` (local atom)
Pure move of `_ViewfinderCorners` — no API, decorative overlay.

### `PhotoPreviewMolecule`
```dart
PhotoPreviewMolecule({ Uint8List? imageBytes, })  // null → empty state with hint text + scanner icon
```
Wraps `AspectRatio` + bordered container + `ViewfinderCornersAtom`. Absorbs `_EmptyPreview`.

### `PhotoActionRowMolecule`
```dart
PhotoActionRowMolecule({
  required bool hasPhoto,
  required bool isLoading,
  required VoidCallback onPick,
  VoidCallback? onClear,
})
```
Renders the choose/retake `AppButtonAtom(filled)` + conditional clear `AppButtonAtom(outlined)`.

### `StatusActionRowMolecule`
```dart
StatusActionRowMolecule({ required VoidCallback onRetake, required VoidCallback onTypeInstead })
```
Two `AppButtonAtom`s (filled + outlined).

### `SolveStatusContent` (value object)
```dart
class SolveStatusContent {
  final String title;
  final String body;
  final bool showActions;
  const SolveStatusContent({ required this.title, required this.body, required this.showActions });
}
```

### `AskByPhotoHeaderOrganism`
Pure move of `_Header`. No params (static copy from `AppTextStyles`).

### `PhotoUploadPanelOrganism`
```dart
PhotoUploadPanelOrganism({
  Uint8List? imageBytes,
  String? fileName,
  required bool isLoading,
  required VoidCallback onPickPhoto,
  required VoidCallback onSubmit,
  required VoidCallback onClear,
})
```
Surface container + "Photo input" title + `PhotoPreviewMolecule` + filename + `PhotoActionRowMolecule` + submit `AppButtonAtom(accent, expand)`. **No bloc access** — takes plain data instead of `AskByPhotoPhotoSelected?`.

### `SolveStatusPanelOrganism`
```dart
SolveStatusPanelOrganism({
  required SolveStatusContent content,
  required VoidCallback onRetake,
  required VoidCallback onTypeInstead,
})
```
Surface container rendering `content.title` / `content.body` and, when `content.showActions`, a `StatusActionRowMolecule`. The **state → `SolveStatusContent` mapping** (the old `_contentFor` switch) moves to the **page**, so the organism stays presentational and bloc-free.

### `AskByPhotoTemplate`
```dart
AskByPhotoTemplate({
  required Widget header,
  required Widget uploadPanel,
  required Widget statusPanel,
})
```
Owns the `Scaffold` + `SafeArea` + `SingleChildScrollView` + `ConstrainedBox` + the `LayoutBuilder` responsive 1col/2col arrangement (was `_AskByPhotoContent`). Pure layout, no data, no bloc. Receives already-built organisms.

### `SolutionHandoffTemplate`
```dart
SolutionHandoffTemplate({ required String questionId, int? stepCount })
```
The handoff card layout, fed plain primitives instead of the `AskByPhotoSolved` state object.

## Page Responsibilities (the only bloc-aware layer)

### `AskByPhotoPage`
- Provides the bloc (`BlocProvider` + `serviceLocator<AskByPhotoBloc>()`) — unchanged.
- `BlocConsumer`:
  - **listener**: toast handling + `GoRouter` navigation on `AskByPhotoSolved` — unchanged.
  - **builder**: derive plain values from state (`imageBytes`, `fileName`, `isLoading`) and the `SolveStatusContent` (moving `_contentFor` here), then build the three organisms and hand them to `AskByPhotoTemplate`.
- Keeps `_pickPhoto` file-picker logic and event dispatch (`onPickPhoto`, `onSubmit`, `onClear`, `onRetake`, `onTypeInstead`) — the page wires callbacks to `context.read<AskByPhotoBloc>().add(...)`.

### `QuestionSolutionHandoffPage`
- Maps `solvedState` → `SolutionHandoffTemplate(questionId:, stepCount: solvedState?.solution.steps.length)`.

## Data Flow

```
AskByPhotoBloc state ──┐
                       ▼
            AskByPhotoPage.builder
   (derives imageBytes/fileName/isLoading + SolveStatusContent,
    wires event callbacks)
                       │ plain data + callbacks
                       ▼
            AskByPhotoTemplate (layout)
            ├── AskByPhotoHeaderOrganism
            ├── PhotoUploadPanelOrganism
            │     ├── PhotoPreviewMolecule ── ViewfinderCornersAtom
            │     └── PhotoActionRowMolecule ── AppButtonAtom ×N
            └── SolveStatusPanelOrganism
                  └── StatusActionRowMolecule ── AppButtonAtom ×2
```

No widget below `Page` imports `flutter_bloc` or the bloc. This is the key testability win: organisms/molecules/atoms can be widget-tested with plain constructor args.

## Light Visual Polish (option B)

Limited to what the atoms naturally standardise:

- **One button radius and padding** across all buttons (currently `8.r` everywhere already, but variant-by-variant duplicated — now centralised).
- **Consistent surface treatment**: organisms reuse the same border/radius via the existing surface container pattern (kept inline in each organism; no separate surface atom needed since it's two property sets).
- Loading spinner standardised inside `AppButtonAtom`.
- No colour, copy, spacing-scale, or layout changes beyond the above.

## Error Handling

No change. The bloc's typed-`Failure` handling and the page's toast/navigation logic are preserved verbatim. Presentational widgets have no error paths.

## Testing / Verification

No automated tests exist in the repo. Verification is:

1. `flutter analyze` is clean (no new warnings).
2. `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8888` — manually confirm the ask-by-photo screen and solution handoff render and behave identically (pick, clear, submit, each outcome state, responsive 1col/2col).

## Migration / Sequencing

1. Add `AppButtonAtom` (shared) + `ViewfinderCornersAtom` (local).
2. Build molecules (`PhotoPreviewMolecule`, `PhotoActionRowMolecule`, `StatusActionRowMolecule`, `SolveStatusContent`).
3. Build organisms consuming molecules/atoms.
4. Build templates.
5. Rewrite the two pages to map bloc state → organisms via the templates; delete the old inline `_*` widget classes.
6. `flutter analyze`; manual smoke test.

Router and DI files are untouched (pages keep their class names and constructors).

## Risks

- **`AskByPhotoSolved` coupling in the router**: unchanged — the router still passes the state object as `extra`; only the page→template boundary is decoupled. Acceptable for this scope.
- **Shared-folder precedent**: `shared/design/atomic/` is a new top-level seam. It is intentionally minimal (one atom) to avoid speculative generality; future generic atoms graduate here.
