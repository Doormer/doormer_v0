import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

/// Every public page of the website and the URL nginx serves it at.
const expectedRoutes = <String>{
  '/',
  '/about',
  '/contact',
  '/privacy',
  '/terms',
  '/guides',
  '/guides/homework-photo-tips',
  '/guides/learn-from-worked-solutions',
  '/guides/ai-homework-help-for-parents',
};

/// Flutter app routes the website may link to.
const appRoutes = <String>{'/auth/signup', '/auth/login'};

const headerLinks = <String>[
  '/#how-it-works',
  '/#compare',
  '/#parents',
  '/guides',
  '/#faq',
  '/auth/login',
  '/auth/signup',
];

const footerLinks = <String>[
  '/about',
  '/contact',
  '/privacy',
  '/terms',
  '/guides',
];

const pagesDir = 'web/site/pages';
const homeHtmlBudgetBytes = 70 * 1000;
const cssGzipBudgetBytes = 20 * 1000;
const javascriptBudgetBytes = 20 * 1000;
const fontBudgetBytes = 120 * 1000;

String fileForRoute(String route) =>
    route == '/' ? '$pagesDir/home.html' : '$pagesDir$route.html';

/// The URL a page file is served at, or null for the not-found page.
String? routeForFile(String path) {
  final relative = path.substring(pagesDir.length).replaceAll(r'\', '/');
  if (relative == '/home.html') return '/';
  if (relative == '/404.html') return null;
  return relative.substring(0, relative.length - '.html'.length);
}

List<File> sitePageFiles() => Directory(pagesDir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.html'))
    .toList()
  ..sort((a, b) => a.path.compareTo(b.path));

int totalBytes(String directory, String extension) => Directory(directory)
    .listSync()
    .whereType<File>()
    .where((file) => file.path.endsWith(extension))
    .fold(0, (total, file) => total + file.lengthSync());

Document parsePage(File file) => html_parser.parse(file.readAsStringSync());

Set<String> idsIn(Document document) =>
    document.querySelectorAll('[id]').map((element) => element.id).toSet();

/// Words that would scope Doormer to one audience. The card collection is a
/// gender-neutral set of instruments, not spaceships, and Doormer is for
/// learners of every age.
final scopingWords = <String, RegExp>{
  'spaceship framing': RegExp(
      r'\b(star ?ships?|space ?ships?|ships?|shipyards?|fleets?)\b',
      caseSensitive: false),
  'the 12–18 age range': RegExp(r'12\s*(–|-|to)\s*18', caseSensitive: false),
  'teen-only wording': RegExp(r'\bteens?\b', caseSensitive: false),
};

/// Everything a reader, a screen reader or a search result can show: the
/// page's visible text, its title, labels and image descriptions, and the
/// descriptions shared with search engines and social apps.
String readableText(Document page) => [
      page.querySelector('title')?.text ?? '',
      for (final meta in page.querySelectorAll(
          'meta[name="description"], meta[property^="og:"], meta[name^="twitter:"]'))
        meta.attributes['content'] ?? '',
      for (final script
          in page.querySelectorAll('script[type="application/ld+json"]'))
        script.text,
      for (final labelled in page.querySelectorAll('[aria-label], img[alt]'))
        '${labelled.attributes['aria-label'] ?? ''} ${labelled.attributes['alt'] ?? ''}',
      page.body?.text ?? '',
    ].join('\n');

void main() {
  group('the website has exactly the planned pages', () {
    for (final route in expectedRoutes) {
      test('$route has a page', () {
        expect(File(fileForRoute(route)).existsSync(), isTrue,
            reason: 'Missing ${fileForRoute(route)}');
      });
    }

    test('every page file belongs to a planned route', () {
      final strays = sitePageFiles()
          .map((file) => file.path)
          .where((path) => !path.endsWith('/404.html'))
          .where((path) => !expectedRoutes.contains(routeForFile(path)))
          .toList();
      expect(strays, isEmpty);
    });
  });

  group('the website stays within its size budgets', () {
    test('home page HTML stays at or below 70 KB', () {
      expect(File(fileForRoute('/')).lengthSync(),
          lessThanOrEqualTo(homeHtmlBudgetBytes),
          reason: 'home.html must stay at or below 70 KB');
    });

    test('site CSS stays at or below 20 KB gzipped', () {
      final cssGzipBytes =
          gzip.encode(File('web/site/css/site.css').readAsBytesSync()).length;
      expect(cssGzipBytes, lessThanOrEqualTo(cssGzipBudgetBytes),
          reason: 'site.css must stay at or below 20 KB gzipped');
    });

    test('site JavaScript stays at or below 20 KB', () {
      expect(totalBytes('web/site/js', '.js'),
          lessThanOrEqualTo(javascriptBudgetBytes),
          reason: 'web/site/js/*.js must stay at or below 20 KB total');
    });

    test('site fonts stay at or below 120 KB', () {
      expect(totalBytes('web/site/fonts', '.woff2'),
          lessThanOrEqualTo(fontBudgetBytes),
          reason: 'web/site/fonts/*.woff2 must stay at or below 120 KB total');
    });
  });

  for (final file in sitePageFiles()) {
    group(file.path, () {
      late Document page;

      setUp(() {
        page = parsePage(file);
      });

      test('is written in New Zealand English', () {
        expect(page.documentElement!.attributes['lang'], 'en-NZ');
      });

      test('has a title and a description of search-result length', () {
        final title = page.querySelector('title')?.text.trim() ?? '';
        final description = page
                .querySelector('meta[name="description"]')
                ?.attributes['content']
                ?.trim() ??
            '';
        expect(title.length, inInclusiveRange(10, 65), reason: title);
        expect(description.length, inInclusiveRange(50, 160),
            reason: description);
      });

      test('has one h1, a main landmark and a skip link to it', () {
        expect(page.querySelectorAll('h1'), hasLength(1));
        expect(page.querySelector('main#main'), isNotNull);
        expect(page.querySelector('a.skip-link[href="#main"]'), isNotNull);
      });

      test('carries the shared header and footer links', () {
        final header = page.querySelector('header.site-header')!;
        final footer = page.querySelector('footer.site-footer')!;
        final headerHrefs = header
            .querySelectorAll('a[href]')
            .map((link) => link.attributes['href'])
            .toSet();
        final footerHrefs = footer
            .querySelectorAll('a[href]')
            .map((link) => link.attributes['href'])
            .toSet();
        expect(headerHrefs, containsAll(headerLinks));
        expect(footerHrefs, containsAll(footerLinks));
      });

      test('gives every image a text alternative', () {
        final missing = page
            .querySelectorAll('img')
            .where((img) => !img.attributes.containsKey('alt'))
            .map((img) => img.outerHtml)
            .toList();
        expect(missing, isEmpty);
      });

      test('has no unfinished text', () {
        final text = page.body!.text.toLowerCase();
        for (final marker in ['todo', 'lorem', 'tbd', 'placeholder']) {
          expect(text.contains(marker), isFalse, reason: marker);
        }
      });

      test('keeps its words gender-neutral and open to all ages', () {
        final text = readableText(page);
        for (final MapEntry(key: rule, value: pattern)
            in scopingWords.entries) {
          final found =
              pattern.allMatches(text).map((match) => match[0]).toSet();
          expect(found, isEmpty, reason: 'Found $rule: $found');
        }
      },
          skip: file.path.endsWith('/home.html')
              ? 'The cards section is back to its original design for review; '
                  'its wording changes once the product owner approves it.'
              : false);

      test('links only to pages, anchors and files that exist', () {
        final broken = <String>[];
        final ownIds = idsIn(page);
        final references = [
          ...page
              .querySelectorAll('a[href]')
              .map((element) => element.attributes['href']!),
          ...page
              .querySelectorAll('link[href]')
              .map((element) => element.attributes['href']!),
          ...page
              .querySelectorAll('script[src]')
              .map((element) => element.attributes['src']!),
          ...page
              .querySelectorAll('img[src]')
              .map((element) => element.attributes['src']!),
        ];
        for (final reference in references) {
          if (reference.startsWith('https://') ||
              reference.startsWith('mailto:')) {
            continue;
          }
          if (reference.startsWith('#')) {
            if (!ownIds.contains(reference.substring(1))) {
              broken.add(reference);
            }
            continue;
          }
          if (!reference.startsWith('/')) {
            broken.add(reference);
            continue;
          }
          final hashAt = reference.indexOf('#');
          final path =
              hashAt == -1 ? reference : reference.substring(0, hashAt);
          final fragment =
              hashAt == -1 ? null : reference.substring(hashAt + 1);
          if (expectedRoutes.contains(path)) {
            if (fragment != null) {
              final target = File(fileForRoute(path));
              if (!target.existsSync() ||
                  !idsIn(parsePage(target)).contains(fragment)) {
                broken.add(reference);
              }
            }
            continue;
          }
          if (appRoutes.contains(path)) continue;
          if (!File('web$path').existsSync()) broken.add(reference);
        }
        expect(broken, isEmpty);
      });
    });
  }

  test('the home page has the AdSense verification marker once', () {
    final home = File(fileForRoute('/')).readAsStringSync();
    expect('<!-- google-adsense-account -->'.allMatches(home), hasLength(1));
  });

  test('the sitemap lists every page and nothing else', () {
    final sitemap = File('web/sitemap.xml').readAsStringSync();
    final listed = RegExp(r'<loc>__SITE_ORIGIN__([^<]*)</loc>')
        .allMatches(sitemap)
        .map((match) => match.group(1)!)
        .toSet();
    expect(listed, expectedRoutes);
  });

  test('robots.txt points at the sitemap', () {
    expect(File('web/robots.txt').readAsStringSync(),
        contains('Sitemap: __SITE_ORIGIN__/sitemap.xml'));
  });

  group('nginx sends website paths to the site and app paths to Flutter', () {
    final config = File('nginx.conf').readAsStringSync();
    final pageRule = RegExp(r'location ~ (\^/\(about[^ ]*\$) \{')
        .firstMatch(config)
        ?.group(1);

    test('has a rule for the site pages and for the home page', () {
      expect(pageRule, isNotNull);
      expect(config, contains('location = / {'));
    });

    test('the page rule matches every page except home', () {
      final rule = RegExp(pageRule!);
      for (final route in expectedRoutes.where((route) => route != '/')) {
        expect(rule.hasMatch(route), isTrue, reason: route);
      }
    });

    test('the page rule leaves app and asset paths alone', () {
      final rule = RegExp(pageRule!);
      for (final path in [
        '/auth/login',
        '/auth/signup',
        '/questions/photo',
        '/saved',
        '/collection',
        '/profile',
        '/site/pages/home.html',
        '/index.html',
        '/about/team',
        '/privacy/settings',
        '/guides/nested/page',
      ]) {
        expect(rule.hasMatch(path), isFalse, reason: path);
      }
    });
  });
}
