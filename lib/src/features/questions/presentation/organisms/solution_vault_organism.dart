import 'dart:math' as math;

import 'package:doormer/src/core/motion/motion_policy.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/atoms/confetti_atom.dart';
import 'package:doormer/src/features/questions/presentation/atoms/diagram_atom.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_segment_order.dart';
import 'package:doormer/src/features/questions/presentation/organisms/segment_list_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solution_check_organism.dart';
import 'package:doormer/src/shared/design/atomic/atoms/dashed_border_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/idle_beat_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The final-answer vault. A one-line strip while locked so it does not squat
/// at full size, an unlockable panel on the last step, then the answer itself.
///
/// The border style carries the state, not just its colour: the vault is drawn
/// with a broken edge while it is shut and openable, and only becomes solid
/// once the answer is out. A solid edge would say the answer is already yours.
class SolutionVaultOrganism extends StatefulWidget {
  final bool revealed;
  final bool unlockable;

  /// True while the lock is refusing to give. The vault does not decide how
  /// long that lasts — the page does, so everything turns over together.
  final bool resisting;
  final String lockedLabel;

  /// What the student is told they just did, once it is open.
  final String solvedLabel;
  final String checkTitle;
  final List<OrderedSegment> checkBody;
  final List<OrderedSegment> answerBody;
  final VoidCallback onReveal;
  final void Function(VisualSolutionSegment visual) onEnlargeVisual;
  final DiagramImageProviderBuilder imageProviderBuilder;

  const SolutionVaultOrganism({
    super.key,
    required this.revealed,
    required this.unlockable,
    this.resisting = false,
    required this.lockedLabel,
    required this.solvedLabel,
    required this.checkTitle,
    required this.checkBody,
    required this.answerBody,
    required this.onReveal,
    required this.onEnlargeVisual,
    this.imageProviderBuilder = networkDiagramImageProvider,
  });

  @override
  State<SolutionVaultOrganism> createState() => _SolutionVaultOrganismState();
}

