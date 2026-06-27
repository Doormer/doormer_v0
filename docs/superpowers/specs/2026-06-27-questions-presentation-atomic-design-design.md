# Refactor: Questions Presentation Layer → Atomic Design

**Date:** 2026-06-27
**Status:** Approved (design)
**Scope:** `lib/src/features/questions/presentation/` + a new shared design-system seam under `lib/src/shared/design/`

## Problem

The questions feature's presentation layer is structurally flat and monolithic:

- `ask_by_photo_page.dart` is **577 lines** holding **8 widget classes** (`_AskByPhotoContent`, `_Header`, `_UploadPanel`, `_PreviewFrame`, `_EmptyPreview`, `_ViewfinderCorners`, `_StatusPanel`) plus the `_StatusContent` plain data holder, inside one file. Layout, presentation, and bloc wiring are tangled together.
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

## Tokens

The existing `core/theme/AppColors` and `core/theme/AppTextStyles` **are** the token layer. Atoms consume them. We do not create `SectionTitleAtom` / `BodyTextAtom` wrappers — that would be redundant indirection over `AppTextStyles`.

**One token change (issue #2 — shared atom must not leak a feature-named token):**
The accent button currently maps to `AppColors.uploadButton` (`= Colors.deepOrangeAccent`). A purpose-agnostic *shared* atom must not reference a token literally named `uploadButton`. We introduce a semantic alias:

```dart
// core/theme/app_colors.dart
static const Color accent = Colors.deepOrangeAccent;   // semantic token consumed by shared atoms
static const Color uploadButton = accent;              // plain alias — still used by the registration feature
```

`AppButtonAtom`'s `accent` variant references `AppColors.accent`. `uploadButton` remains a normal (non-deprecated) alias because the registration feature still uses that name; no deprecation warnings are introduced. The viewfinder corner color also migrates to `AppColors.accent`.

## Target Structure

```
lib/src/shared/design/atomic/atoms/
  app_button_atom.dart          # AppButtonAtom
  surface_card_atom.dart        # SurfaceCardAtom (bordered/rounded panel surface)

lib/src/features/questions/presentation/
  atoms/
    viewfinder_corners_atom.dart      # ViewfinderCornersAtom (questions-specific decorative atom)
  molecules/
    ask_by_photo_header_molecule.dart # AskByPhotoHeaderMolecule (was _Header — title + supporting text)
    photo_preview_molecule.dart       # PhotoPreviewMolecule  (was _PreviewFrame + _EmptyPreview)
    photo_action_row_molecule.dart    # PhotoActionRowMolecule (choose/retake + clear)
    status_action_row_molecule.dart   # StatusActionRowMolecule (retake + type-instead)
  organisms/
    photo_upload_panel_organism.dart  # PhotoUploadPanelOrganism (was _UploadPanel)
    solve_status_panel_organism.dart  # SolveStatusPanelOrganism (was _StatusPanel)
  templates/
    ask_by_photo_template.dart        # AskByPhotoTemplate (data-driven: builds organisms, owns responsive layout)
    solution_handoff_template.dart    # SolutionHandoffTemplate (was the handoff page body)
  mapper/
    solve_status_presenter.dart       # SolveStatusContent + solveStatusContentFor(state) (was _StatusContent + _contentFor)
  pages/
    ask_by_photo_page.dart            # AskByPhotoPage (bloc provider/consumer/events only)
    question_solution_handoff_page.dart # QuestionSolutionHandoffPage (maps route data → template)
  bloc/                               # unchanged
```

### Layer placement rationale

- **`AppButtonAtom` and `SurfaceCardAtom` are shared** — both are generic and purpose-agnostic, reused across both panels and the handoff card, and reusable by future features. They live in `shared/design/atomic/atoms/`. The surface card removes the bordered-`BoxDecoration` that is currently copy-pasted in **three** places (upload panel, status panel, handoff card) — eliminating it is the same DRY win as the button atom (issue #1). `SurfaceCardAtom` is a **pure visual primitive**: it only applies the surface treatment (color/border/radius/padding) to an arbitrary `child`. It must never bake in semantic structure (title, body, action slots, content rules); the moment it would, it becomes a molecule. This guardrail comes out of the three-model review.
- **`AskByPhotoHeaderMolecule` is a molecule, not an organism** — it is a title + supporting-text pair functioning as one intro unit. All three review models (Gemini 3.1 Pro, GPT-5.5, Opus 4.8) independently flagged that a two-`Text` block is too simple to be an organism (Frost: organisms are "relatively complex... distinct sections"); a heading group maps to an HTML `<hgroup>`, i.e. a molecule. It lives in `molecules/`.
- **`ViewfinderCornersAtom` is questions-local** — it is purely decorative and meaningless outside the photo viewfinder, so it is a feature-local atom, not a shared one. It stays an **atom** by Frost's *decomposability* test: it is a single indivisible decorative overlay with no independently-named sub-components (the four brackets are produced by a private `_corner` helper, not standalone widgets). Note: the canonical atom test is decomposability — "can't be broken down further without ceasing to be functional" — **not** reusability (an earlier draft justified this by reusability, which is actually a *molecule* property; corrected per the three-model review).
- The **state → copy mapping** lives in `mapper/solve_status_presenter.dart`, not inside a widget. `SolveStatusContent` is a plain value object and `solveStatusContentFor(AskByPhotoState)` is a pure function (the old `_contentFor` switch). It is **page-invoked only**: the `AskByPhotoPage` calls it and passes the resolved `SolveStatusContent` down as a prop. No organism, molecule, or template may import the mapper — doing so would smuggle page-level content/variation decisions into a presentational layer (Frost: state-driven content variations belong at the Pages level). This keeps the page lean and the ~6 title/body strings out of widget code (issue #5).

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
  final Color? borderColor;          // outlined only; defaults to AppColors.borders
}
```

- `filled` → `AppColors.primary` / `onPrimary` (the "Choose photo", "Retake" buttons).
- `accent` → `AppColors.accent` / `onPrimary` (the "Submit to solver" button).
- `outlined` → transparent with `AppColors.primary` foreground and a `borderColor` side (the "Clear", "Type instead" buttons). **The two current outlined buttons use different borders** — "Clear" uses `AppColors.borders` (current L284) and "Type instead" uses `AppColors.focusedBorders` (current L493). The `borderColor` param preserves both exactly; callers pass the matching color (cross-validation finding #1).
- `isLoading` renders the sized `CircularProgressIndicator` exactly as today.
- **Padding is standardised** to a single vertical value (`14.h`) as part of the light polish (option B). The current buttons vary slightly (`14.h` choose/clear, `15.h` submit, `13.h` status actions); normalising them to `14.h` is an accepted, deliberate polish change — this is the *only* spacing change in scope and is called out explicitly so it is not mistaken for a regression (cross-validation finding #2). Radius stays `8.r`.

### `SurfaceCardAtom` (shared atom)

Collapses the bordered-surface container duplicated across the upload panel, status panel, and handoff card.

```dart
class SurfaceCardAtom extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;   // default EdgeInsets.all(22.w)
  final double radius;                 // default 18.r
}
```

Renders `Container(decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.borders), borderRadius: BorderRadius.circular(radius)))`. The two photo panels use the defaults (`padding: 22.w`, `radius: 18.r`). The handoff card passes `padding: EdgeInsets.all(24.w), radius: 16.r` to preserve its current spacing and corner exactly (cross-validation finding #3). **Constraint (atomic-design guardrail):** this atom takes only a `child` and styling params — it must not gain `title`/`subtitle`/`actions`/named content slots. If a future need wants a structured card, build a *molecule* that composes `SurfaceCardAtom`, do not extend the atom.

### `AskByPhotoHeaderMolecule`
Move of `_Header` — a heading + supporting-text pair, no params (static copy via `AppTextStyles`). Classified as a **molecule** (not an organism): per the three-model review it is a simple title/subtitle group, the `<hgroup>` equivalent, below the complexity bar for an organism.

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
Renders the choose/retake `AppButtonAtom(filled)` + conditional clear `AppButtonAtom(outlined, borderColor: AppColors.borders)`.

### `StatusActionRowMolecule`
```dart
StatusActionRowMolecule({ required VoidCallback onRetake, required VoidCallback onTypeInstead })
```
Retake `AppButtonAtom(filled)` + type-instead `AppButtonAtom(outlined, borderColor: AppColors.focusedBorders)`.

### `SolveStatusContent` + `solveStatusContentFor` (mapper, not a widget)
Lives in `mapper/solve_status_presenter.dart`. Pure presentation logic, no Flutter widgets.
```dart
class SolveStatusContent {
  final String title;
  final String body;
  final bool showActions;
  const SolveStatusContent({ required this.title, required this.body, required this.showActions });
}

