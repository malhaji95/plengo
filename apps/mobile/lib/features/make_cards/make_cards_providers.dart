import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/generated/export.dart';
import '../../core/db/app_database.dart';
import '../../core/srs/srs_key.dart';
import '../../shared/ui/ui.dart';
import '../flashcards/flashcard_providers.dart';
import '../flashcards/flashcard_ui.dart';
import '../my_decks/my_decks_providers.dart';
import '../my_decks/my_decks_screen.dart' show deckHue;
import '../subjects/catalog_providers.dart';

/// The subjects of the student's level (and university placement) — the subjects a group can belong
/// to (v3 §7). Empty until the student has chosen a level.
final studentSubjectsProvider = FutureProvider.autoDispose<List<CatalogSubject>>((ref) async {
  final me = ref.watch(authControllerProvider).value;
  final level = me?.educationLevelId;
  if (me == null || level == null) return const [];
  final subjects = await ref.watch(
    subjectsProvider((
      levelId: level,
      universityId: me.universityId,
      facultyId: me.facultyId,
      academicYearId: me.academicYearId,
    )).future,
  );
  return [...subjects]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
});

/// A group's colour: its subject's hue, else the deck's own colour.
PlengoHue groupHue(LocalDeckRow d) => d.subjectId != null ? subjectHue(d.subjectId!) : deckHue(d.color, d.id);

/// `#RRGGBB` of a hue's base colour (the deck colour stored with a new group).
String hueHex(PlengoHue hue) => '#${(hue.base.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// A subject's name from the student's subject list; «مادة» when it is not there (another level).
String subjectNameOf(List<CatalogSubject> subjects, String? id) =>
    id == null ? 'بدون مادة' : subjects.where((s) => s.id == id).firstOrNull?.nameAr ?? 'مادة';

/// Progress of one group from this device's SRS states (v3 §7 «إحصائيات التقدم»).
typedef GroupStats = ({int total, int fresh, int learning, int review, int mastered});

/// A review card counts as mastered from this interval on.
const masteredIntervalDays = 21;

final groupStatsProvider = FutureProvider.autoDispose.family<GroupStats, String>((ref, deckId) async {
  final cards = await ref.watch(myDeckCardsProvider(deckId).future);
  final keys = [
    for (final c in cards)
      if (!c.locked) SrsKey.userCard(c.id),
  ];
  final states = await ref.read(srsStoreProvider).statesFor(keys);
  var fresh = 0, learning = 0, review = 0, mastered = 0;
  for (final k in keys) {
    final st = states[k];
    switch (SrsBucket.of(st?.state)) {
      case SrsBucket.fresh:
        fresh++;
      case SrsBucket.learning:
        learning++;
      case SrsBucket.review:
        review++;
        if ((st?.intervalDays ?? 0) >= masteredIntervalDays) mastered++;
    }
  }
  return (total: keys.length, fresh: fresh, learning: learning, review: review, mastered: mastered);
});
