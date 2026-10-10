// Tags each site page's links to the website's stylesheet and scripts with a
// version, for example /site/css/site.css?h=3f2a9c1b07. The tag is the start of
// the file's SHA-256, so it changes whenever the file does and a browser never
// pairs a page with an old copy of the file it saved earlier.
//
// Run from the project root after changing anything in web/site/css or
// web/site/js:
//
//   dart run tool/stamp_site_assets.dart
import 'dart:io';

import 'package:crypto/crypto.dart';

final siteAssetLink =
    RegExp(r'(/site/(?:css|js)/[\w.-]+\.(?:css|js))(?:\?h=[0-9a-f]*)?');

String versionTagOf(String path) => sha256
    .convert(File('web$path').readAsBytesSync())
    .toString()
    .substring(0, 10);

void main() {
  final pages = Directory('web/site/pages')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.html'));
  for (final page in pages) {
    final html = page.readAsStringSync();
    final tagged = html.replaceAllMapped(siteAssetLink, (match) {
      final path = match[1]!;
      return '$path?h=${versionTagOf(path)}';
    });
    if (tagged != html) {
      page.writeAsStringSync(tagged);
      stdout.writeln('Updated ${page.path}');
    }
  }
}
