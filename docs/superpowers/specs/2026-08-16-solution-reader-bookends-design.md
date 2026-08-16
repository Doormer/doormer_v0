# Solution Reader — The Missing Bookends

**Date:** 2026-08-16
**Status:** Design
**Feature:** `questions` — solution reader
**Supersedes nothing. Follows:** Milestone 1 (`plan.md`, solution reader reading experience)

## Problem

The solver returns three pieces of content that the app parses, holds in memory, and never shows:

| Field | Lives on | Role for the student |
|---|---|---|
| `approach` | `SolutionDocument.approach` | Orientation — what the data is and what the plan is, *before* the work |
| `verification` | `SolutionDocument.verification` | Confidence — a second route to the same answer, *after* it |
| `note` | `PhotoQuestionSolveOutcome.note` | A caveat about how the question data was read |

`approach` and `verification` reach the presentation layer inside `SolutionDocument` and are simply never read. `note` never even gets that far: it is dropped at **two** boundaries.

1. `AskByPhotoBloc` builds `AskByPhotoSolved(questionId:, solution:)` from the outcome and discards `note`.
2. `SolutionReaderBloc._onStarted` reads `outcome.solution` and discards the rest of the outcome.

So `note` cannot be rendered at all without plumbing, on either entry path.

The reader currently tells a student the middle of the story — steps, then the answer — and neither bookend.

### The content is real

Measured against `assets/mock/mock_question_response.json`:

- `approach` — one text segment, 1064 characters.
- `verification` — three segments: text (494 chars), a `math` block, text (153 chars).
- `note` — one sentence.

**`approach` currently reads as solver telemetry, not student prose.** It opens "Frozen question-data ledger", logs *rejected* student marks, describes diagram topology, and only in its final sentence states a plan a student would recognise. This is a known content problem; the standing decision is to **render it whole and fix it upstream**, not to truncate or summarise it in the client. This design therefore does not parse, split, or editorialise `approach` — whatever the solver sends is what the student sees.

## Non-goals

Everything else in the Milestone 2 bundle is explicitly out: XP counter and pellet flight, streak flame, vault chains and chain-snap, ambient motion loops, math shine sweep, swipe hints, trail panning. Those need an XP data source, new state, and animation infrastructure that does not exist. This design needs none of the three, which is why it is separated from them.

## Shape

Reading order becomes:

```
Brief  ->  Step 1 .. Step n  ->  Answer + Check
```

**Briefing** is a screen of its own, before step 1, with a node at the head of the trail. It is where the reader opens. Its CTA reads "Start solving". Back from step 1 returns to it. It carries `approach` in full, plus `note` as a caveat line.

**Check** is a section below the vault, revealed at the same moment as the answer. A verification read *before* the answer is just another step; read *after* it, it is the thing that makes the answer trustworthy.

### Why not the alternatives

**Verification as a trail node after the answer.** Rejected. `isLastStep` currently gates the entire vault-unlock path, and the presenter already carries a subtle correction on top of it (`answerRevealed = state.isLastStep && state.answerRevealed`, so that reveal-then-back does not leak a revealed vault onto an earlier step). Making verification the last node redefines `isLastStep` and puts that logic at risk for no pedagogical gain — the check does not need to be navigated to, it needs to arrive with the answer.

**Approach as a disclosure on step 1.** Rejected. It needs its own visibility state regardless, so it does not actually save a bloc change. It would sit on the same card as the "Why this works" disclosure and teach two competing disclosure affordances in one place. And a 1064-character block collapsed above step 1 buries the step it is supposed to introduce.

**Approach as a node, verification with the answer.** Chosen. Each piece lands where it is pedagogically right, and the delicate vault logic is not touched.

## State model

One field is added to `SolutionReaderReady`:

```dart
final bool onBriefing;
```

The critical property: **`stepIndex` keeps meaning "index into `document.steps`", so `isLastStep` is unchanged and the vault logic is untouched.** The briefing is a mode, not an index.

