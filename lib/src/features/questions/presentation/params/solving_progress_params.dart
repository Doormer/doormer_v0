import 'package:flutter/foundation.dart';

/// What the progress card shows while a photo is being solved.
class SolvingProgressParams {
  /// The photo being solved, shown as a thumbnail. Null when there is none.
  final Uint8List? imageBytes;
  final String title;
  final String body;

  const SolvingProgressParams({
    this.imageBytes,
    required this.title,
    required this.body,
  });
}
