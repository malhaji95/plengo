import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/app.dart';
import 'package:plengo/app/providers.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/core/auth/auth_repository.dart';
import 'package:plengo/core/auth/token_store.dart';
import 'package:plengo/core/db/app_database.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const testMe = Me(
  id: 'u1',
  email: 'student@example.com',
  emailVerified: true,
  role: MeRole.student,
  fullName: 'سارة أحمد',
  educationLevelId: null,
);

/// Pumps the real app with a mocked repository and an in-memory database. The config call made
/// at start-up goes nowhere (no server); it is designed to fail silently.
Future<({MockAuthRepository repo, ProviderContainer container})> pumpApp(
  WidgetTester tester, {
  Me? signedInAs,
  void Function(MockAuthRepository repo)? arrange,
}) async {
  final repo = MockAuthRepository();
  when(() => repo.restoreSession()).thenAnswer((_) async => signedInAs);
  when(() => repo.levels()).thenAnswer(
    (_) async => const [
      EducationLevel(id: 'l9', code: 'grade-9', nameAr: 'الصف التاسع', sortOrder: 1),
      EducationLevel(id: 'l12', code: 'grade-12', nameAr: 'البكالوريا', sortOrder: 2),
    ],
  );
  arrange?.call(repo);

  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final container = ProviderContainer(
    overrides: [
      appEnvironmentProvider.overrideWithValue(const AppEnvironment(platform: 'android', appVersion: '1.0.0')),
      tokenStoreProvider.overrideWithValue(MemoryTokenStore()),
      databaseProvider.overrideWithValue(db),
      authRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const PlengoApp()));
  await tester.pumpAndSettle();
  return (repo: repo, container: container);
}

Finder fieldByKey(String key) => find.byKey(Key(key));