`hasBriefing` is derived from the document, never stored:

```dart
bool get hasBriefing => document.approach.body.isNotEmpty;
```

`note` is added to `SolutionReaderReady` as a plain `String` (default `''`).

### Transitions

| Event | Condition | Result |
|---|---|---|
| `SolutionReaderStarted` | `approach.body` non-empty | `onBriefing: true`, `stepIndex: 0` |
| `SolutionReaderStarted` | `approach.body` empty | `onBriefing: false` — behaviour identical to today |
| `SolutionReaderAdvanced` | `onBriefing` | `onBriefing: false`, `stepIndex` unchanged |
| `SolutionReaderAdvanced` | `!onBriefing && !isLastStep` | `stepIndex + 1` |
| `SolutionReaderWentBack` | `!onBriefing && stepIndex == 0 && hasBriefing` | `onBriefing: true` |
| `SolutionReaderWentBack` | `!onBriefing && stepIndex > 0` | `stepIndex - 1` |
| `SolutionReaderWentBack` | `onBriefing` | no-op |
| `SolutionReaderRationaleToggled` | `onBriefing` | no-op |
| `SolutionReaderAnswerRevealed` | `onBriefing` | no-op |

### Two guards that are easy to get wrong

Both are consequences of `isLastStep` being computed from `stepIndex` while the briefing sits at `stepIndex == 0`. In a **single-step document with a briefing**, `isLastStep` is already true while the student is still on the briefing.

1. `_onAdvanced` currently returns early when `isLastStep`. Without a briefing check *first*, "Start solving" would do nothing and the reader would be stuck on the briefing forever.
2. `_onAnswerRevealed` currently requires `isLastStep`. Without a `!onBriefing` check, the answer could be revealed from the briefing screen, before a single step is read.

Both get a dedicated test using a one-step document, because a three-step document does not expose either bug.

## Components

Dependencies point strictly downward, and nothing below the page sees bloc state.

### New

- **`organisms/solution_briefing_organism.dart`** — `SolutionBriefingOrganism({required SolutionBriefingParams params})`. Renders a "The plan" heading, the `approach` segments through the existing `SegmentListMolecule`, and the note caveat when present. Key: `Key('solution_briefing')`.
- **`params/solution_briefing_params.dart`** — plain holder, **not `Equatable`** (carries callbacks).
- **`organisms/solution_check_organism.dart`** — `SolutionCheckOrganism({required List<OrderedSegment> body, required void Function(VisualSolutionSegment) onEnlargeVisual, DiagramImageProviderBuilder imageProviderBuilder})`. A "Check it" heading plus the `verification` segments. Renders nothing when `body` is empty. Key: `Key('solution_check')`.
- **`molecules/note_caveat_molecule.dart`** — a single-line caveat with an info icon. Key: `Key('solution_note')`.

**Why `SolutionCheckOrganism` is a sibling of the vault, not part of it.** The vault is a high-contrast `tertiaryContainer` panel whose job is to make one short answer land. `verification` is 650+ characters plus a math block. Putting it inside would turn the payoff into a wall. Below it, at normal surface contrast, the answer stays punchy and the check reads calmly.

### Modified

- **`molecules/solution_trail_molecule.dart`** — `SolutionTrailNode` gains `final IconData? icon`. When `icon` is non-null and the node is not `done`, `_TrailNode` renders the icon instead of `displayNumber`. A `done` node still renders the tick, so the briefing behaves like every other completed node once passed.
- **`bloc/solution_reader_state.dart`** — `onBriefing`, `note`, `hasBriefing`, extended `copyWith`, extended `props`.
- **`bloc/solution_reader_event.dart`** — `SolutionReaderStarted` gains `String note` (default `''`).
- **`bloc/solution_reader_bloc.dart`** — briefing transitions and the two guards above; `_onStarted` passes `outcome.note` through on the sample path.
- **`bloc/ask_by_photo_state.dart`** — `AskByPhotoSolved` gains `final String note` (default `''`) so the solve path does not drop it.
- **`bloc/ask_by_photo_bloc.dart`** — pass `outcome.note` when constructing `AskByPhotoSolved`.
- **`mapper/solution_reader_presenter.dart`** — briefing content, the head trail node, briefing-aware CTA and back affordances, check content.
- **`templates/solution_reader_template.dart`** — render the briefing organism instead of the step organism + vault when on the briefing; render the check organism below the vault when revealed.
- **`pages/question_solution_page.dart`** — pass `solvedState?.note` into `SolutionReaderStarted`.

