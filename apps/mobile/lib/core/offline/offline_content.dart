import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/generated/export.dart';
import '../db/app_database.dart';
import '../learning/arabic_normalizer.dart';
import 'pack_files.dart';
import 'pack_store.dart';

/// A device clock may lag the server a little; beyond this it counts as set backwards (§22.4).
const clockTolerance = Duration(minutes: 5);
const leaseRefreshEvery = Duration(days: 1);

/// Leases for premium pack content (spec §22.4): refreshed when online (at most daily per scope),
/// checked against the last known server time, and when access is gone the scope's premium pack
/// data is deleted from the device.
class LeaseManager {
  LeaseManager({required this.client, required this.store, required this.files, required this.clock});

  final ApiClient client;
  final PackStore store;
  final PackFileStore files;
  final int Function() clock;

  /// Valid when held, not expired, and the device clock is not behind the server's.
  Future<bool> isValid(String scopeKey) async {
    final lease = await store.lease(scopeKey);
    if (lease == null) return false;
    final now = clock();
    final serverTime = await store.serverTime();
    if (serverTime != null && now < serverTime - clockTolerance.inMilliseconds) return false;
    return now < lease.expiresAt;
  }

  /// Refreshes leases of every scope holding premium packs. Returns the scopes whose content was
  /// removed because the entitlement is gone.
  Future<List<String>> refresh({bool force = false}) => guardApi(() async {
    final now = clock();
    final scopes = <String, OfflinePackRow>{};
    for (final p in await store.packs()) {
      if (p.premium) scopes.putIfAbsent(packScopeKey(p), () => p);
    }
    final due = <String, OfflinePackRow>{};
    for (final MapEntry(key: key, value: p) in scopes.entries) {
      final lease = await store.lease(key);
      if (force || lease == null || now - lease.refreshedAt >= leaseRefreshEvery.inMilliseconds) due[key] = p;
    }
    if (due.isEmpty) return const [];
    final result = (await client.api.offline.refreshOfflineLicenses(
      body: RefreshLeasesRequest(
        scopes: [
          for (final p in due.values)
            LeaseScope(
              scopeType: p.scopeType == 'teacher_track'
                  ? LeaseScopeScopeType.teacherTrack
                  : LeaseScopeScopeType.subject,
              subjectId: p.scopeType == 'subject' ? p.subjectId : null,
              teacherTrackId: p.scopeType == 'teacher_track' ? p.teacherTrackId : null,
            ),
        ],
      ),
    )).data;
    await store.setServerTime(DateTime.parse(result.serverTime).millisecondsSinceEpoch);
    final removed = <String>[];
    for (final l in result.leases) {
      final key = scopeKeyOf(l.scopeType.json!, l.subjectId, l.teacherTrackId);
      if (l.status == OfflineLeaseStatus.active) {
        await store.putLease(key, DateTime.parse(l.expiresAt!).millisecondsSinceEpoch, now);
      } else {
        await store.deleteLease(key);
        await purgePremium(key);
        removed.add(key);
      }
    }
    return removed;
  });

  /// Deletes a scope's premium pack items and their images; free items stay (§22.4).
  Future<void> purgePremium(String scopeKey) async {
    for (final p in await store.packs()) {
      if (packScopeKey(p) != scopeKey) continue;
      final items = await store.itemsOf(p.packKey);
      final premium = items.values.where((i) => !i.isFree).toList();
      for (final card in premium.where((i) => i.type == 'card')) {
        final c = OfflineCard.fromJson(jsonDecode(card.json) as Map<String, Object?>);
        for (final media in [c.front.mediaId, c.back.mediaId]) {
          final f = await store.file(p.packKey, media);
          if (f == null) continue;
          await store.removeFile(p.packKey, media);
          if (!await store.fileShared(f.path, p.packKey)) await files.delete(f.path);
        }
      }
      await store.removeItems(p.packKey, premium.map((i) => i.itemId));
      if (premium.length == items.length) {
        for (final path in await store.deletePack(p.packKey)) {
          await files.delete(path);
        }
      } else {
        // What is left is free; a later update fetches whatever access allows again.
        await store.updatePack(p.packKey, const OfflinePacksCompanion(premium: Value(false), version: Value(null)));
      }
    }
  }
}

/// A question from a pack with what local grading needs.
class PackQuestion {
  const PackQuestion(this.question, {required this.canGradeLocally});

  final OfflineQuestion question;

  /// False for written questions from a pack built with another normalizer version (§22.6).
  final bool canGradeLocally;
}

/// Reads downloaded pack content the student may use now: free items, and premium items of scopes
/// with a valid lease.
class OfflineContent {
  OfflineContent({required this.store, required this.leases, required this.files});

