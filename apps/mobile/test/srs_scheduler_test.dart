import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plengo/core/srs/scheduler.dart';

/// Replays the fixtures shared with the TypeScript scheduler (spec §41 rule 12).
void main() {
  final fixtures =
      jsonDecode(File('../../packages/srs/fixtures/scheduler.json').readAsStringSync()) as Map<String, Object?>;
  final ratings = {for (final r in Rating.values) r.name: r};

  group('scheduler fixtures (shared with TypeScript)', () {
    for (final sc in (fixtures['scenarios']! as List).cast<Map<String, Object?>>()) {
      test(sc['name']! as String, () {
        var state = CardState.fromJson(sc['start']! as Map<String, Object?>);
        for (final step in (sc['steps']! as List).cast<Map<String, Object?>>()) {
          final at = DateTime.parse(step['at']! as String).millisecondsSinceEpoch;
          state = schedule(state, ratings[step['rating']]!, at, sc['cardId']! as String);
          expect(state, CardState.fromJson(step['expect']! as Map<String, Object?>));
          expect(intervalLabel(state, at), step['label']);
        }
      });
    }

    test('fuzz vectors', () {
      for (final f in (fixtures['fuzz']! as List).cast<Map<String, Object?>>()) {
        expect(
          fuzzInterval(
            f['cardId']! as String,
            f['reps']! as int,
            ratings[f['rating']]!,
            (f['preFuzzDays']! as num).toDouble(),
          ),
          f['expected'],
          reason: '$f',
        );
      }
    });

    test('business days start at 04:00 Asia/Damascus', () {
      for (final b in (fixtures['businessDays']! as List).cast<Map<String, Object?>>()) {
        final at = DateTime.parse(b['at']! as String).millisecondsSinceEpoch;
        expect(businessDay(at), b['day']);
        expect(
          DateTime.fromMillisecondsSinceEpoch(startOfBusinessDay(businessDay(at)), isUtc: true).toIso8601String(),
          b['startsAt'],
        );
      }
    });
  });

  test('previews labels under the three buttons', () {
    final now = DateTime.utc(2026, 9, 27, 9).millisecondsSinceEpoch;
    final p = preview(CardState.newCard(now), now, 'x');
    expect([p[Rating.again]!.label, p[Rating.good]!.label, p[Rating.easy]!.label], ['< 1 د', '10 د', '4 أيام']);
  });

  test('JSON round trip matches the API shape', () {
    final now = DateTime.utc(2026, 9, 27, 9).millisecondsSinceEpoch;
    final s = schedule(CardState.newCard(now), Rating.easy, now, 'x');
    expect(CardState.fromJson(s.toJson()), s);
    expect(s.toJson()['dueAt'], '2026-10-01T01:00:00.000Z');
    expect(s.toJson()['state'], 'review');
  });
}