## Presenter contract

`SolutionReaderContent` gains:

```dart
final bool onBriefing;
final List<OrderedSegment> briefingBody;
final String briefingTitle;      // 'The plan'
final String note;               // '' when absent
final List<OrderedSegment> checkBody;
final String checkTitle;         // 'Check it'
```

Copy rules, all of which follow the existing "progress is encoded exactly once" constraint:

- CTA on the briefing: **"Start solving"**.
- CTA elsewhere: unchanged — "Next step", then "Reveal answer", then "Solved".
- `canGoBack` is `false` on the briefing, and `true` on step 1 when a briefing exists.
- The briefing contributes a trail node with `icon: Icons.flag_outlined` and `semanticsLabel: 'The plan'`. Step nodes keep their existing 1-based `displayNumber`, so **step numbering does not shift** — step 1 is still node "1".
- No string introduced by this design contains a count, a total, or " of ".

## Degradation

Every field is optional in the entity and optional in real payloads. Each absence is a silent, total absence — never an empty heading or a reserved gap.

| Absent | Result |
|---|---|
| `approach.body` empty | No briefing screen, no head trail node, `onBriefing` never true. Reader behaves exactly as it does today. |
| `verification.body` empty | No check section. The vault is the last thing on the page. |
| `note` empty | No caveat line on the briefing. |
| `approach` empty but `note` present | No briefing screen, so the note has nowhere to go and is not shown. Accepted: the note is a caveat *about the approach*, and the solver always sends them together. |

## Testing

Behavioural, at the seam that owns each rule.

**Bloc** (`solution_reader_bloc_test.dart`)
- Opens on the briefing when `approach` is non-empty; opens on step 1 when it is empty.
- "Start solving" leaves the briefing without changing `stepIndex`.
- Back from step 1 returns to the briefing; back on the briefing is a no-op.
- **One-step document + briefing:** advancing off the briefing works (guard 1).
- **One-step document + briefing:** `SolutionReaderAnswerRevealed` is a no-op while on the briefing (guard 2).
- Rationale toggle is a no-op on the briefing.
- `note` survives both entry paths.

**Presenter** (`solution_reader_presenter_test.dart`)
- Briefing CTA reads "Start solving"; `canGoBack` is false there and true on step 1.
- The trail's head node carries the flag icon; step nodes keep 1-based numbering.
- `checkBody` is empty until revealed and populated after.
- No emitted string contains " of ".

**Organisms**
- Briefing renders the approach segments and the note; hides the note when empty.
- Check renders nothing for an empty body, and its heading plus segments otherwise.

**Template**
- On the briefing: the briefing organism is shown and the step card and vault are not.
- After reveal with verification present: the check organism sits below the vault.

**Regression guard:** the existing `AskByPhotoSolved` equality tests must keep passing with the added field defaulting to `''`.

## Risks

- **`AskByPhotoSolved` gains a field** and it participates in `props`. Any test constructing it positionally or asserting exact equality could break. The field defaults to `''`, so equality is preserved for every existing construction.
- **The briefing shifts what "first screen" means.** The reader's opening frame changes for every solved question that has an `approach`. This is the intended product change, but it is the one user-visible behaviour change here rather than an addition.
- **`approach` quality is upstream.** Shipping this makes the solver's telemetry-flavoured prose visible to students. That is a deliberate, agreed trade: it is the only way the content problem becomes visible enough to fix.
