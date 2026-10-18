import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The atomic design layers, from the bottom up. A file's layer is the nearest
/// folder above it named after one, so `presentation/organisms/x.dart` and
/// `presentation/organisms/cards/x.dart` are both organisms.
const _layers = ['atoms', 'molecules', 'organisms', 'templates', 'pages'];

/// The ending of every file name in a folder below the pages, before `.dart`.
const _suffixes = {
  'atoms': '_atom',
  'molecules': '_molecule',
  'organisms': '_organism',
  'templates': '_template',
  'params': '_params',
};

// Files that broke a rule before it was checked. Renaming or moving one fixes
// it, and then it comes off its list.
const _namedBeforeTheRule = {
  'lib/src/features/questions/presentation/params/solution_trail_node.dart',
  'lib/src/shared/design/atomic/atoms/quest_backdrop.dart',
};
const _scaffoldsBeforeTheRule = {
  'lib/src/shared/widget/not_found_page.dart',
};

final _importOrExport = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// Every Dart file under `lib/`, by its path from the package root.
final List<String> _files = Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .map((file) => file.path.replaceAll(r'\', '/'))
    .where((path) => path.endsWith('.dart'))
    .toList()
  ..sort();

const _layerFolders = {..._layers, 'params'};

/// The layer [path] belongs to: the nearest folder above it named after a
/// layer. Null for a file in no layer, such as routing code.
String? _layerOf(String path) {
  final folders = path.split('/')..removeLast();
  for (final folder in folders.reversed) {
    if (_layerFolders.contains(folder)) return folder;
  }
  return null;
}

String _sourceOf(String path) => File(path).readAsStringSync();

/// What [path] imports and exports: each URI as written, and for a file in
/// this package, its path from the package root.
Iterable<({String uri, String? path})> _importsOf(String path) sync* {
  for (final match in _importOrExport.allMatches(_sourceOf(path))) {
    final uri = match.group(1)!;
    yield (
      uri: uri,
      path: uri.startsWith('package:doormer/')
          ? 'lib/${uri.substring('package:doormer/'.length)}'
          : uri.contains(':')
              ? null
              : Uri.file(path).resolve(uri).path,
    );
  }
}

/// Whether [path] ends with its layer's suffix and holds the class named after
/// it: `organisms/card_detail_organism.dart` holds `CardDetailOrganism`.
bool _isNamedForItsLayer(String path) {
  final fileName = path.split('/').last.replaceAll('.dart', '');
  final className = fileName
      .split('_')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join();
  return fileName.endsWith(_suffixes[_layerOf(path)]!) &&
      RegExp('\\bclass $className\\b').hasMatch(_sourceOf(path));
}

void main() {
  // A layer folder can hold folders of its own, such as organisms/cards/.
  test('a file in a folder inside a layer folder belongs to that layer', () {
    expect(
      _layerOf(
          'lib/src/features/x/presentation/organisms/cards/y_organism.dart'),
      'organisms',
    );
    expect(
      _layerOf('lib/src/features/x/presentation/pages/auth/y_page.dart'),
      'pages',
    );
    expect(
      _layerOf('lib/src/features/x/presentation/params/y_params.dart'),
      'params',
    );
    expect(_layerOf('lib/src/core/routes/destination_shell.dart'), isNull);
  });

  test('nothing below a page uses a bloc', () {
    final offenders = [
      for (final path in _files)
        if (_suffixes.containsKey(_layerOf(path)))
          for (final import in _importsOf(path))
            if (import.uri.startsWith('package:flutter_bloc/') ||
                import.uri.startsWith('package:bloc/') ||
                (import.path?.contains('/bloc/') ?? false))
              '$path imports ${import.uri}',
    ];

    expect(offenders, isEmpty,
        reason: 'Only a page reads a bloc. It hands what the layers below '
            'need down to them, through their params and constructors.');
  });

  test('no layer uses a layer above it', () {
    final offenders = [
      for (final path in _files)
        if (_layers.contains(_layerOf(path)))
          for (final import in _importsOf(path))
            if (import.path != null &&
                _layers.indexOf(_layerOf(import.path!) ?? '') >
                    _layers.indexOf(_layerOf(path)!))
              '$path imports ${import.uri}',
    ];

    expect(offenders, isEmpty,
        reason: 'Atoms build molecules, molecules build organisms, organisms '
            'build templates, and templates build pages: never the other '
            'way round.');
  });

  test('each file below a page is named for its layer and its class', () {
    final misnamed = {
      for (final path in _files)
        if (_suffixes.containsKey(_layerOf(path)) && !_isNamedForItsLayer(path))
          path,
    };

    expect(misnamed, _namedBeforeTheRule,
        reason: 'A file in organisms/ is named like card_detail_organism.dart '
            'and holds the class CardDetailOrganism, and likewise for each '
            'layer. A file on the list that has been fixed comes off it.');
  });

  test('only templates and pages build a Scaffold', () {
    final offenders = {
      for (final path in _files)
        if (!const ['templates', 'pages'].contains(_layerOf(path)) &&
            RegExp(r'\bScaffold\(').hasMatch(_sourceOf(path)))
          path,
    };

    expect(offenders, _scaffoldsBeforeTheRule,
        reason: "A template owns its screen's one Scaffold. Wiring, such as "
            'the nav bar shell in core/routes/, hands its layout to a '
            'template. A file on the list that has been fixed comes off it.');
  });
}
