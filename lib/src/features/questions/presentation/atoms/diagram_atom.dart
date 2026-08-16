import 'dart:async';
import 'dart:math';

import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/idle_beat_atom.dart';
import 'package:flutter/material.dart';

typedef DiagramImageProviderBuilder = ImageProvider Function(String url);

ImageProvider networkDiagramImageProvider(String url) => NetworkImage(url);

/// One payload diagram, tone-corrected for the dark page.
class DiagramAtom extends StatefulWidget {
  /// `invert(1)` composed with `hue-rotate(180deg)`.
  ///
  /// The payload's PNGs are transparent line art authored for a light page.
  /// Unfiltered, the `#222222` rectangle sits at 1.09:1 against the dark
  /// surface — invisible. Inverting alone reaches 12:1 but turns the blue road
  /// edges orange and the purple label green, breaking the colour coding that
  /// ties each measurement label to its edge. The hue rotation puts the hues
  /// back, so only lightness flips.
  static const ColorFilter inkFilter = ColorFilter.matrix(<double>[
    0.574, -1.43, -0.144, 0.0, 255.0, //
    -0.426, -0.43, -0.144, 0.0, 255.0, //
    -0.426, -1.43, 0.856, 0.0, 255.0, //
    0.0, 0.0, 0.0, 1.0, 0.0, //
  ]);

  /// A diagram is the one part of a step that cannot be read around, and the
  /// payload's URLs are SAS-signed and travel over whatever connection the
  /// student happens to have. One dropped request should not cost them the
  /// figure, so the load is attempted three times before the figure gives up.
  static const int maxAttempts = 3;

  static const Duration retryBackoff = Duration(milliseconds: 600);

  final String url;
  final double aspectRatio;
  final String semanticsLabel;
  final VoidCallback onFailed;
  final DiagramImageProviderBuilder imageProviderBuilder;

  const DiagramAtom({
    super.key,
    required this.url,
    required this.aspectRatio,
    required this.semanticsLabel,
    required this.onFailed,
    this.imageProviderBuilder = networkDiagramImageProvider,
  });

  @override
  State<DiagramAtom> createState() => _DiagramAtomState();
}

class _DiagramAtomState extends State<DiagramAtom> {
  int _attempt = 0;
  Timer? _retry;

  @override
  void dispose() {
    _retry?.cancel();
    super.dispose();
  }

  void _onError() {
    if (_attempt >= DiagramAtom.maxAttempts - 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onFailed();
      });
      return;
    }
    if (_retry?.isActive ?? false) return;
    // Retrying instantly just re-runs the same request against the same dead
    // moment. The pause gives the connection time to come back.
    _retry = Timer(DiagramAtom.retryBackoff, () {
      if (mounted) setState(() => _attempt++);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.imageProviderBuilder(widget.url);
    // The cache keys a failed load by provider, so an identical provider would
    // be handed the same failure again without ever reaching the network.
    if (_attempt > 0) {
      provider.evict();
    }

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: ColorFiltered(
        colorFilter: DiagramAtom.inkFilter,
        child: Image(
          key: ValueKey<int>(_attempt),
          image: provider,
          fit: BoxFit.contain,
          semanticLabel: widget.semanticsLabel,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (frame != null || wasSynchronouslyLoaded) return child;
            return const Center(child: _DiagramSpinner());
          },
          errorBuilder: (context, error, stackTrace) {
            _onError();
            return const Center(child: _DiagramSpinner());
          },
        ),
      ),
    );
  }
}

/// Turns while the figure is on its way.
///
/// It is bounded, like every other loop on this page: an endless spinner makes
/// `pumpAndSettle` hang in any test that renders a loading diagram. Ten turns
/// is far longer than a diagram that is going to arrive needs, and one that
/// has not arrived by then is the retry's problem, not the spinner's.
class _DiagramSpinner extends StatelessWidget {
  const _DiagramSpinner();

  @override
  Widget build(BuildContext context) {
    return IdleBeatAtom(
      key: const Key('diagram_spinner'),
      period: const Duration(milliseconds: 800),
      beats: 10,
      builder: (context, phase, child) {
        return Transform.rotate(angle: phase * 2 * pi, child: child);
      },
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CustomPaint(painter: _SpinnerRingPainter()),
      ),
    );
  }
}

class _SpinnerRingPainter extends CustomPainter {
  const _SpinnerRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 2.5;
    final rect = Offset.zero & size;
    final ring = rect.deflate(stroke / 2);

    canvas.drawArc(
      ring,
      0,
      2 * pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = QuestPalette.cream.withValues(alpha: 0.18),
    );
    // A quarter of bright rim is what makes the turn legible; a whole bright
    // ring rotating looks like nothing is happening at all.
    canvas.drawArc(
      ring,
      -pi / 2,
      pi / 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = QuestPalette.pink,
    );
  }

  @override
  bool shouldRepaint(_SpinnerRingPainter oldDelegate) => false;
}
