import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../shared/widgets/async_view.dart';
import '../access/access_format.dart';
import 'home_providers.dart';

typedef InboxState = ({List<StudentNotification> items, String? nextCursor, int unread, bool loadingMore});

/// The in-app inbox (spec §20.3): every notification, including those never pushed.
class InboxController extends AsyncNotifier<InboxState> {
  @override
  Future<InboxState> build() async {
    final page = await ref.watch(homeRepositoryProvider).notifications();
    return (items: page.items, nextCursor: page.nextCursor, unread: page.unreadCount, loadingMore: false);
  }

  Future<void> loadMore() async {
    final s = state.value;
    if (s == null || s.nextCursor == null || s.loadingMore) return;
    state = AsyncData((items: s.items, nextCursor: s.nextCursor, unread: s.unread, loadingMore: true));
    try {
      final page = await ref.read(homeRepositoryProvider).notifications(cursor: s.nextCursor);
      state = AsyncData((
        items: [...s.items, ...page.items],
        nextCursor: page.nextCursor,
        unread: page.unreadCount,
        loadingMore: false,
      ));
    } catch (_) {
      state = AsyncData((items: s.items, nextCursor: s.nextCursor, unread: s.unread, loadingMore: false));
    }
  }

  Future<void> markRead(StudentNotification n) async {
    if (n.readAt != null) return;
    final unread = await ref.read(homeRepositoryProvider).markRead(n.id);
    _apply(unread, (item) => item.id == n.id);
  }

  Future<void> markAllRead() async {
    final unread = await ref.read(homeRepositoryProvider).markAllRead();
    _apply(unread, (_) => true);
  }

  void _apply(int unread, bool Function(StudentNotification) which) {
    final s = state.value;
    if (s == null) return;
    final now = DateTime.now().toUtc().toIso8601String();
    state = AsyncData((
      items: [for (final i in s.items) which(i) && i.readAt == null ? _read(i, now) : i],
      nextCursor: s.nextCursor,
      unread: unread,
      loadingMore: false,
    ));
    // The bell on Home shows the new count next time it is seen.
    ref.invalidate(homeProvider);
  }
}

StudentNotification _read(StudentNotification n, String at) => StudentNotification(
  id: n.id,
  type: n.type,
  titleAr: n.titleAr,
  bodyAr: n.bodyAr,
  action: n.action,
  actionTarget: n.actionTarget,
  createdAt: n.createdAt,
  readAt: at,
);

final inboxProvider = AsyncNotifierProvider.autoDispose<InboxController, InboxState>(InboxController.new);

const _typeIcons = {
  NotificationType.newContent: Icons.fiber_new_outlined,
  NotificationType.teacherUpdate: Icons.person_outline,
  NotificationType.dueReminder: Icons.style_outlined,
  NotificationType.studyReminder: Icons.alarm,
  NotificationType.announcement: Icons.campaign_outlined,
  NotificationType.promotion: Icons.local_offer_outlined,
  NotificationType.reportResolved: Icons.flag_outlined,
};

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(inboxProvider);
    final unread = inbox.value?.unread ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () => _guard(context, ref.read(inboxProvider.notifier).markAllRead),
              child: const Text('تعليم الكل كمقروء'),
            ),
          IconButton(
            tooltip: 'إعدادات الإشعارات',
            icon: const Icon(Icons.tune),
            onPressed: () =>
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NotificationSettingsScreen())),
          ),
        ],
      ),
      body: AsyncView(
        value: inbox,
        onRetry: () => ref.invalidate(inboxProvider),
        data: (s) => s.items.isEmpty
            ? const EmptyState('لا توجد إشعارات', icon: Icons.notifications_none)
            : RefreshIndicator(
                onRefresh: () => ref.refresh(inboxProvider.future),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.extentAfter < 300) ref.read(inboxProvider.notifier).loadMore();
                    return false;
                  },
                  child: ListView.separated(
                    itemCount: s.items.length + (s.nextCursor != null ? 1 : 0),
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      if (i == s.items.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: s.loadingMore
                                ? const CircularProgressIndicator()
                                : OutlinedButton(
                                    onPressed: () => ref.read(inboxProvider.notifier).loadMore(),
                                    child: const Text('عرض المزيد'),
                                  ),
                          ),
                        );
                      }
                      final n = s.items[i];
                      final isUnread = n.readAt == null;
                      return ListTile(
                        leading: Icon(_typeIcons[n.type] ?? Icons.notifications_outlined),
                        title: Text(
                          n.titleAr,
                          style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal),
                        ),
                        subtitle: Text('${n.bodyAr}\n${damascusDate(n.createdAt)}'),
                        isThreeLine: true,
                        trailing: isUnread
                            ? Icon(Icons.circle, size: 10, color: Theme.of(context).colorScheme.primary)
                            : null,
                        onTap: () async {
                          await _guard(context, () => ref.read(inboxProvider.notifier).markRead(n));
                          if (context.mounted) await openAction(context, ref, n.action, n.actionTarget);
                        },
                      );
                    },
                  ),
                ),
              ),
      ),
    );
  }
}

