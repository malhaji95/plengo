import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/api/generated/export.dart';

final homeProvider = FutureProvider<Home>((ref) => ref.watch(homeRepositoryProvider).home());

final notificationPreferencesProvider = FutureProvider.autoDispose<NotificationPreferences>(
  (ref) => ref.watch(homeRepositoryProvider).preferences(),
);

final dailyGoalProvider = FutureProvider.autoDispose<int>((ref) => ref.watch(homeRepositoryProvider).goal());

/// Opens external links; replaced in tests.
final externalUrlLauncherProvider = Provider<Future<void> Function(Uri)>(
  (ref) =>
      (uri) async => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// Banner images (network, cached); replaced in tests where there is no network.
final bannerImageBuilderProvider = Provider<Widget Function(BuildContext, HomeBanner)>(
  (ref) =>
      (_, b) => Image.network(
        b.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Center(child: Text(b.titleAr, textAlign: TextAlign.center)),
      ),
);

/// Where a banner or notification tap goes (spec §19.2). Unknown or malformed targets do nothing:
/// an admin typo must never crash or strand the student.
String? actionRoute(BannerAction action, String? target) {
  if (target == null || target.isEmpty) return null;
  return switch (action) {
    BannerAction.subject => '${Routes.subjects}/$target',
    BannerAction.teacher => '${Routes.teachers}/$target',
    BannerAction.teacherTrack => '${Routes.tracks}/$target',
    BannerAction.quiz => '${Routes.quizzes}/$target',
    BannerAction.deck => '${Routes.decks}/$target',
    BannerAction.internalRoute => target.startsWith('/') && !target.startsWith('//') ? target : null,
    _ => null,
  };
}

Future<void> openAction(BuildContext context, WidgetRef ref, BannerAction action, String? target) async {
  if (action == BannerAction.externalUrl) {
    final uri = Uri.tryParse(target ?? '');
    if (uri != null && uri.scheme == 'https') await ref.read(externalUrlLauncherProvider)(uri);
    return;
  }
  final route = actionRoute(action, target);
  if (route != null && context.mounted) context.go(route);
}

/// "باقي 87 يوماً على امتحان …" with Arabic number agreement.
String countdownText(ExamCountdown c) {
  final n = c.daysLeft;
  final days = switch (n) {
    1 => 'يوم واحد',
    2 => 'يومان',
    >= 3 && <= 10 => '$n أيام',
    _ => '$n يوماً',
  };
  return n <= 0 ? 'اليوم موعد ${c.titleAr}، بالتوفيق!' : 'باقي $days على ${c.titleAr}';
}

/// "٦ أسئلة", "١٥ سؤالاً": Arabic counted nouns.
String countedQuestions(int n) => switch (n) {
  1 => 'سؤال واحد',
  2 => 'سؤالان',
  >= 3 && <= 10 => '$n أسئلة',
  _ => '$n سؤالاً',
};

String streakText(int n) => switch (n) {
  0 => 'لا سلسلة بعد',
  1 => 'يوم واحد متتالٍ',
  2 => 'يومان متتاليان',
  >= 3 && <= 10 => '$n أيام متتالية',
  _ => '$n يوماً متتالياً',
};
