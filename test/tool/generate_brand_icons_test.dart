import 'package:flutter_test/flutter_test.dart';

import '../../tool/generate_brand_icons.dart' show isSelected;

void main() {
  test('with no paths named, makes every file', () {
    expect(isSelected('web/favicon.png', const []), isTrue);
    expect(
        isSelected('assets/images/brand/doormer_icon.png', const []), isTrue);
  });

  test('with paths named, makes only the files whose paths start with one', () {
    const brand = ['assets/images/brand'];

    expect(isSelected('assets/images/brand/doormer_icon.png', brand), isTrue);
    expect(
        isSelected('assets/images/brand/3.0x/doormer_icon.png', brand), isTrue);
    expect(isSelected('web/icons/Icon-192.png', brand), isFalse);
    expect(
      isSelected('web/icons/Icon-192.png', const ['assets/', 'web/icons/']),
      isTrue,
    );
  });
}
