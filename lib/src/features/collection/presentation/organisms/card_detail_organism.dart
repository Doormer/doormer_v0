import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/punch_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entity/card_rarity.dart';
import '../../domain/entity/holding.dart';
import '../atoms/collectible_card_atom.dart';
import '../molecules/shattered_copy_molecule.dart';
import '../params/card_detail_params.dart';

/// One card, with its facts and the option to shatter a copy.
///
/// **Capped at [maxWidth].** A Flutter `Dialog` expands to its child, so without
/// an explicit constraint the card drifts away from its facts on a wide window.
///
/// **Plays each shatter.** The window stays open while copies are shattered.
/// When a rebuild shows the same card with one fewer copy and a higher
/// balance, a copy breaks over the card and its quarks fly out of the window
/// to the page's balance behind it. With motion off, the numbers simply
/// change.
class CardDetailOrganism extends StatefulWidget {
  static const double maxWidth = 520;

  /// Below this the card sits above its facts rather than beside them.
  static const double stackBelowWidth = 420;

  final CardDetailParams params;

  const CardDetailOrganism({super.key, required this.params});

  /// How many are held, and how many of those are special.
  ///
  /// Three cases, because "3 · 3 special" says the same number twice:
  ///
  ///   none special  ->  `3`
  ///   some special  ->  `3 · 1 special`
  ///   all special   ->  `3 special`
  ///
  /// The count is the printing-agnostic total; the special part only appears
  /// when there is something to distinguish, so "Now special" leaves a trace
  /// rather than being announced once and then lost.
  static String heldLabel(Holding holding) {
    final total = holding.totalCopies;
    if (!holding.hasSpecial) return '$total';
    if (holding.specialCopies == total) return '$total special';
    return '$total · ${holding.specialCopies} special';
  }

  @override
  State<CardDetailOrganism> createState() => _CardDetailOrganismState();
}

