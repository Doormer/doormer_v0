import 'dart:convert';

import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:flutter/services.dart';

import '../../domain/entity/collection.dart';
import '../../domain/entity/draw_outcome.dart';
import '../model/collection_model.dart';

abstract class CollectionLocalDataSource {
  Future<Collection> loadCollection();

  Future<List<DrawOutcome>> loadDrawSequence();
}

/// The only source of collection data in this build. Every draw is replayed
/// from a fixed sequence in the asset rather than rolled here — the real odds,
/// the rarity table and the guarantee all live in the Go engine, and a second
/// implementation in Dart would drift from it without anyone noticing.
class CollectionLocalDataSourceImpl implements CollectionLocalDataSource {
  static const String mockAssetPath = 'assets/mock/mock_collection.json';

  final AssetBundle _bundle;

  CollectionLocalDataSourceImpl({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  Future<Map<String, dynamic>> _read() async {
    final raw = await _bundle.loadString(mockAssetPath);
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  @override
  Future<Collection> loadCollection() async {
    try {
      return CollectionModel.collectionFrom(await _read());
    } catch (e, stackTrace) {
      AppLogger.error(
        'Collection asset load failed',
        error: e,
        stackTrace: stackTrace,
      );
      throw DatabaseFailure('We could not open your collection.');
    }
  }

  @override
  Future<List<DrawOutcome>> loadDrawSequence() async {
    try {
      return CollectionModel.sequenceFrom(await _read());
    } catch (e, stackTrace) {
      AppLogger.error(
        'Draw sequence asset load failed',
        error: e,
        stackTrace: stackTrace,
      );
      throw DatabaseFailure('We could not open your collection.');
    }
  }
}
