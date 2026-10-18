// Regenerates every exported icon from the two master Doormer icons in
// web/site/img/brand/, so the website, the web app and the native apps all
// show the same artwork:
//
// - doormer-icon.svg, the full icon, for app icons.
// - doormer-favicon.svg, the "d" from the wordmark, for browser tabs and the
//   Windows title bar and taskbar. They show icons at 32 px or smaller, where
//   the full icon's path, levels and door blur together.
//
// It renders with headless Chrome. Set CHROME to use a different
// Chromium-based browser. Run it from the repository root whenever a master
// icon changes:
//
//   dart run tool/generate_brand_icons.dart
import 'dart:io';
import 'dart:typed_data';

const masterIconPath = 'web/site/img/brand/doormer-icon.svg';
const faviconPath = 'web/site/img/brand/doormer-favicon.svg';

/// The master is 120 × 120. Its artwork (everything except the background)
/// spans x 16–104 and y 10–112.
const artworkCentreX = 60.0;
const artworkCentreY = 61.0;
const artworkDiagonal = 134.7;

/// The ways the master icon is shaped for different platforms.
enum IconShape {
  /// The master as drawn: rounded corners, transparent outside them.
  roundedTile,

  /// Background to the edges and no transparency; the device rounds it.
  square,

  /// Square background with the artwork inside the central 80% circle that
  /// browsers keep when they crop an installed web app's icon.
  maskable,

  /// The artwork alone on a transparent canvas, inside the central 66 dp of
  /// Android's 108 dp adaptive icon. The background is a separate layer.
  androidForeground,

  /// The rounded tile at 824/1024 of the canvas, Mac's standard icon margin.
  mac,
}

/// Which master icon an exported icon is drawn from.
enum IconArt {
  /// The full icon: the path, the levels and the door.
  full,

  /// The "d" from the wordmark, already drawn as a rounded tile.
  favicon,
}

class IconFile {
  const IconFile(this.path, this.size, this.shape, {this.art = IconArt.full});

  final String path;
  final int size;
  final IconShape shape;
  final IconArt art;
}

const iosFolder = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
const macFolder = 'macos/Runner/Assets.xcassets/AppIcon.appiconset';
const androidFolder = 'android/app/src/main/res';

const androidDensities = {
  'mdpi': 1.0,
  'hdpi': 1.5,
  'xhdpi': 2.0,
  'xxhdpi': 3.0,
  'xxxhdpi': 4.0,
};

final iconFiles = <IconFile>[
  const IconFile('web/site/img/apple-touch-icon.png', 180, IconShape.square),
  const IconFile('web/favicon.png', 32, IconShape.roundedTile,
      art: IconArt.favicon),
  const IconFile('web/icons/Icon-192.png', 192, IconShape.roundedTile),
  const IconFile('web/icons/Icon-512.png', 512, IconShape.roundedTile),
  const IconFile('web/icons/Icon-maskable-192.png', 192, IconShape.maskable),
  const IconFile('web/icons/Icon-maskable-512.png', 512, IconShape.maskable),
  for (final MapEntry(key: density, value: scale)
      in androidDensities.entries) ...[
    IconFile('$androidFolder/mipmap-$density/ic_launcher.png',
        (48 * scale).round(), IconShape.roundedTile),
    IconFile('$androidFolder/mipmap-$density/ic_launcher_foreground.png',
        (108 * scale).round(), IconShape.androidForeground),
  ],
  for (final (name, size) in const [
    ('20x20@1x', 20),
    ('20x20@2x', 40),
    ('20x20@3x', 60),
    ('29x29@1x', 29),
    ('29x29@2x', 58),
    ('29x29@3x', 87),
    ('40x40@1x', 40),
    ('40x40@2x', 80),
    ('40x40@3x', 120),
    ('60x60@2x', 120),
    ('60x60@3x', 180),
    ('76x76@1x', 76),
    ('76x76@2x', 152),
    ('83.5x83.5@2x', 167),
    ('1024x1024@1x', 1024),
  ])
    IconFile('$iosFolder/Icon-App-$name.png', size, IconShape.square),
  for (final size in const [16, 32, 64, 128, 256, 512, 1024])
    IconFile('$macFolder/app_icon_$size.png', size, IconShape.mac),
  const IconFile(
      'linux/runner/resources/app_icon.png', 256, IconShape.roundedTile),
];

const windowsIconPath = 'windows/runner/resources/app_icon.ico';
const windowsIconSizes = [16, 24, 32, 48, 64, 128, 256];

/// Windows shows its 32 px and smaller icons in the title bar and taskbar.
IconArt windowsArt(int size) => size <= 32 ? IconArt.favicon : IconArt.full;

Future<void> main() async {
  final chrome = findChrome();
  final fullIcon = File(masterIconPath).readAsStringSync();
  final favicon = File(faviconPath).readAsStringSync();
  String masterFor(IconArt art) => switch (art) {
        IconArt.full => fullIcon,
        IconArt.favicon => favicon,
      };

  for (final file in iconFiles) {
    await renderPng(chrome, shapeIcon(masterFor(file.art), file.shape),
        file.size, File(file.path),
        transparent: hasTransparency(file.shape));
    stdout.writeln('${file.path} (${file.size} px)');
  }

  final windowsImages = <Uint8List>[];
  final scratch = await Directory.systemTemp.createTemp('doormer-ico-');
  try {
    for (final size in windowsIconSizes) {
      final png = File('${scratch.path}/$size.png');
      await renderPng(chrome, masterFor(windowsArt(size)), size, png,
          transparent: true);
      windowsImages.add(png.readAsBytesSync());
    }
  } finally {
    scratch.deleteSync(recursive: true);
  }
  File(windowsIconPath)
      .writeAsBytesSync(buildIco(windowsIconSizes, windowsImages));
  stdout.writeln('$windowsIconPath (${windowsIconSizes.join(', ')} px)');
}