class _CardDetailOrganismState extends State<CardDetailOrganism>
    with SingleTickerProviderStateMixin {
  /// The layer the shards fly on, over the window's body.
  final _layerKey = GlobalKey();
  final _cardKey = GlobalKey();

  /// Runs each shatter from 0 to 1. The shards, the quark dots and the rising
  /// "+N quarks" all read it, so none of them can drift out of step.
  late final AnimationController _shatter;

  /// The shatter now playing, or null.
  _Shatter? _playing;

  @override
  void initState() {
    super.initState();
    _shatter = AnimationController(
      vsync: this,
      duration: ShatteredCopyMolecule.duration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _playing = null);
        }
      });
  }

  @override
  void didUpdateWidget(CardDetailOrganism oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.params;
    final after = widget.params;
    final shattered = after.holding.card.id == before.holding.card.id &&
        after.holding.totalCopies == before.holding.totalCopies - 1 &&
        after.quarkBalance > before.quarkBalance;
    if (!shattered || !MotionPolicy.of(context)) return;

    final card = after.holding.card;
    _playing = _Shatter(
      quarksGained: after.quarkBalance - before.quarkBalance,
      isSpecial: before.holding.variantToShatter == CardVariant.special,
      shards: ShatteredCopyMolecule.shardsFor(
        card.rarity,
        ShatteredCopyMolecule.seedFor(card.id, after.holding.totalCopies),
      ),
    );
    // Back to the start. A shatter still playing is cut short.
    _shatter.value = 0;
    // Where the card and the page balance's quark dot sit is known after
    // layout.
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  /// Measures where the card and the page balance's quark dot sit, then
  /// plays.
  void _play() {
    final playing = _playing;
    if (!mounted || playing == null) return;
    final layer = _layerKey.currentContext?.findRenderObject();
    final card = _cardKey.currentContext?.findRenderObject();
    final quarkDot =
        widget.params.quarkDotKey.currentContext?.findRenderObject();
    final cardAtom = _cardKey.currentWidget;
    if (layer is! RenderBox ||
        card is! RenderBox ||
        quarkDot is! RenderBox ||
        cardAtom is! CollectibleCardAtom ||
        !layer.hasSize ||
        !card.hasSize ||
        !quarkDot.hasSize) {
      // Nowhere to draw it.
      setState(() => _playing = null);
      return;
    }

    Offset onLayer(RenderBox box, Offset point) =>
        layer.globalToLocal(box.localToGlobal(point));

    setState(() {
      playing.measured = (
        cardRect: Rect.fromPoints(
          onLayer(card, Offset.zero),
          onLayer(card, card.size.bottomRight(Offset.zero)),
        ),
        cardWidth: cardAtom.width,
        quarkDotCentre: onLayer(quarkDot, quarkDot.size.center(Offset.zero)),
      );
    });
    _shatter.forward(from: 0);
  }

  @override
  void dispose() {
    _shatter.dispose();
    super.dispose();
  }

  String _rarityLabel(Rarity rarity) {
    switch (rarity) {
      case Rarity.common:
        return 'Common';
      case Rarity.uncommon:
        return 'Uncommon';
      case Rarity.rare:
        return 'Rare';
    }
  }

  /// Why the last shatter failed, what the next one pays, or why there is
  /// nothing to shatter. Always exactly one line, so the window never changes
  /// height.
  Widget _lineUnderButton({
    required bool canShatter,
    required int shatterQuarks,
  }) {
    final errorMessage = widget.params.errorMessage;
    final (text, colour) = errorMessage != null
        ? (errorMessage, QuestPalette.muted)
        : canShatter
            ? ('+$shatterQuarks quarks', QuestPalette.mint)
            : ("You can't shatter your only copy.", QuestPalette.muted);
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 10.5.sp, color: colour),
    );
  }

  @override
  Widget build(BuildContext context) {
    final params = widget.params;
    final holding = params.holding;
    final card = holding.card;

    // Never shatter the last copy: that would empty the grid slot the
    // student just filled. Any copy beyond the first is fair game, whichever
    // printing it is.
    final canShatter = holding.totalCopies > 1;

    final variant = holding.variantToShatter;
    final shatterQuarks = card.shatterQuarksFor(variant);

    final playing = _playing;
    final measured = playing?.measured;

    return Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: CardDetailOrganism.maxWidth),
        // The shards fly on a layer over the body. It ignores taps and is not
        // clipped, so shards can fly past the window's edge.
        child: Stack(
          key: _layerKey,
          clipBehavior: Clip.none,
          children: [
            Container(
              key: const Key('card-detail-body'),
              padding: EdgeInsets.all(18.w),
              // A surface of its own. Without this the detail had padding but
              // no background, so the grid behind it showed straight through
              // and the two sets of text overlapped.
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: QuestPalette.cream.withValues(alpha: 0.08),
                  width: 1.w,
                ),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [QuestPalette.ink, QuestPalette.night],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      key: const Key('card-detail-close'),
                      onPressed: params.onClose,
                      icon: Icon(Icons.close, size: 18.w),
                      color: QuestPalette.muted,
                      tooltip: 'Close',
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // A phone cannot hold the card beside its facts: inside
                      // a Dialog's insets there is roughly 94px left for a
                      // label and its value, which overflows. The spec calls
                      // for the card above its facts on a narrow screen, and
                      // this is where that lives.
                      final stacked = constraints.maxWidth <
                          CardDetailOrganism.stackBelowWidth;
                      final facts = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            card.description,
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              height: 1.45,
                              color: QuestPalette.cream.withValues(alpha: 0.72),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          _Fact(
                            label: 'Held',
                            value: CardDetailOrganism.heldLabel(holding),
                            punchTrigger: holding.totalCopies,
                          ),
                          _Fact(
                            label: 'Rarity',
                            value: _rarityLabel(card.rarity),
                          ),
                          _Fact(label: 'Size', value: card.scaleLabel),
                          _Fact(label: 'Deck', value: params.deckName),
                          SizedBox(height: 16.h),
                          Center(
                            child: AppButtonAtom(
                              label: 'Shatter one',
                              variant: AppButtonVariant.accent,
                              isLoading: params.isShattering,
                              onPressed: canShatter
                                  ? () => params.onShatter(variant)
                                  : null,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 6.h),
                            child: Center(
                              child: _lineUnderButton(
                                canShatter: canShatter,
                                shatterQuarks: shatterQuarks,
                              ),
                            ),
                          ),
                        ],
                      );

                      if (stacked) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(
                              child: CollectibleCardAtom(
                                key: _cardKey,
                                card: card,
                                width: 158,
                                isSpecial: holding.hasSpecial,
                              ),
                            ),
                            SizedBox(height: 14.h),
                            facts,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CollectibleCardAtom(
                            key: _cardKey,
                            card: card,
                            width: 132,
                            isSpecial: holding.hasSpecial,
                          ),
                          SizedBox(width: 18.w),
                          Expanded(child: facts),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            if (playing != null && measured != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _shatter,
                    builder: (context, _) => ShatteredCopyMolecule(
                      card: card,
                      isSpecial: playing.isSpecial,
                      cardWidth: measured.cardWidth,
                      cardRect: measured.cardRect,
                      quarkDotCentre: measured.quarkDotCentre,
                      shards: playing.shards,
                      quarksGained: playing.quarksGained,
                      progress: _shatter.value,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A shatter the window is playing.
class _Shatter {
  final int quarksGained;

  /// Whether the copy that broke was the special printing.
  final bool isSpecial;

  final List<Shard> shards;

  /// Where the card sits on the layer, the width it is drawn at, and where
  /// the page balance's quark dot sits. Null until the window has laid out
  /// after the answer.
  ({Rect cardRect, double cardWidth, Offset quarkDotCentre})? measured;

  _Shatter({
    required this.quarksGained,
    required this.isSpecial,
    required this.shards,
  });
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;

  /// When set, the value punches whenever this changes.
  final Object? punchTrigger;

  const _Fact({required this.label, required this.value, this.punchTrigger});

  @override
  Widget build(BuildContext context) {
    final valueText = Text(
      value,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
      style: TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        color: QuestPalette.cream,
      ),
    );
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.sp, color: QuestPalette.dim),
            ),
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: punchTrigger == null
                ? valueText
                : PunchAtom(trigger: punchTrigger, child: valueText),
          ),
        ],
      ),
    );
  }
}
