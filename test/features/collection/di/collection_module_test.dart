import 'package:dio/dio.dart';
import 'package:doormer/src/features/collection/di/collection_module.dart';
import 'package:doormer/src/features/collection/domain/usecase/load_friend_collection_usecase.dart';
import 'package:doormer/src/features/collection/domain/usecase/load_friend_decks_usecase.dart';
import 'package:doormer/src/features/collection/presentation/bloc/friend_collection_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  final locator = GetIt.instance;

  setUp(() {
    locator.registerSingleton<Dio>(Dio());
    initCollectionModule();
  });

  tearDown(() => locator.reset());

  test("a friend's collection resolves, from its use cases to its bloc", () {
    expect(locator<LoadFriendDecksUseCase>(), isNotNull);
    expect(locator<LoadFriendCollectionUseCase>(), isNotNull);
    expect(locator<FriendCollectionBloc>(), isA<FriendCollectionBloc>());
  });
}
