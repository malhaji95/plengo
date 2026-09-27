import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plengo/core/config/version.dart';
import 'package:plengo/core/db/app_database.dart';
import 'package:plengo/features/subjects/subject_screen.dart';
import 'package:plengo/shared/widgets/form_widgets.dart';

void main() {
  test('compareVersions orders dotted versions numerically', () {
    expect(compareVersions('1.2.10', '1.2.9'), 1);
    expect(compareVersions('1.0', '1.0.0'), 0);
    expect(compareVersions('0.9.9', '1.0.0'), -1);
  });

  test('lesson counts follow Arabic number agreement', () {
    expect([0, 1, 2, 3, 10, 11, 25].map(lessonCountLabel), [
      'لا دروس بعد',
      'درس واحد',
      'درسان',
      '3 دروس',
      '10 دروس',
      '11 درساً',
      '25 درساً',
    ]);
  });

  test('validators return Arabic messages', () {
    expect(Validators.email('bad'), 'البريد الإلكتروني غير صحيح');
    expect(Validators.email('a@b.co'), isNull);
    expect(Validators.otp('12345'), isNotNull);
    expect(Validators.otp('123456'), isNull);
    expect(Validators.password('1234567'), isNotNull);
  });

  test('wipe clears learning data but keeps device settings', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.setValue('settings.theme_mode', 'dark');
    await db.setValue('cache.home', '{}');
    await db.wipe();
    expect(await db.getValue('settings.theme_mode'), 'dark');
    expect(await db.getValue('cache.home'), isNull);
  });
}