  final PackStore store;
  final LeaseManager leases;
  final PackFileStore files;

  Future<bool> _usable(OfflinePackRow p, OfflineItemRow i) async => i.isFree || await leases.isValid(packScopeKey(p));

  Future<List<(OfflinePackRow, OfflineItemRow)>> _usableOf(String type) async {
    final out = <(OfflinePackRow, OfflineItemRow)>[];
    final seen = <String>{};
    for (final (p, i) in await store.itemsOfType(type)) {
      if (seen.contains(i.itemId) || !await _usable(p, i)) continue;
      seen.add(i.itemId);
      out.add((p, i));
    }
    return out;
  }

  PackQuestion _question(OfflinePackRow p, OfflineItemRow i) {
    final q = OfflineQuestion.fromJson(jsonDecode(i.json) as Map<String, Object?>);
    final sameNormalizer = (p.normalizationVersion ?? ArabicNormalizer.version) == ArabicNormalizer.version;
    return PackQuestion(q, canGradeLocally: q.type != OfflineQuestionType.written || sameNormalizer);
  }

  Future<PackQuestion?> question(String id) async {
    for (final (p, i) in await store.itemById(id)) {
      if (i.type == 'question' && await _usable(p, i)) return _question(p, i);
    }
    return null;
  }

  /// Usable questions of one subject scope, in reading order.
  Future<List<PackQuestion>> questions({
    required String subjectId,
    String? teacherTrackId,
    String? unitId,
    String? lessonId,
    Set<OfflineQuestionType>? types,
  }) async {
    final out = [for (final (p, i) in await _usableOf('question')) _question(p, i)].where((pq) {
      final q = pq.question;
      return q.subjectId == subjectId &&
          q.teacherTrackId == teacherTrackId &&
          (unitId == null || q.unitId == unitId) &&
          (lessonId == null || q.lessonId == lessonId) &&
          (types == null || types.contains(q.type));
    }).toList()..sort((a, b) => a.question.sortOrder.compareTo(b.question.sortOrder));
    return out;
  }

  Future<OfflineQuiz?> quiz(String id) async {
    for (final (p, i) in await store.itemById(id)) {
      if (i.type == 'quiz' && await _usable(p, i)) {
        return OfflineQuiz.fromJson(jsonDecode(i.json) as Map<String, Object?>);
      }
    }
    return null;
  }

  Future<OfflineDeck?> deck(String id) async {
    for (final (p, i) in await store.itemById(id)) {
      if (i.type == 'deck' && await _usable(p, i)) {
        return OfflineDeck.fromJson(jsonDecode(i.json) as Map<String, Object?>);
      }
    }
    return null;
  }

  /// Cards of a downloaded deck in its order; null when the deck is not (usably) downloaded.
  Future<List<OfflineCard>?> cards(String deckId) async {
    final deck = await this.deck(deckId);
    if (deck == null) return null;
    final byId = <String, OfflineCard>{};
    for (final (_, i) in await _usableOf('card')) {
      final c = OfflineCard.fromJson(jsonDecode(i.json) as Map<String, Object?>);
      if (c.deckId == deckId) byId[c.id] = c;
    }
    return [for (final id in deck.cardIds) ?byId[id]];
  }

  Future<OfflineCard?> card(String id) async {
    for (final (p, i) in await store.itemById(id)) {
      if (i.type == 'card' && await _usable(p, i)) {
        return OfflineCard.fromJson(jsonDecode(i.json) as Map<String, Object?>);
      }
    }
    return null;
  }

  /// A decrypted pack image.
  Future<Uint8List?> image(String mediaId) async {
    final f = await store.anyFile(mediaId);
    return f == null ? null : files.read(f.path);
  }
}

/// Grades like the server (spec §14, §22.6): the correct option, or the written answer normalized
/// and compared with the accepted answers. No partial credit.
CheckResult gradeLocally(OfflineQuestion q, {String? selectedOptionId, String? writtenAnswer}) {
  if (q.type == OfflineQuestionType.written) {
    final accepted = q.acceptedAnswers;
    return CheckResult(
      isCorrect: ArabicNormalizer.matches(writtenAnswer ?? '', accepted.map((a) => a.normalized)),
      correctOptionId: null,
      correctAnswer: accepted.isEmpty ? null : accepted.first.original,
      explanation: q.explanation,
    );
  }
  final correct = q.options.where((o) => o.isCorrect).firstOrNull;
  return CheckResult(
    isCorrect: correct != null && correct.id == selectedOptionId,
    correctOptionId: correct?.id,
    correctAnswer: null,
    explanation: q.explanation,
  );
}