Future<void> _guard(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } on ApiException catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
  }
}

/// Reminder times offered: the reminder job runs hourly (spec §20.3).
final reminderTimes = [for (var h = 6; h <= 23; h++) '${h.toString().padLeft(2, '0')}:00'];

/// Consent categories (§20.2), the due-card reminder time and the daily goal (§19.4).
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPreferencesProvider);
    final goal = ref.watch(dailyGoalProvider);
    Future<void> save({bool? learning, bool? promotions, String? reminderTime}) => _guard(context, () async {
      await ref
          .read(homeRepositoryProvider)
          .setPreferences(learning: learning, promotions: promotions, reminderTime: reminderTime);
      ref.invalidate(notificationPreferencesProvider);
    });
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات الإشعارات')),
      body: AsyncView(
        value: prefs,
        onRetry: () => ref.invalidate(notificationPreferencesProvider),
        data: (p) => ListView(
          children: [
            SwitchListTile(
              title: const Text('التعلّم'),
              subtitle: const Text('محتوى جديد، تحديثات المدرسين، وتذكير المراجعة'),
              value: p.learning,
              onChanged: (v) => save(learning: v),
            ),
            SwitchListTile(
              title: const Text('العروض'),
              subtitle: const Text('عروض وخصومات. لن تصلك إلا إذا فعّلتها'),
              value: p.promotions,
              onChanged: (v) => save(promotions: v),
            ),
            ListTile(
              enabled: p.learning,
              title: const Text('وقت تذكير المراجعة'),
              subtitle: const Text('بتوقيت دمشق، عندما تكون لديك بطاقات مستحقة'),
              trailing: DropdownButton<String>(
                value: reminderTimes.contains(p.reminderTime) ? p.reminderTime : null,
                hint: Directionality(textDirection: TextDirection.ltr, child: Text(p.reminderTime)),
                onChanged: p.learning ? (v) => v == null ? null : save(reminderTime: v) : null,
                items: [
                  for (final t in reminderTimes)
                    DropdownMenuItem(
                      value: t,
                      child: Directionality(textDirection: TextDirection.ltr, child: Text(t)),
                    ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('الهدف اليومي'),
              subtitle: Text(switch (goal) {
                AsyncData(value: final g) => '$g عنصراً يومياً (بطاقات وإجابات)',
                _ => '…',
              }),
              trailing: const Icon(Icons.edit_outlined),
              onTap: goal.hasValue ? () => editDailyGoal(context, ref, goal.value!) : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks for a new daily goal (1–500) and saves it; Home and settings refresh.
Future<void> editDailyGoal(BuildContext context, WidgetRef ref, int current) async {
  final picked = await showDialog<int>(
    context: context,
    builder: (_) => _GoalDialog(initial: current),
  );
  if (picked == null || picked == current || !context.mounted) return;
  await _guard(context, () async {
    await ref.read(homeRepositoryProvider).setGoal(picked);
    ref.invalidate(homeProvider);
    ref.invalidate(dailyGoalProvider);
  });
}

class _GoalDialog extends StatefulWidget {
  const _GoalDialog({required this.initial});

  final int initial;

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  static const _presets = [10, 20, 30, 50, 100];
  late int _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('الهدف اليومي'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('عدد البطاقات والإجابات التي تريد إنجازها كل يوم'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final p in {..._presets, widget.initial}.toList()..sort())
                ChoiceChip(label: Text('$p'), selected: _value == p, onSelected: (_) => setState(() => _value = p)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(context, _value), child: const Text('حفظ')),
      ],
    );
  }
}
