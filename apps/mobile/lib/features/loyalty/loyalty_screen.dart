import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../access/access_format.dart' show damascusDate;
import '../home/home_providers.dart' show homeProvider;
import 'loyalty_repository.dart';

/// «N نقطة» with Western digits.
String pointsLabel(int n) => '$n نقطة';

/// نقاطي (V3_PLAN §10): the balance, today's points toward the daily cap, how to earn, the rewards
/// to redeem, my redemptions and the points history. Shows nothing but a notice when loyalty is off.
class LoyaltyScreen extends ConsumerStatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  ConsumerState<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends ConsumerState<LoyaltyScreen> {
  String? _redeeming;

  @override
  void initState() {
    super.initState();
    // The kept-alive summary may be old (reviews since): fetch it again on open.
    Future.microtask(() {
      if (mounted) ref.invalidate(loyaltySummaryProvider);
    });
  }

  Future<void> _refresh() async {
    ref
      ..invalidate(loyaltyRewardsProvider)
      ..invalidate(loyaltyHistoryProvider)
      ..invalidate(loyaltyRedemptionsProvider)
      ..invalidate(loyaltySummaryProvider);
    await ref.read(loyaltySummaryProvider.future);
  }

  Future<void> _redeem(LoyaltyReward r, int balance) async {
    final ok = await showConfirmSheet(
      context,
      title: 'استبدال ${pointsLabel(r.costPoints)}؟',
      message: '«${r.titleAr}» مقابل ${pointsLabel(r.costPoints)}. يبقى لك ${pointsLabel(balance - r.costPoints)}.',
      icon: Icons.redeem_rounded,
      hue: PlengoColors.yellow,
      primaryLabel: 'استبدال',
      secondaryLabel: 'إلغاء',
    );
    if (ok != true || !mounted) return;
    setState(() => _redeeming = r.id);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref.read(loyaltyRepositoryProvider).redeem(r.id);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      setState(() => _redeeming = null);
      await _showSuccess(r, result);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(key: const Key('loyalty.error'), content: Text(e.message)));
      // The balance or ownership changed elsewhere: show the server's view.
      if (e.code == 'INSUFFICIENT_POINTS' || e.code == 'ALREADY_ENTITLED') _refresh().ignore();
    } finally {
      if (mounted) setState(() => _redeeming = null);
    }
  }

  Future<void> _showSuccess(LoyaltyReward r, LoyaltyRedeemResult result) {
    final deckId = result.redemption.deckId ?? r.deckId;
    final unlock = r.kind == LoyaltyRewardKind.unlockDeck && deckId != null;
    return showPlengoSheet<void>(
      context: context,
      builder: (sheet) {
        final s = sheet.surface;
        return Column(
          key: const Key('loyalty.success'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: StateIllustration(icon: Icons.check_rounded, hue: PlengoColors.green, size: 96),
            ),
            const SizedBox(height: 12),
            Semantics(
              header: true,
              child: Text(
                unlock ? 'تم فتح المجموعة!' : 'تم إرسال طلبك',
                textAlign: TextAlign.center,
                style: PlengoType.section.copyWith(color: s.ink),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              unlock
                  ? 'أصبحت «${r.deckTitleAr ?? r.titleAr}» متاحة لك.'
                  : 'سنراجع طلب «${r.titleAr}» ونتواصل معك قريباً.',
              textAlign: TextAlign.center,
              style: PlengoType.sub.copyWith(color: s.mute),
            ),
            const SizedBox(height: 4),
            Text(
              'رصيدك الآن: ${pointsLabel(result.balance)}',
              textAlign: TextAlign.center,
              style: PlengoType.rowTitle.copyWith(color: s.ink),
            ),
            const SizedBox(height: 16),
            if (unlock)
              PlengoButton(
                key: const Key('loyalty.openDeck'),
                label: 'افتح المجموعة',
                icon: Icons.style_rounded,
                onPressed: () {
                  Navigator.pop(sheet);
                  // `go`, not `push`: the deck page lives in the tab shell, which a pushed top-level route
                  // cannot stack under itself.
                  context.go('${Routes.decks}/$deckId');
                },
              )
            else
              PlengoButton(label: 'حسناً', onPressed: () => Navigator.pop(sheet)),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(loyaltySummaryProvider);
    return Scaffold(
      appBar: AppBar(leading: const PlengoBackButton(), leadingWidth: kPlengoLeadingWidth, title: const Text('نقاطي')),
      body: AsyncView(
        value: summary,
        onRetry: () => ref.invalidate(loyaltySummaryProvider),
        data: (sum) {
          if (!sum.enabled) {
            return const PlengoEmptyState(
              key: Key('loyalty.disabled'),
              icon: Icons.star_outline_rounded,
              hue: PlengoColors.yellow,
              title: 'برنامج النقاط غير متاح حالياً',
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 24),
                  children: [
                    _BalanceHero(balance: sum.balance),
                    const SizedBox(height: PlengoSpace.section),
                    _TodayCard(summary: sum),
                    const SizedBox(height: PlengoSpace.section),
                    _RulesCard(rules: sum.rules),
                    const SectionHeader('المكافآت'),
                    _Rewards(redeeming: _redeeming, onRedeem: _redeem),
                    const _Redemptions(),
                    const _History(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) => PlengoHeroCard(
    semanticsLabel: 'رصيدك ${pointsLabel(balance)}',
    child: ExcludeSemantics(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: PlengoColors.yellow.base, shape: BoxShape.circle),
            child: const Icon(Icons.star_rounded, color: PlengoColors.ink, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('رصيدك', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(
                  '$balance',
                  key: const Key('loyalty.balance'),
                  style: PlengoType.display.copyWith(color: Colors.white, fontSize: 34),
                ),
                const Text('نقطة', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.summary});

  final LoyaltySummary summary;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final cap = summary.dailyCap;
    final earned = summary.earnedToday;
    final remaining = summary.remainingToday;
    return PlengoCard(
      key: const Key('loyalty.today'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('نقاط اليوم', style: PlengoType.rowTitle.copyWith(color: s.ink)),
          const SizedBox(height: 10),
          if (cap > 0) ...[
            PlengoProgressBar(
              value: (earned / cap).clamp(0, 1).toDouble(),
              label: '$earned من $cap',
              color: PlengoColors.yellow.base,
              semanticsLabel: 'حصلت اليوم على $earned من $cap نقطة',
            ),
            const SizedBox(height: 8),
            Text(
              remaining == 0
                  ? 'بلغت حدّ اليوم، عُد غداً لتجمع المزيد.'
                  : 'تبقّى لك ${pointsLabel(remaining ?? cap - earned)} اليوم.',
              style: PlengoType.caption.copyWith(color: s.mute),
            ),
          ] else
            Text('حصلت اليوم على ${pointsLabel(earned)}', style: PlengoType.sub.copyWith(color: s.ink)),
        ],
      ),
    );
  }
}

class _RulesCard extends StatelessWidget {
  const _RulesCard({required this.rules});

  final LoyaltySettings rules;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    Widget row(IconData icon, PlengoHue hue, String title, String value) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          SubjectIconTile(icon: icon, hue: hue, size: 40, soft: true),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: PlengoType.sub.copyWith(color: s.ink, height: 1.4)),
          ),
          const SizedBox(width: 8),
          PlengoChip(label: value, hue: PlengoColors.yellow, icon: Icons.star_rounded),
        ],
      ),
    );
    return PlengoCard(
      key: const Key('loyalty.rules'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('كيف تجمع النقاط؟', style: PlengoType.rowTitle.copyWith(color: s.ink)),
          if (rules.pointsPerReview > 0)
            row(Icons.style_rounded, PlengoColors.pink, 'راجع بطاقة من بطاقاتك المستحقة', '+${rules.pointsPerReview}'),
          if (rules.pointsPerCorrectQuestion > 0)
            row(
              Icons.check_circle_rounded,
              PlengoColors.green,
              'أجب عن سؤال إجابة صحيحة',
              '+${rules.pointsPerCorrectQuestion}',
            ),
          if (rules.dailyCap > 0)
            row(Icons.today_rounded, PlengoColors.blue, 'الحد الأعلى للنقاط في اليوم', '${rules.dailyCap}'),
        ],
      ),
    );
  }
}

class _Rewards extends ConsumerWidget {
  const _Rewards({required this.redeeming, required this.onRedeem});

  final String? redeeming;
  final Future<void> Function(LoyaltyReward reward, int balance) onRedeem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewards = ref.watch(loyaltyRewardsProvider);
    return switch (rewards) {
      AsyncValue(:final value?) when value.items.isEmpty => const _Note('لا توجد مكافآت حالياً، تابع جمع النقاط.'),
      AsyncValue(:final value?) => Column(
        children: [
          for (final r in [...value.items]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder))) ...[
            _RewardCard(
              reward: r,
              balance: value.balance,
              busy: redeeming == r.id,
              onRedeem: redeeming == null ? () => onRedeem(r, value.balance) : null,
            ),
            const SizedBox(height: PlengoSpace.listGap),
          ],
        ],
      ),
      AsyncValue(:final error?) => _Note(
        error is ApiException ? error.message : ApiException.genericMessage,
        onRetry: () => ref.invalidate(loyaltyRewardsProvider),
      ),
      _ => const PlengoLoadingSkeleton(hero: false, rows: 2, padding: EdgeInsets.zero),
    };
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.reward, required this.balance, required this.busy, required this.onRedeem});

  final LoyaltyReward reward;
  final int balance;
  final bool busy;
  final VoidCallback? onRedeem;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final r = reward;
    final deck = r.kind == LoyaltyRewardKind.unlockDeck;
    final missing = r.costPoints - balance;
    return PlengoCard(
      key: Key('loyalty.reward.${r.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SubjectIconTile(
                icon: deck ? Icons.style_rounded : Icons.card_giftcard_rounded,
                hue: deck ? PlengoColors.pink : PlengoColors.orange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.titleAr, style: PlengoType.rowTitle.copyWith(color: s.ink)),
                    if (deck && r.deckTitleAr != null && r.deckTitleAr != r.titleAr)
                      Text(r.deckTitleAr!, style: PlengoType.caption.copyWith(color: s.mute)),
                    if (r.description != null && r.description!.trim().isNotEmpty)
                      Text(r.description!, style: PlengoType.caption.copyWith(color: s.mute)),
                    const SizedBox(height: 6),
                    PlengoChip(label: pointsLabel(r.costPoints), hue: PlengoColors.yellow, icon: Icons.star_rounded),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (r.alreadyOwned)
            Row(
              children: [
                const PlengoChip(label: 'لديك هذه المكافأة', hue: PlengoColors.green, icon: Icons.check_rounded),
                const Spacer(),
                if (deck && r.deckId != null)
                  PlengoButton(
                    label: 'افتح',
                    variant: PlengoButtonVariant.ghost,
                    size: PlengoButtonSize.small,
                    onPressed: () => context.go('${Routes.decks}/${r.deckId}'),
                  ),
              ],
            )
          else ...[
            PlengoButton(
              key: Key('loyalty.redeem.${r.id}'),
              label: 'استبدال',
              icon: Icons.redeem_rounded,
              size: PlengoButtonSize.small,
              expand: true,
              busy: busy,
              variant: PlengoButtonVariant.brand,
              onPressed: r.affordable ? onRedeem : null,
            ),
            if (!r.affordable && missing > 0) ...[
              const SizedBox(height: 6),
              Text(
                'تحتاج ${pointsLabel(missing)} إضافية',
                textAlign: TextAlign.center,
                style: PlengoType.caption.copyWith(color: s.mute),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Redemptions extends ConsumerWidget {
  const _Redemptions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(loyaltyRedemptionsProvider).value ?? const <LoyaltyRedemption>[];
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const Key('loyalty.redemptions'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('طلباتي'),
        PlengoCard(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            children: [
              for (final (i, r) in items.indexed)
                ListRow(
                  flat: true,
                  showDivider: i < items.length - 1,
                  icon: r.kind == LoyaltyRewardKind.unlockDeck ? Icons.style_rounded : Icons.card_giftcard_rounded,
                  hue: r.kind == LoyaltyRewardKind.unlockDeck ? PlengoColors.pink : PlengoColors.orange,
                  title: r.titleAr,
                  caption: '${pointsLabel(r.costPoints)} · ${damascusDate(r.createdAt)}',
                  trailing: _StatusChip(status: r.status),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final LoyaltyRedemptionStatus status;

  @override
  Widget build(BuildContext context) => switch (status) {
    LoyaltyRedemptionStatus.fulfilled => const PlengoChip(
      label: 'تم التنفيذ',
      hue: PlengoColors.green,
      icon: Icons.check_rounded,
    ),
    LoyaltyRedemptionStatus.cancelled => const PlengoChip(
      label: 'أُلغي',
      hue: PlengoColors.red,
      icon: Icons.close_rounded,
    ),
    _ => const PlengoChip(label: 'قيد المراجعة', hue: PlengoColors.orange, icon: Icons.schedule_rounded),
  };
}

const _reasons = {
  LoyaltyReason.review: 'مراجعة البطاقات',
  LoyaltyReason.correctAnswer: 'إجابات صحيحة',
  LoyaltyReason.redemption: 'استبدال مكافأة',
  LoyaltyReason.refund: 'استرجاع نقاط',
  LoyaltyReason.adminAdjust: 'تعديل من الإدارة',
};

class _History extends ConsumerWidget {
  const _History();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.surface;
    final history = ref.watch(loyaltyHistoryProvider);
    final items = history.value;
    return Column(
      key: const Key('loyalty.history'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('سجل النقاط'),
        if (items == null)
          history.hasError
              ? _Note(ApiException.genericMessage, onRetry: () => ref.invalidate(loyaltyHistoryProvider))
              : const PlengoLoadingSkeleton(hero: false, rows: 2, padding: EdgeInsets.zero)
        else if (items.isEmpty)
          const _Note('لا توجد حركات بعد. راجع بطاقاتك لتبدأ بجمع النقاط.')
        else
          PlengoCard(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              children: [
                for (final (i, e) in items.indexed)
                  ListRow(
                    flat: true,
                    showDivider: i < items.length - 1,
                    icon: e.delta >= 0 ? Icons.add_rounded : Icons.remove_rounded,
                    hue: e.delta >= 0 ? PlengoColors.green : PlengoColors.red,
                    title: e.note?.trim().isNotEmpty == true && e.reason == LoyaltyReason.adminAdjust
                        ? e.note!
                        : _reasons[e.reason] ?? '',
                    caption: damascusDate(e.createdAt),
                    trailing: Text(
                      '${e.delta > 0
                          ? '+'
                          : e.delta < 0
                          ? '−'
                          : ''}${e.delta.abs()}',
                      textDirection: TextDirection.ltr,
                      style: PlengoType.rowTitle.copyWith(
                        color: e.delta >= 0
                            ? (s.isDark ? PlengoColors.green.base : PlengoColors.green.ink)
                            : (s.isDark ? PlengoColors.red.base : PlengoColors.red.ink),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text, {this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return PlengoCard(
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: PlengoType.sub.copyWith(color: s.mute)),
          ),
          if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}

/// ★ balance on the Home header; tap → نقاطي. Nothing while loyalty is off, loading or offline.
class LoyaltyPointsChip extends ConsumerWidget {
  const LoyaltyPointsChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Home reloading (pull to refresh, coming back to Home) refreshes the balance too.
    ref.listen(homeProvider, (prev, next) {
      if (prev != null && prev.hasValue && prev.isLoading && !next.isLoading) ref.invalidate(loyaltySummaryProvider);
    });
    final summary = ref.watch(loyaltySummaryProvider).value;
    if (summary == null || !summary.enabled) return const SizedBox.shrink();
    final s = context.surface;
    final yellow = PlengoColors.yellow;
    final r = BorderRadius.circular(PlengoRadius.pill);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Semantics(
        button: true,
        label: 'نقاطي: ${pointsLabel(summary.balance)}',
        excludeSemantics: true,
        child: Material(
          key: const Key('home.points'),
          color: s.isDark ? yellow.base.withValues(alpha: 0.18) : yellow.soft,
          borderRadius: r,
          child: InkWell(
            borderRadius: r,
            onTap: () => context.push(Routes.loyalty),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 20, color: s.isDark ? yellow.base : yellow.ink),
                    const SizedBox(width: 4),
                    Text(
                      '${summary.balance}',
                      style: PlengoType.rowTitle.copyWith(color: s.isDark ? yellow.base : yellow.ink, height: 1.2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
