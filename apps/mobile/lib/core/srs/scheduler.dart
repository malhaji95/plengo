import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';

/// Spaced repetition, SM-2 / Anki style with three buttons (spec §13.4). A line-by-line port of
/// `packages/srs/src/index.ts`: both must pass `packages/srs/fixtures/scheduler.json` exactly (same
/// arithmetic, rounding, fuzz bytes and 04:00 Asia/Damascus business day). Times are epoch ms (UTC).
abstract final class Srs {
  static const minute = 60000;
  static const day = 86400000;
  static const learningStepsMs = [1 * minute, 10 * minute];
  static const relearningStepsMs = [10 * minute];
  static const graduatingIntervalDays = 1;
  static const easyIntervalDays = 4;
  static const startingEase = 2.5;
  static const minimumEase = 1.3;
  static const easyBonus = 1.3;
  static const lapseIntervalFactor = 0.0;
  static const maximumIntervalDays = 365;
  static const learnAheadLimitMs = 20 * minute;
  static const newCardsPerDay = 20;
  static const maxReviewsPerDay = 200;

  /// Syria has kept UTC+3 all year since 2022; a fixed offset keeps all clients identical.
  static const businessUtcOffsetMs = 3 * 60 * minute;
  static const dayStartsAtMs = 4 * 60 * minute;
}

/// Business-day number of an instant: days start at 04:00 Damascus, whatever the device zone.
int businessDay(int at) => ((at + Srs.businessUtcOffsetMs - Srs.dayStartsAtMs) / Srs.day).floor();

/// UTC instant at which business day [day] starts.
int startOfBusinessDay(int day) => day * Srs.day + Srs.dayStartsAtMs - Srs.businessUtcOffsetMs;

enum CardStateName { newCard, learning, review, relearning }

enum Rating { again, good, easy }

const _stateNames = {
  CardStateName.newCard: 'new',
  CardStateName.learning: 'learning',
  CardStateName.review: 'review',
  CardStateName.relearning: 'relearning',
};

CardStateName cardStateNameFromJson(String s) => _stateNames.entries.firstWhere((e) => e.value == s).key;
String cardStateNameToJson(CardStateName s) => _stateNames[s]!;

class CardState {
  const CardState({
    required this.state,
    required this.step,
    required this.dueAt,
    required this.intervalDays,
    required this.ease,
    required this.reps,
    required this.lapses,
    required this.lastReviewedAt,
  });

  factory CardState.newCard(int now) => CardState(
    state: CardStateName.newCard,
    step: 0,
    dueAt: now,
    intervalDays: 0,
    ease: Srs.startingEase,
    reps: 0,
    lapses: 0,
    lastReviewedAt: null,
  );

  /// The API's `SrsStateInput` shape (ISO-8601 UTC times).
  factory CardState.fromJson(Map<String, Object?> json) => CardState(
    state: cardStateNameFromJson(json['state']! as String),
    step: (json['step']! as num).toInt(),
    dueAt: DateTime.parse(json['dueAt']! as String).millisecondsSinceEpoch,
    intervalDays: (json['intervalDays']! as num).toInt(),
    ease: (json['ease']! as num).toDouble(),
    reps: (json['reps']! as num).toInt(),
    lapses: (json['lapses']! as num).toInt(),
    lastReviewedAt: json['lastReviewedAt'] == null
        ? null
        : DateTime.parse(json['lastReviewedAt']! as String).millisecondsSinceEpoch,
  );

  final CardStateName state;
  final int step;
  final int dueAt;

  /// Whole days in review; during relearning, the interval to return to.
  final int intervalDays;
  final double ease;
  final int reps;
  final int lapses;
  final int? lastReviewedAt;

