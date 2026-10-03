import 'dart:convert';
import 'dart:typed_data';

import 'package:doormer/src/features/questions/utils/image_readability.dart';
import 'package:flutter_test/flutter_test.dart';

// 1x1 transparent PNG.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
  'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  testWidgets('a real PNG is readable', (tester) async {
    final ok = await tester.runAsync(() => isReadableImage(_png));
    expect(ok, isTrue);
  });

  testWidgets('random bytes are not', (tester) async {
    final ok = await tester.runAsync(
        () => isReadableImage(Uint8List.fromList(List.filled(64, 7))));
    expect(ok, isFalse);
  });

  test('a decoder that throws means unreadable', () async {
    expect(
      await isReadableImage(Uint8List(4),
          decode: (_) async => throw Exception('codec')),
      isFalse,
    );
  });

  test('the message is friendly', () {
    expect(
        unreadableImageMessage, "We can't read this file. Try a JPG or PNG.");
  });
}
