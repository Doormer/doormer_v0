import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/core/utils/invite_code_storage/in_memory_invite_code_storage.dart';
import 'package:doormer/src/core/utils/invite_code_storage/invite_code_storage.dart';
import 'package:doormer/src/core/utils/invite_code_storage/invite_code_storage_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_html/html.dart' as html;

void main() {
  setUpAll(AppLogger.disable);

  final implementations =
      <String, InviteCodeStorage Function(DateTime Function() now)>{
    'in the browser': (now) => InviteCodeStorageWeb(now: now),
    'in memory': (now) => InMemoryInviteCodeStorage(now: now),
  };

  for (final MapEntry(key: name, value: make) in implementations.entries) {
    group(name, () {
      late DateTime now;
      late InviteCodeStorage storage;

      setUp(() async {
        now = DateTime.utc(2026, 10, 26, 9);
        storage = make(() => now);
        await storage.forget();
      });

      test('keeps nothing at first', () async {
        expect(await storage.read(), isNull);
      });

      test('reads back the code it kept', () async {
        await storage.keep('K7QM2XPA');

        expect(await storage.read(), 'K7QM2XPA');
      });

      test('a newer code takes the place of the older one', () async {
        await storage.keep('K7QM2XPA');
        await storage.keep('NEWC0DE2');

        expect(await storage.read(), 'NEWC0DE2');
      });

      test('forgets the code', () async {
        await storage.keep('K7QM2XPA');
        await storage.forget();

        expect(await storage.read(), isNull);
      });

      test('keeps a code for 7 days', () async {
        await storage.keep('K7QM2XPA');

        now = now.add(const Duration(days: 7) - const Duration(minutes: 1));
        expect(await storage.read(), 'K7QM2XPA');

        now = now.add(const Duration(minutes: 1));
        expect(await storage.read(), isNull);
      });
    });
  }

  test('in the browser, a kept value it cannot read counts as none', () async {
    final storage = InviteCodeStorageWeb();
    html.window.localStorage['friend_invite_code'] = 'not json';

    expect(await storage.read(), isNull);
    expect(html.window.localStorage['friend_invite_code'], isNull);
  });
}