  static String _iso(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String();

  Map<String, Object?> toJson() => {
    'state': cardStateNameToJson(state),
    'step': step,
    'dueAt': _iso(dueAt),
    'intervalDays': intervalDays,
    'ease': ease,
    'reps': reps,
    'lapses': lapses,
    'lastReviewedAt': lastReviewedAt == null ? null : _iso(lastReviewedAt!),
  };

  CardState copyWith({
    CardStateName? state,
    int? step,
    int? dueAt,
    int? intervalDays,
    double? ease,
    int? reps,
    int? lapses,
    int? lastReviewedAt,
  }) => CardState(
    state: state ?? this.state,
    step: step ?? this.step,
    dueAt: dueAt ?? this.dueAt,
    intervalDays: intervalDays ?? this.intervalDays,
    ease: ease ?? this.ease,
    reps: reps ?? this.reps,
    lapses: lapses ?? this.lapses,
    lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is CardState &&
      other.state == state &&
      other.step == step &&
      other.dueAt == dueAt &&
      other.intervalDays == intervalDays &&
      other.ease == ease &&
      other.reps == reps &&
      other.lapses == lapses &&
      other.lastReviewedAt == lastReviewedAt;

  @override
  int get hashCode => Object.hash(state, step, dueAt, intervalDays, ease, reps, lapses, lastReviewedAt);

  @override
  String toString() => 'CardState(${toJson()})';
}

double _round2(double x) => (x * 100 + 0.5).floor() / 100;
int _roundHalfUp(double x) => (x + 0.5).floor();

int _seedNumber(String seed) {
  final digest = sha256.convert(utf8.encode(seed)).bytes;
  // Unsigned big-endian uint32. Multiplication, not shifts: web ints use 32-bit signed bitwise ops.
  return digest[0] * 16777216 + digest[1] * 65536 + digest[2] * 256 + digest[3];
}

/// §13.4 exact fuzz for review intervals of at least 3 days.
int fuzzInterval(String cardId, int reps, Rating rating, double preFuzzDays) {
  final base = _roundHalfUp(preFuzzDays);
  final span = math.max(1, _roundHalfUp(base * 0.05));
  final bucket = _seedNumber('$cardId:$reps:${rating.name}') % (2 * span + 1);
  return math.min(Srs.maximumIntervalDays, math.max(1, base + bucket - span));
}

int _reviewInterval(String cardId, int reps, Rating rating, double pre) {
  final capped = math.min(Srs.maximumIntervalDays.toDouble(), pre);
  return capped >= 3 ? fuzzInterval(cardId, reps, rating, capped) : math.max(1, _roundHalfUp(capped));
}

/// The state after rating a card at [now]. [cardId] is the stable flashcard or user card id.
CardState schedule(CardState card, Rating rating, int now, String cardId) {
  final reps = card.reps + 1;
  final today = businessDay(now);
  final base = card.copyWith(reps: reps, lastReviewedAt: now);
  CardState toReview(int intervalDays, {double? ease}) => base.copyWith(
    state: CardStateName.review,
    step: 0,
    intervalDays: intervalDays,
    dueAt: startOfBusinessDay(today + intervalDays),
    ease: ease,
  );

  switch (card.state) {
    case CardStateName.newCard:
    case CardStateName.learning:
      if (rating == Rating.again) {
        return base.copyWith(state: CardStateName.learning, step: 0, dueAt: now + Srs.learningStepsMs[0]);
      }
      if (rating == Rating.easy) return toReview(Srs.easyIntervalDays);
      final next = card.state == CardStateName.newCard ? 1 : card.step + 1;
      if (next < Srs.learningStepsMs.length) {
        return base.copyWith(state: CardStateName.learning, step: next, dueAt: now + Srs.learningStepsMs[next]);
      }
      return toReview(Srs.graduatingIntervalDays);
    case CardStateName.review:
      final late = math.max(0, today - businessDay(card.dueAt));
      if (rating == Rating.again) {
        return base.copyWith(
          state: CardStateName.relearning,
          step: 0,
          lapses: card.lapses + 1,
          ease: math.max(Srs.minimumEase, _round2(card.ease - 0.2)),
          intervalDays: math.max(1, (card.intervalDays * Srs.lapseIntervalFactor).floor()),
          dueAt: now + Srs.relearningStepsMs[0],
        );
      }
      if (rating == Rating.good) {
        final pre = math.max(card.intervalDays + 1.0, (card.intervalDays + late / 2) * card.ease);
        return toReview(_reviewInterval(cardId, reps, Rating.good, pre));
      }
      final pre = math.max(card.intervalDays + 1.0, (card.intervalDays + late) * card.ease * Srs.easyBonus);
      return toReview(_reviewInterval(cardId, reps, Rating.easy, pre), ease: _round2(card.ease + 0.15));
    case CardStateName.relearning:
      if (rating == Rating.again) return base.copyWith(step: 0, dueAt: now + Srs.relearningStepsMs[0]);
      final next = card.step + 1;
      if (rating == Rating.good && next < Srs.relearningStepsMs.length) {
        return base.copyWith(step: next, dueAt: now + Srs.relearningStepsMs[next]);
      }
      return toReview(card.intervalDays);
  }
}

String _number(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// Arabic label for a predicted interval (§13.4): د، س، يوم/أيام، شهر.
String intervalLabel(CardState after, int now) {
  if (after.state == CardStateName.learning || after.state == CardStateName.relearning) {
    final minutes = ((after.dueAt - now) / Srs.minute).round();
    if (minutes <= 1) return '< 1 د';
    if (minutes < 60) return '$minutes د';
    return '${(minutes / 60).round()} س';
  }
  final d = after.intervalDays;
  if (d >= 30) return '${_number((d / 30 * 10 + 0.5).floor() / 10)} شهر';
  if (d == 1) return 'يوم';
  if (d == 2) return 'يومان';
  if (d <= 10) return '$d أيام';
  return '$d يوماً';
}

/// Predicted state and label for each button, shown after a flip.
Map<Rating, ({CardState state, String label})> preview(CardState card, int now, String cardId) => {
  for (final rating in Rating.values)
    rating: (
      state: schedule(card, rating, now, cardId),
      label: intervalLabel(schedule(card, rating, now, cardId), now),
    ),
};