bool hasTransparency(IconShape shape) => switch (shape) {
      IconShape.square || IconShape.maskable => false,
      IconShape.roundedTile ||
      IconShape.androidForeground ||
      IconShape.mac =>
        true,
    };

String shapeIcon(String master, IconShape shape) => switch (shape) {
      IconShape.roundedTile => master,
      IconShape.square => squareCorners(master),
      IconShape.maskable => fitArtwork(squareCorners(master), 120 * 0.8),
      IconShape.androidForeground =>
        fitArtwork(withoutBackground(master), 120 * 66 / 108),
      IconShape.mac => shrinkWhole(master, 824 / 1024),
    };

final backgroundRect = RegExp(r'<rect id="background"[^>]*/>');

String squareCorners(String svg) => svg.replaceFirstMapped(backgroundRect,
    (match) => match[0]!.replaceFirst(RegExp(r' rx="[^"]*"'), ''));

String withoutBackground(String svg) => svg.replaceFirst(backgroundRect, '');

/// Scales the artwork so its bounding box fits inside a centred circle.
String fitArtwork(String svg, double circleDiameter) {
  const artworkGroup = '<g id="artwork">';
  if (!svg.contains(artworkGroup)) {
    throw StateError('$masterIconPath needs a <g id="artwork"> group');
  }
  final scale = (circleDiameter / artworkDiagonal).toStringAsFixed(4);
  return svg.replaceFirst(
      artworkGroup,
      '<g id="artwork" transform="translate(60 60) scale($scale) '
      'translate(-$artworkCentreX -$artworkCentreY)">');
}

/// Shrinks the whole icon, background included, around its centre.
String shrinkWhole(String svg, double fraction) {
  final start = svg.indexOf('>', svg.indexOf('<svg')) + 1;
  final end = svg.lastIndexOf('</svg>');
  final margin = (120 * (1 - fraction) / 2).toStringAsFixed(3);
  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120">'
      '<g transform="translate($margin $margin) scale(${fraction.toStringAsFixed(5)})">'
      '${svg.substring(start, end)}</g></svg>';
}

String findChrome() {
  final candidates = [
    if (Platform.environment['CHROME'] case final chrome?) chrome,
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/Applications/Chromium.app/Contents/MacOS/Chromium',
    '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge',
    '/usr/bin/google-chrome',
    '/usr/bin/chromium',
    '/usr/bin/chromium-browser',
  ];
  for (final candidate in candidates) {
    if (File(candidate).existsSync()) return candidate;
  }
  stderr.writeln('Chrome not found. Set CHROME to a Chromium-based browser.');
  exit(1);
}

/// Renders [svg] to a [size] × [size] PNG. Opaque renders have no alpha
/// channel, which the App Store requires for iPhone icons.
Future<void> renderPng(String chrome, String svg, int size, File output,
    {required bool transparent}) async {
  final scratch = await Directory.systemTemp.createTemp('doormer-render-');
  try {
    File('${scratch.path}/icon.svg').writeAsStringSync(svg);
    final page = File('${scratch.path}/page.html')
      ..writeAsStringSync('<!doctype html><html><head><style>'
          'html,body{margin:0;background:transparent}'
          'img{display:block;width:${size}px;height:${size}px}'
          '</style></head><body><img src="icon.svg"></body></html>');
    output.parent.createSync(recursive: true);
    final result = await Process.run(chrome, [
      '--headless=new',
      '--disable-gpu',
      '--hide-scrollbars',
      '--no-first-run',
      '--no-default-browser-check',
      '--user-data-dir=${scratch.path}/profile',
      '--force-device-scale-factor=1',
      if (transparent) '--default-background-color=00000000',
      '--window-size=$size,$size',
      '--screenshot=${output.absolute.path}',
      page.uri.toString(),
    ]);
    if (result.exitCode != 0 || !output.existsSync()) {
      throw ProcessException(chrome, const [],
          'Could not render ${output.path}: ${result.stderr}', result.exitCode);
    }
  } finally {
    scratch.deleteSync(recursive: true);
  }
}

/// Packs PNG images into a Windows .ico file.
Uint8List buildIco(List<int> sizes, List<Uint8List> pngs) {
  const headerBytes = 6;
  const entryBytes = 16;
  final header = BytesBuilder()
    ..add(_uint16(0))
    ..add(_uint16(1))
    ..add(_uint16(pngs.length));
  final images = BytesBuilder();
  var offset = headerBytes + entryBytes * pngs.length;
  for (var i = 0; i < pngs.length; i++) {
    final side = sizes[i] >= 256 ? 0 : sizes[i];
    header
      ..addByte(side)
      ..addByte(side)
      ..addByte(0)
      ..addByte(0)
      ..add(_uint16(1))
      ..add(_uint16(32))
      ..add(_uint32(pngs[i].length))
      ..add(_uint32(offset));
    images.add(pngs[i]);
    offset += pngs[i].length;
  }
  return (header..add(images.takeBytes())).takeBytes();
}

Uint8List _uint16(int value) =>
    (ByteData(2)..setUint16(0, value, Endian.little)).buffer.asUint8List();

Uint8List _uint32(int value) =>
    (ByteData(4)..setUint32(0, value, Endian.little)).buffer.asUint8List();