/// Pure function — the old _contentFor switch. Maps a bloc state to display copy.
SolveStatusContent solveStatusContentFor(AskByPhotoState state);
```
Keeping this a pure function (rather than a widget method or page-inlined switch) makes the ~6 outcome strings unit-testable without any widget, and keeps both the page and the status organism free of copy. **Page-invoked only** — no widget layer imports this mapper.

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
`SurfaceCardAtom` + "Photo input" title + `PhotoPreviewMolecule` + filename + `PhotoActionRowMolecule` + submit `AppButtonAtom(accent, expand)`. **No bloc access** — takes plain data instead of `AskByPhotoPhotoSelected?`.

### `SolveStatusPanelOrganism`
```dart
SolveStatusPanelOrganism({
  required SolveStatusContent content,
  required VoidCallback onRetake,
  required VoidCallback onTypeInstead,
})
```
`SurfaceCardAtom` rendering `content.title` / `content.body` and, when `content.showActions`, a `StatusActionRowMolecule`. The state → `SolveStatusContent` mapping is done by the `solveStatusContentFor` mapper (called in the page), so the organism stays presentational and bloc-free.

### `AskByPhotoTemplate` (data-driven)
```dart
AskByPhotoTemplate({
  // upload panel data + callbacks
  Uint8List? imageBytes,
  String? fileName,
  required bool isLoading,
  required VoidCallback onPickPhoto,
  required VoidCallback onSubmit,
  required VoidCallback onClear,
  // status panel data + callbacks
  required SolveStatusContent statusContent,
  required VoidCallback onRetake,
  required VoidCallback onTypeInstead,
})
```
Owns the `Scaffold` + `SafeArea` + `SingleChildScrollView` + `ConstrainedBox` + the `LayoutBuilder` responsive 1col/2col arrangement (was `_AskByPhotoContent`). **It composes the organisms itself** (`AskByPhotoHeaderMolecule`, `PhotoUploadPanelOrganism`, `SolveStatusPanelOrganism`) from the data passed in — it is not a generic slot container, so the `AskByPhoto` name stays honest and the template matches the referenced article's data-driven template layer (issue #3). It holds no bloc and no `flutter_bloc` import; all dynamic values arrive as constructor args.

**Atomic-design guardrail (from the three-model review):** the template *receives already-resolved data and callbacks* but **never derives or chooses content** — no state inspection, no `solveStatusContentFor` call, no mapping. The page resolves all content (including the `statusContent` variation) and injects it; the template only arranges structure. This is the code-level realization of Frost's "template = content structure, page = real content + variations." Two of three reviewers (GPT-5.5, Opus 4.8) judged the data-driven template faithful given this guardrail; the dissent (Gemini, preferring `Widget` slots) is noted but the data-driven choice was the user's explicit decision in issue #3.

### `SolutionHandoffTemplate`
```dart
SolutionHandoffTemplate({ required String questionId, int? stepCount })
```
The handoff card layout (built on `SurfaceCardAtom`), fed plain primitives instead of the `AskByPhotoSolved` state object.

## Page Responsibilities (the only bloc-aware layer)

### `AskByPhotoPage`
- Provides the bloc (`BlocProvider` + `serviceLocator<AskByPhotoBloc>()`) — unchanged.
- `BlocConsumer`:
  - **listener**: toast handling + `GoRouter` navigation on `AskByPhotoSolved` — unchanged.
  - **builder**: derive plain values from state (`imageBytes`, `fileName`, `isLoading`) and compute `statusContent` via `solveStatusContentFor(state)` (the mapper), then pass data + callbacks to `AskByPhotoTemplate` (the template composes the organisms itself).
- Keeps `_pickPhoto` file-picker logic and event dispatch (`onPickPhoto`, `onSubmit`, `onClear`, `onRetake`, `onTypeInstead`) — the page wires callbacks to `context.read<AskByPhotoBloc>().add(...)`.

### `QuestionSolutionHandoffPage`
- Maps `solvedState` → `SolutionHandoffTemplate(questionId:, stepCount: solvedState?.solution.steps.length)`.

## Data Flow

```
AskByPhotoBloc state ──┐
                       ▼
            AskByPhotoPage.builder
   (derives imageBytes/fileName/isLoading,
    computes statusContent = solveStatusContentFor(state),
    wires event callbacks)
                       │ plain data + callbacks
                       ▼
            AskByPhotoTemplate (layout only — composes the widgets below)
            ├── AskByPhotoHeaderMolecule
            ├── PhotoUploadPanelOrganism ── SurfaceCardAtom
            │     ├── PhotoPreviewMolecule ── ViewfinderCornersAtom
            │     └── PhotoActionRowMolecule ── AppButtonAtom ×N
            └── SolveStatusPanelOrganism ── SurfaceCardAtom
                  └── StatusActionRowMolecule ── AppButtonAtom ×2
