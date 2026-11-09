import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/responsive.dart';
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

/// Icon and colour by notification type (V-Notifications): new content blue, review reminders yellow,
/// teacher updates pink, handled reports green, offers orange, announcements red.
({IconData icon, PlengoHue hue}) notificationStyle(NotificationType type) => switch (type) {
  NotificationType.newContent => (icon: Icons.fiber_new_rounded, hue: PlengoColors.blue),
  NotificationType.dueReminder => (icon: Icons.style_outlined, hue: PlengoColors.yellow),
  NotificationType.studyReminder => (icon: Icons.alarm_rounded, hue: PlengoColors.yellow),
  NotificationType.teacherUpdate => (icon: Icons.person_outline_rounded, hue: PlengoColors.pink),
  NotificationType.reportResolved => (icon: Icons.flag_outlined, hue: PlengoColors.green),
  NotificationType.promotion => (icon: Icons.local_offer_outlined, hue: PlengoColors.orange),
  NotificationType.announcement => (icon: Icons.campaign_outlined, hue: PlengoColors.red),
};

void _openSettings(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NotificationSettingsScreen()));

/// V-Notifications: unread («جديد») then read («سابقاً») rows with type-coloured icon tiles,
/// «تعليم الكل كمقروء» in the app bar, more pages on scroll and a link to the settings at the bottom.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.surface;
    final inbox = ref.watch(inboxProvider);
    final unread = inbox.value?.unread ?? 0;
    final settingsLink = Center(
      child: PlengoButton(
        label: 'إعدادات الإشعارات',
        icon: Icons.tune_rounded,
        variant: PlengoButtonVariant.ghost,
        size: PlengoButtonSize.small,
        onPressed: () => _openSettings(context),
      ),
    );
    Future<void> open(StudentNotification n) async {
      await _guard(context, () => ref.read(inboxProvider.notifier).markRead(n));
      if (context.mounted) await openAction(context, ref, n.action, n.actionTarget);
    }

    return Scaffold(
      appBar: AppBar(
        leading: const PlengoBackButton(),
        leadingWidth: kPlengoLeadingWidth,
        title: const Text('الإشعارات'),
        actions: [
          if (unread > 0)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Center(
                child: PlengoButton(
                  label: 'تعليم الكل كمقروء',
                  variant: PlengoButtonVariant.ghost,
                  size: PlengoButtonSize.small,
                  onPressed: () => _guard(context, ref.read(inboxProvider.notifier).markAllRead),
                ),
              ),
            ),
        ],
      ),
      body: ContentWidth(
        child: AsyncView(
          value: inbox,
          onRetry: () => ref.invalidate(inboxProvider),
          data: (st) {
            if (st.items.isEmpty) {
              return ListView(
                padding: const EdgeInsetsDirectional.all(PlengoSpace.screen),
                children: [
                  const PlengoEmptyState(
                    title: 'لا توجد إشعارات',
                    icon: Icons.notifications_none_rounded,
                    hue: PlengoColors.blue,
                  ),
                  settingsLink,
                ],
              );
            }
            final fresh = [
              for (final n in st.items)
                if (n.readAt == null) n,
            ];
            final old = [
              for (final n in st.items)
                if (n.readAt != null) n,
            ];
            Widget group(String title, List<StudentNotification> items) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 12, bottom: 8, start: 4),
                  child: Semantics(
                    header: true,
                    child: Text(title, style: PlengoType.chip.copyWith(color: s.mute)),
                  ),
                ),
                for (final (i, n) in items.indexed) ...[
                  if (i > 0) const SizedBox(height: PlengoSpace.listGap),
                  _NotificationRow(notification: n, onTap: () => open(n)),
                ],
              ],
            );
            return RefreshIndicator(
              onRefresh: () => ref.refresh(inboxProvider.future),
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.extentAfter < 300) ref.read(inboxProvider.notifier).loadMore();
                  return false;
                },
                child: ListView(
                  padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 0, PlengoSpace.screen, 24),
                  children: [
                    if (fresh.isNotEmpty) group('جديد', fresh),
                    if (old.isNotEmpty) group('سابقاً', old),
                    if (st.nextCursor != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: st.loadingMore
                              ? const CircularProgressIndicator()
                              : PlengoButton(
                                  label: 'عرض المزيد',
                                  variant: PlengoButtonVariant.secondary,
                                  size: PlengoButtonSize.small,
                                  onPressed: () => ref.read(inboxProvider.notifier).loadMore(),
                                ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    settingsLink,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One inbox row: the type's icon tile, the title (bold on a warm background while unread, with a blue
/// dot announced as «غير مقروء»), the text and the Damascus date.
class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification, required this.onTap});

  final StudentNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final n = notification;
    final unread = n.readAt == null;
    final style = notificationStyle(n.type);
    final background = !unread
        ? s.card
        : s.isDark
        ? Color.alphaBlend(PlengoColors.yellow.base.withValues(alpha: 0.07), s.card)
        : Color.alphaBlend(PlengoColors.yellow.soft.withValues(alpha: 0.45), s.card);
    final r = BorderRadius.circular(PlengoRadius.row);
    return Semantics(
      button: true,
      container: true,
      child: MergeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: r,
            border: s.isDark ? Border.all(color: s.line) : null,
            boxShadow: s.isDark ? null : [BoxShadow(color: s.line, offset: const Offset(0, 1))],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: r,
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: PlengoSpace.row),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      SubjectIconTile(icon: style.icon, hue: style.hue, soft: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              n.titleAr,
                              style: PlengoType.rowTitle.copyWith(
                                color: s.ink,
                                fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                            Text(n.bodyAr, style: PlengoType.caption.copyWith(color: s.mute)),
                            Text(damascusDate(n.createdAt), style: PlengoType.caption.copyWith(color: s.mute)),
                          ],
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(width: 8),
                        Semantics(
                          label: 'غير مقروء',
                          child: Icon(Icons.circle, size: 10, color: PlengoColors.blue.base),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
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

/// Consent categories (§20.2), the review reminder and its time, and the daily goal (§19.4).
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.surface;
    final prefs = ref.watch(notificationPreferencesProvider);
    final goal = ref.watch(dailyGoalProvider);
    Future<void> save({bool? learning, bool? promotions, String? reminderTime}) => _guard(context, () async {
      await ref
          .read(homeRepositoryProvider)
          .setPreferences(learning: learning, promotions: promotions, reminderTime: reminderTime);
      ref.invalidate(notificationPreferencesProvider);
    });
    Future<void> saveReviewReminder(bool on) => _guard(context, () async {
      await ref.read(homeRepositoryProvider).setPreferences(reviewReminder: on);
      ref.invalidate(notificationPreferencesProvider);
    });
    Widget section(String title, List<Widget> children) => Padding(
      padding: const EdgeInsetsDirectional.only(bottom: PlengoSpace.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title, top: 0),
          PlengoCard(
            padding: const EdgeInsetsDirectional.symmetric(vertical: 4),
            // ListTiles paint their ink on the nearest Material, above the card's colour.
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                children: [
                  for (final (i, c) in children.indexed) ...[
                    if (i > 0) Divider(height: 1, color: s.line, indent: 16, endIndent: 16),
                    c,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(
        leading: const PlengoBackButton(),
        leadingWidth: kPlengoLeadingWidth,
        title: const Text('إعدادات الإشعارات'),
      ),
      body: ContentWidth(
        child: AsyncView(
          value: prefs,
          onRetry: () => ref.invalidate(notificationPreferencesProvider),
          data: (p) {
            final timeEnabled = p.learning && p.reviewReminder;
            return ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 4, PlengoSpace.screen, 24),
              children: [
                section('الإشعارات', [
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
                ]),
                section('التذكير', [
                  SwitchListTile(
                    title: const Text('تذكير المراجعة'),
                    subtitle: const Text('عندما تكون لديك بطاقات مستحقة'),
                    value: p.learning && p.reviewReminder,
                    onChanged: p.learning ? saveReviewReminder : null,
                  ),
                  ListTile(
                    enabled: timeEnabled,
                    title: const Text('وقت تذكير المراجعة'),
                    subtitle: const Text('بتوقيت دمشق، عندما تكون لديك بطاقات مستحقة'),
                    trailing: DropdownButton<String>(
                      value: reminderTimes.contains(p.reminderTime) ? p.reminderTime : null,
                      hint: Directionality(textDirection: TextDirection.ltr, child: Text(p.reminderTime)),
                      onChanged: timeEnabled ? (v) => v == null ? null : save(reminderTime: v) : null,
                      items: [
                        for (final t in reminderTimes)
                          DropdownMenuItem(
                            value: t,
                            child: Directionality(textDirection: TextDirection.ltr, child: Text(t)),
                          ),
                      ],
                    ),
                  ),
                ]),
                section('الهدف اليومي', [
                  ListTile(
                    leading: const SubjectIconTile(icon: Icons.flag_rounded, hue: PlengoColors.green, size: 40),
                    title: const Text('الهدف اليومي'),
                    subtitle: Text(switch (goal) {
                      AsyncData(value: final g) => '$g عنصراً يومياً (بطاقات وإجابات)',
                      _ => '…',
                    }),
                    trailing: Icon(Icons.edit_outlined, color: s.action),
                    onTap: goal.hasValue ? () => editDailyGoal(context, ref, goal.value!) : null,
                  ),
                ]),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// One choice of the daily-goal list shared by V-Goal and the goal sheet on Home.
typedef DailyGoalPreset = ({int goal, String label, int minutes});

const dailyGoalPresets = <DailyGoalPreset>[
  (goal: 10, label: 'خفيف', minutes: 5),
  (goal: 20, label: 'عادي', minutes: 10),
  (goal: 30, label: 'جاد', minutes: 15),
  (goal: 50, label: 'مكثّف', minutes: 25),
  (goal: 100, label: 'تحدٍّ', minutes: 50),
];

/// «حوالي 10 د» (the design's «~10 د»; a tilde does not survive right-to-left text).
String goalMinutesShort(int minutes) => 'حوالي $minutes د';

/// «حوالي 10 دقائق», «حوالي 15 دقيقة».
String goalMinutesLong(int minutes) => 'حوالي $minutes ${minutes >= 3 && minutes <= 10 ? 'دقائق' : 'دقيقة'}';

/// Asks for a new daily goal in a sheet (the V-Goal list) and saves it; Home and settings refresh.
Future<void> editDailyGoal(BuildContext context, WidgetRef ref, int current) async {
  final picked = await showPlengoSheet<int>(
    context: context,
    title: 'الهدف اليومي',
    builder: (_) => _GoalSheet(initial: current),
  );
  if (picked == null || picked == current || !context.mounted) return;
  await _guard(context, () async {
    await ref.read(homeRepositoryProvider).setGoal(picked);
    ref.invalidate(homeProvider);
    ref.invalidate(dailyGoalProvider);
  });
}

class _GoalSheet extends StatefulWidget {
  const _GoalSheet({required this.initial});

  final int initial;

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  late int _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final custom = !dailyGoalPresets.any((p) => p.goal == widget.initial);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('عدد البطاقات والإجابات التي تريد إنجازها كل يوم', style: PlengoType.sub.copyWith(color: s.mute)),
        const SizedBox(height: 12),
        for (final p in dailyGoalPresets) ...[
          RadioRow(
            title: p.label,
            selected: _value == p.goal,
            minHeight: 52,
            onTap: () => setState(() => _value = p.goal),
            trailing: Text('${p.goal} عنصراً · ${goalMinutesShort(p.minutes)}'),
          ),
          const SizedBox(height: 6),
        ],
        if (custom) ...[
          RadioRow(
            title: 'هدفك الحالي',
            selected: _value == widget.initial,
            minHeight: 52,
            onTap: () => setState(() => _value = widget.initial),
            trailing: Text('${widget.initial} عنصراً'),
          ),
          const SizedBox(height: 6),
        ],
        const SizedBox(height: 8),
        PlengoButton(label: 'حفظ', onPressed: () => Navigator.pop(context, _value)),
      ],
    );
  }
}
