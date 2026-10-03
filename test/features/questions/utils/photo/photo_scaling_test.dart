import 'package:doormer/src/features/questions/utils/photo/photo_scaling.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fitWithin', () {
    test('scales a landscape photo so its long edge is 2048', () {
      expect(
          fitWithin(const PhotoSize(4000, 3000)), const PhotoSize(2048, 1536));
    });

    test('scales a portrait photo so its long edge is 2048', () {
      expect(
          fitWithin(const PhotoSize(3000, 4000)), const PhotoSize(1536, 2048));
    });

    test('never enlarges a small photo', () {
      expect(fitWithin(const PhotoSize(1000, 800)), const PhotoSize(1000, 800));
      expect(
          fitWithin(const PhotoSize(2048, 1536)), const PhotoSize(2048, 1536));
    });

    test('keeps at least one pixel on a very thin photo', () {
      expect(fitWithin(const PhotoSize(100000, 10)), const PhotoSize(2048, 1));
    });
  });

  group('scalingSteps', () {
    test('a photo that already fits is drawn once at its own size', () {
      expect(scalingSteps(const PhotoSize(1000, 800)),
          const [PhotoSize(1000, 800)]);
    });

    test('a 12 MP photo goes straight to the target', () {
      expect(scalingSteps(const PhotoSize(4000, 3000)),
          const [PhotoSize(2048, 1536)]);
    });

    test('a 48 MP photo is halved once before the target', () {
      expect(
        scalingSteps(const PhotoSize(8064, 6048)),
        const [PhotoSize(4032, 3024), PhotoSize(2048, 1536)],
      );
    });

    test('halvings too big for a mobile canvas are skipped', () {
      // 8160x6120 is about 50 MP, over the 16.7 MP canvas limit.
      expect(
        scalingSteps(const PhotoSize(16320, 12240)),
        const [PhotoSize(4080, 3060), PhotoSize(2048, 1536)],
      );
    });

    test('a panorama is halved until one more halving would pass the target',
        () {
      expect(
        scalingSteps(const PhotoSize(16000, 2000)),
        const [
          PhotoSize(8000, 1000),
          PhotoSize(4000, 500),
          PhotoSize(2048, 256)
        ],
      );
    });

    test('every list ends at the fitted size', () {
      for (final size in const [
        PhotoSize(4096, 3072),
        PhotoSize(5712, 4284),
        PhotoSize(3024, 4032),
      ]) {
        expect(scalingSteps(size).last, fitWithin(size));
      }
    });
  });
}
