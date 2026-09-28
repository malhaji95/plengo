import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plengo/core/learning/arabic_normalizer.dart';

/// The Dart and TypeScript normalizers pass the same fixtures (spec §22.6).
void main() {
  final fixtures =
      jsonDecode(File('../../packages/arabic-normalizer/fixtures/v1.json').readAsStringSync()) as Map<String, Object?>;

  test('fixture version matches the app normalizer', () {
    expect(fixtures['version'], ArabicNormalizer.version);
  });

  group('normalize', () {
    for (final f in (fixtures['normalize']! as List).cast<Map<String, Object?>>()) {
      test(f['name']! as String, () {
        expect(ArabicNormalizer.normalize(f['input']! as String), f['expected']);
      });
    }
  });

  group('match', () {
    for (final f in (fixtures['match']! as List).cast<Map<String, Object?>>()) {
      test(f['name']! as String, () {
        final accepted = (f['accepted']! as List).cast<String>().map(ArabicNormalizer.normalize);
        expect(ArabicNormalizer.matches(f['input']! as String, accepted), f['correct']);
      });
    }
  });
}