class _SolutionVaultOrganismState extends State<SolutionVaultOrganism>
    with TickerProviderStateMixin {
  /// Three beats, then quiet. A ring that pulses forever stops being a
  /// prompt and becomes a fixture the eye edits out.
  static const int _ringBeats = 3;
  static const Duration _ringBeat = Duration(milliseconds: 1600);

  late final AnimationController _shake;
  late final AnimationController _burst;
  late final AnimationController _ready;
  late final AnimationController _ring;

  /// What the vault is *showing*, which trails [SolutionVaultOrganism.revealed]
  /// for as long as the lock is resisting.
  bool _open = false;
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    // Built here, not as field initialisers: a vault that is already open when
    // it mounts never touches the shake controller, and a lazily-created
    // controller would first come into being inside dispose().
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _ready = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _ring = AnimationController(
      vsync: this,
      duration: _ringBeat * _ringBeats,
    );
    // Arriving at an already-open vault is not an unlock. A student who taps
    // back and returns should not be congratulated twice.
    _open = widget.revealed;
  }

  @override
  void didUpdateWidget(SolutionVaultOrganism oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.unlockable && !oldWidget.unlockable) _announceReady();
    if (widget.resisting && !oldWidget.resisting) _shake.forward(from: 0);
    if (widget.revealed == _open) return;
    if (!widget.revealed) {
      _shake.stop();
      _burst.stop();
      setState(() {
        _open = false;
        _celebrating = false;
      });
      return;
    }
    setState(() {
      _open = true;
      _celebrating = MotionPolicy.of(context);
    });
    if (_celebrating) _burst.forward(from: 0);
  }

  /// The moment the vault becomes openable it says so once, out loud, then
  /// stops. It is an invitation, not an alarm.
  void _announceReady() {
    if (!MotionPolicy.of(context)) return;
    _ready.forward(from: 0);
    _ring.forward(from: 0);
  }

  @override
  void dispose() {
    _shake.dispose();
    _burst.dispose();
    _ready.dispose();
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_open) {
      return _burstIn(_revealedVault());
    }

    return _shakeOut(_readyIn(_shutVault()));
  }

  /// Scale out past the mark and settle back. A vault that simply appears at
  /// its final size reads as a panel that was always there; overshooting reads
  /// as something that just gave way.
  Widget _burstIn(Widget child) {
    return AnimatedBuilder(
      animation: _burst,
      builder: (context, child) {
        final v = _burst.value;
        final scale = v == 0 || v == 1
            ? 1.0
            : v < 0.55
                ? 0.9 + 0.14 * (v / 0.55)
                : 1.04 - 0.04 * ((v - 0.55) / 0.45);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Transform.scale(scale: scale, child: child),
            if (_celebrating)
              const Positioned.fill(
                child: ConfettiAtom(key: Key('vault_confetti')),
              ),
          ],
        );
      },
      child: child,
    );
  }

  /// The vault noticing it can now be opened: one bounce, and an amber ring
  /// that breathes out three times and then leaves the student alone.
  Widget _readyIn(Widget child) {
    return AnimatedBuilder(
      animation: Listenable.merge([_ready, _ring]),
      builder: (context, child) {
        final r = _ready.value;
        final scale = r == 0 || r == 1
            ? 1.0
            : r < 0.35
                ? 1 + 0.035 * (r / 0.35)
                : 1.035 - 0.035 * ((r - 0.35) / 0.65);
        final ring = _ring.value;
        // Each beat is its own 0..1 sweep, so three beats need one controller.
        final beat = ring == 0 || ring == 1 ? 0.0 : (ring * _ringBeats) % 1;
        // Ease out to the widest, faintest point: the ring leaves, it does
        // not merely fade in place.
        final spread = Curves.easeOut.transform(beat);
        return Transform.scale(
          scale: scale,
          child: Stack(
            children: [
              if (beat > 0)
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12.h),
                    child: IgnorePointer(
                      child: DecoratedBox(
                        key: const Key('vault_ready_ring'),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [
                            BoxShadow(
                              color: QuestPalette.amber
                                  .withValues(alpha: 0.5 * (1 - spread)),
                              spreadRadius: 8 * spread,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              child!,
            ],
          ),
        );
      },
      child: child,
    );
  }

  /// The lock refusing. Sideways only: a vault that jumps looks broken, one
  /// that rattles looks held shut.
  Widget _shakeOut(Widget child) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final v = _shake.value;
        if (v == 0 || v == 1) return child!;
        // Hard at the middle, soft at the ends, so it starts and stops on the
        // spot the vault actually occupies.
        final envelope = math.sin(v * math.pi);
        final offset = math.sin(v * math.pi * 6) * 8 * envelope;
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: child,
    );
  }

  Widget _revealedVault() {
    return Container(
      key: const Key('vault_revealed'),
      width: double.infinity,
      margin: EdgeInsets.only(top: 12.h),
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: QuestPalette.mint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: QuestPalette.mint, width: 2),
        boxShadow: [
          BoxShadow(
            color: QuestPalette.mint.withValues(alpha: 0.22),
            blurRadius: 26,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_open_rounded,
                  size: 15.sp, color: QuestPalette.mint),
              SizedBox(width: 6.w),
              Text(
                'CRACKED IT',
                style: TextStyle(
                  fontSize: 10.sp,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w700,
                  color: QuestPalette.mint,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            widget.solvedLabel,
            key: const Key('vault_solved_label'),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: QuestPalette.dim,
            ),
          ),
          SizedBox(height: 6.h),
          SegmentListOrganism(
            segments: widget.answerBody,
            onEnlargeVisual: widget.onEnlargeVisual,
            imageProviderBuilder: widget.imageProviderBuilder,
            emphasised: true,
          ),
          SolutionCheckOrganism(
            title: widget.checkTitle,
            body: widget.checkBody,
            onEnlargeVisual: widget.onEnlargeVisual,
            imageProviderBuilder: widget.imageProviderBuilder,
          ),
        ],
      ),
    );
  }

  Widget _shutVault() {
    return GestureDetector(
      key: const Key('vault_locked'),
      onTap: widget.unlockable ? widget.onReveal : null,
      child: Padding(
        padding: EdgeInsets.only(top: 12.h),
        child: _shutFrame(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 11.h),
            decoration: BoxDecoration(
              color: widget.unlockable
                  ? QuestPalette.amber.withValues(alpha: 0.14)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14.r),
              // The openable state draws its edge with DashedBorderAtom.
              border: widget.unlockable
                  ? null
                  : Border.all(color: Colors.white.withValues(alpha: 0.16)),
              boxShadow: widget.unlockable
                  ? [
                      BoxShadow(
                        color: QuestPalette.amber.withValues(alpha: 0.24),
                        blurRadius: 20,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                IdleBeatAtom(
                  period: const Duration(milliseconds: 2400),
                  beats: 4,
                  child: Icon(
                    widget.unlockable
                        ? Icons.lock_open_rounded
                        : Icons.lock_rounded,
                    size: 15.sp,
                    color: widget.unlockable
                        ? QuestPalette.amber
                        : QuestPalette.dim,
                  ),
                  builder: (context, phase, child) {
                    // The lock strains upward against what is holding it.
                    final lift = (1 - math.cos(phase * 2 * math.pi)) / 2;
                    return Transform.translate(
                      offset: Offset(0, -4 * lift),
                      child: child,
                    );
                  },
                ),
                SizedBox(width: 9.w),
                Expanded(
                  child: Text(
                    widget.lockedLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: kDisplayFont,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: widget.unlockable
                          ? QuestPalette.amber
                          : QuestPalette.dim,
                    ),
                  ),
                ),
                if (widget.unlockable)
                  Icon(Icons.chevron_right_rounded,
                      size: 17.sp, color: QuestPalette.amber),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Draws the broken edge on a vault that is shut but openable. A vault that
  /// is not yet relevant keeps a plain thin edge so it recedes instead.
  Widget _shutFrame({required Widget child}) {
    if (!widget.unlockable) return child;
    return DashedBorderAtom(
      color: QuestPalette.amber,
      radius: 14.r,
      child: child,
    );
  }
}
