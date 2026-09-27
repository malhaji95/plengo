import 'package:flutter_test/flutter_test.dart';
import 'package:plengo/core/srs/queue.dart';
import 'package:plengo/core/srs/scheduler.dart';

void main() {
  final now = DateTime.utc(2026, 9, 27, 9).millisecondsSinceEpoch; // 12:00 Damascus
  const minute = Srs.minute;
  CardState learning(int dueIn) =>
      CardState.newCard(now).copyWith(state: CardStateName.learning, step: 1, dueAt: now + dueIn, reps: 1);
  CardState review(int dueAt) =>
      CardState.newCard(now).copyWith(state: CardStateName.review, intervalDays: 5, dueAt: dueAt, reps: 3);
  final tomorrow = startOfBusinessDay(businessDay(now) + 1);

  test('due learning cards come first, earliest first (§13.5)', () {
    final q = buildQueue(
      order: ['n1', 'r1', 'l1', 'l2'],
      states: {'r1': review(now - minute), 'l1': learning(-2 * minute), 'l2': learning(-5 * minute)},
      now: now,
      newLimit: 20,
      reviewLimit: 200,
    );
    expect(q.next, 'l2');
    expect((q.newCount, q.learningCount, q.reviewCount), (1, 2, 1));
  });

  test('then reviews due today (not tomorrow), within the daily review limit', () {
    final q = buildQueue(
      order: ['r1', 'r2', 'r3', 'rt'],
      states: {'r1': review(now - minute), 'r2': review(now), 'r3': review(tomorrow - 1), 'rt': review(tomorrow)},
      now: now,
      newLimit: 0,
      reviewLimit: 2,
    );
    expect(q.reviewCount, 2);
    expect(['r1', 'r2', 'r3'], contains(q.next));
  });

  test('keeps a stable review order for the day', () {
    final states = {for (var i = 0; i < 30; i++) 'r$i': review(now - minute)};
    final order = states.keys.toList();
    final first = buildQueue(order: order, states: states, now: now, newLimit: 0, reviewLimit: 200).next;
    final again = buildQueue(
      order: order.reversed.toList(),
      states: states,
      now: now,
      newLimit: 0,
      reviewLimit: 200,
    ).next;
    expect(again, first);
  });

  test('then new cards in deck order, within the daily new-card limit', () {
    final q = buildQueue(order: ['a', 'b', 'c'], states: {}, now: now, newLimit: 2, reviewLimit: 200);
    expect(q.next, 'a');
    expect(q.newCount, 2);
    final none = buildQueue(order: ['a'], states: {}, now: now, newLimit: 0, reviewLimit: 200);
    expect(none.done, isTrue);
  });

  test('learns ahead up to 20 minutes, then reports when the next card is due', () {
    final ahead = buildQueue(
      order: ['l'],
      states: {'l': learning(15 * minute)},
      now: now,
      newLimit: 0,
      reviewLimit: 200,
    );
    expect(ahead.next, 'l');
    final later = buildQueue(
      order: ['l'],
      states: {'l': learning(30 * minute)},
      now: now,
      newLimit: 0,
      reviewLimit: 200,
    );
    expect(later.done, isTrue);
    expect(later.nextDueAt, now + 30 * minute);
  });
}