```

No widget below `Page` imports `flutter_bloc` or the bloc, and the `solveStatusContentFor` mapper is a pure function. This is the key testability win: organisms/molecules/atoms can be widget-tested with plain constructor args, and the status copy is unit-testable without any widget.

## Light Visual Polish (option B)

Limited to what the atoms naturally standardise:

- **One button radius and padding** across all buttons (currently `8.r` everywhere already, but variant-by-variant duplicated — now centralised in `AppButtonAtom`).
- **Consistent surface treatment**: the bordered/rounded panel is centralised in `SurfaceCardAtom` and reused by both panels and the handoff card, removing three copies of the same `BoxDecoration`.
- Loading spinner standardised inside `AppButtonAtom`.
- No colour, copy, or layout changes. The **only** spacing change is normalising button vertical padding to `14.h` (see `AppButtonAtom`); surface paddings are preserved exactly via `SurfaceCardAtom` params. (The `uploadButton`→`accent` token rename is a no-op visually — same `deepOrangeAccent` value.)

## Error Handling

No change. The bloc's typed-`Failure` handling and the page's toast/navigation logic are preserved verbatim. Presentational widgets have no error paths.

## Testing / Verification

No automated tests exist in the repo. Verification is:

1. `flutter analyze` is clean (no new warnings).
2. `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8888` — manually confirm the ask-by-photo screen and solution handoff render and behave identically (pick, clear, submit, each outcome state, responsive 1col/2col).

## Migration / Sequencing

1. Add the `accent` token (alias `uploadButton`) in `AppColors`.
2. Add shared atoms: `AppButtonAtom`, `SurfaceCardAtom`. Add local `ViewfinderCornersAtom`.
3. Add the mapper `solve_status_presenter.dart` (`SolveStatusContent` + `solveStatusContentFor`).
4. Build molecules (`AskByPhotoHeaderMolecule`, `PhotoPreviewMolecule`, `PhotoActionRowMolecule`, `StatusActionRowMolecule`).
5. Build organisms (`PhotoUploadPanelOrganism`, `SolveStatusPanelOrganism`) consuming molecules/atoms.
6. Build templates (data-driven; arrange the header molecule + organisms; no content derivation).
7. Rewrite the two pages to derive plain data + `statusContent` and pass them to the templates; delete the old inline `_*` widget classes.
8. `flutter analyze`; manual smoke test.

Router and DI files are untouched (pages keep their class names and constructors).

## Risks

- **`AskByPhotoSolved` coupling in the router**: unchanged — the router still passes the state object as `extra`; only the page→template boundary is decoupled. Acceptable for this scope.
- **Shared-folder precedent**: `shared/design/atomic/` is a new top-level seam. It is intentionally minimal (two atoms: button + surface card) to avoid speculative generality; future generic atoms graduate here.
- **Token alias**: a new semantic `accent` token is added and `uploadButton` becomes a plain alias of it. `uploadButton` is also used by the registration feature, so it is **not** deprecated — both names resolve to the same `deepOrangeAccent` value and no warnings are introduced. Only the questions feature's usages migrate to `accent`.
