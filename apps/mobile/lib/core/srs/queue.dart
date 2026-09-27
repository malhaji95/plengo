import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'scheduler.dart';

/// What a study session shows next and what is left today (spec §13.5).
class QueueSnapshot {
  const QueueSnapshot({
    required this.next,
    required this.newCount,
    required this.learningCount,
    required this.reviewCount,
    required this.nextDueAt,
  });

  /// The card to show now, or null when today's study is done.
  final String? next;
  final int newCount;
  final int learningCount;
  final int reviewCount;

  /// When the next card becomes due (for "أنهيت مراجعة اليوم"), if any.
  final int? nextDueAt;

  bool get done => next == null;
}

/// Stable pseudo-random order of review cards for one business day ("random order", §13.5): the
/// order does not jump around as the queue is rebuilt after each rating.
int _dayShuffleKey(String id, int day) {
  final b = sha256.convert(utf8.encode('$id:$day')).bytes;
  return b[0] * 16777216 + b[1] * 65536 + b[2] * 256 + b[3];
}

/// Builds the queue for [order] (card ids in deck order) from their [states] (missing = new):
/// 1. learning/relearning cards due now, earliest first; 2. review cards due today, up to
/// [reviewLimit]; 3. new cards in deck order, up to [newLimit]; 4. a learning card due within the
/// learn-ahead limit; otherwise done.
QueueSnapshot buildQueue({
  required List<String> order,
  required Map<String, CardState> states,
  required int now,
  required int newLimit,
  required int reviewLimit,
}) {
  final today = businessDay(now);
  final endOfToday = startOfBusinessDay(today + 1);
  final learning = <String>[];
  final reviews = <String>[];
  final fresh = <String>[];
  for (final id in order) {
    final s = states[id];
    if (s == null || s.state == CardStateName.newCard) {
      fresh.add(id);
    } else if (s.state == CardStateName.review) {
      if (s.dueAt < endOfToday) reviews.add(id);
    } else if (s.dueAt < endOfToday) {
      learning.add(id);
    }
  }
  learning.sort((a, b) => states[a]!.dueAt.compareTo(states[b]!.dueAt));
  reviews.sort((a, b) => _dayShuffleKey(a, today).compareTo(_dayShuffleKey(b, today)));
  final dueReviews = reviews.take(reviewLimit < 0 ? 0 : reviewLimit).toList();
  final newCards = fresh.take(newLimit < 0 ? 0 : newLimit).toList();

  String? next;
  final dueLearning = learning.where((id) => states[id]!.dueAt <= now).toList();
  if (dueLearning.isNotEmpty) {
    next = dueLearning.first;
  } else if (dueReviews.isNotEmpty) {
    next = dueReviews.first;
  } else if (newCards.isNotEmpty) {
    next = newCards.first;
  } else if (learning.isNotEmpty && states[learning.first]!.dueAt <= now + Srs.learnAheadLimitMs) {
    next = learning.first;
  }

  int? nextDueAt;
  if (next == null) {
    final upcoming = [
      for (final id in order)
        if (states[id] != null && states[id]!.state != CardStateName.newCard) states[id]!.dueAt,
    ]..sort();
    nextDueAt = upcoming.where((t) => t > now).firstOrNull;
  }
  return QueueSnapshot(
    next: next,
    newCount: newCards.length,
    learningCount: learning.length,
    reviewCount: dueReviews.length,
    nextDueAt: nextDueAt,
  );
}
