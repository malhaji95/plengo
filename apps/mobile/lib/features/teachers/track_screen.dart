import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/network_avatar.dart';
import '../access/access_banner.dart';
import '../learning/scope_learning.dart';
import '../../app/theme.dart';
import '../../shared/widgets/ui_kit.dart';
import 'teacher_providers.dart';
import '../offline/download_widgets.dart';

/// A teacher track page (spec §7.2, §23.2 #12). Its questions, decks and quizzes arrive with
/// Phases 5–7. A track is its own access scope: a subject entitlement does not open it (§8.1).
class TrackScreen extends ConsumerWidget {
  const TrackScreen({super.key, required this.trackId});

  final String trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(trackProvider(trackId));
    return Scaffold(
      appBar: AppBar(title: Text(detail.value?.track.titleAr ?? '')),
      body: AsyncView(
        value: detail,
        onRetry: () => ref.invalidate(trackProvider(trackId)),
        data: (d) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                ScopeHero(
                  title: d.track.titleAr,
                  subtitle: d.track.description ?? '${d.teacher.nameAr} · ${d.subject.nameAr}',
                  subjectId: d.subject.id,
                  teacherTrackId: d.track.id,
                ),
                ScopeAccessBanner(access: d.access),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: NetworkAvatar(url: d.teacher.photoUrl, name: d.teacher.nameAr, radius: 22),
                    title: Text(d.teacher.nameAr, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('المدرس'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => context.go('${Routes.teachers}/${d.teacher.id}'),
                  ),
                ),
                NavCard(
                  icon: Icons.menu_book_rounded,
                  tint: BrandColors.tintYellow,
                  title: d.subject.nameAr,
                  subtitle: 'المادة',
                  margin: const EdgeInsets.only(bottom: 16),
                  onTap: () => context.go('${Routes.subjects}/${d.subject.id}'),
                ),
                ScopeLearning(
                  subjectId: d.subject.id,
                  teacherTrackId: d.track.id,
                  quizCount: d.quizCount,
                  questionCount: d.questionCount,
                  quizzesPath: '${Routes.tracks}/${d.track.id}/quizzes',
                  deckCount: d.deckCount,
                  decksPath: '${Routes.tracks}/${d.track.id}/decks',
                  decksLabel: 'بطاقات المسار',
                  questionsPath: '${Routes.tracks}/${d.track.id}/questions',
                  questionsLabel: 'أسئلة المسار',
                ),
                OfflineDownloadTile(scope: (subjectId: d.subject.id, teacherTrackId: d.track.id), label: 'تحميل الكل'),
                if (d.deckCount.total == 0 && d.quizCount.total == 0 && d.questionCount.total == 0)
                  const EmptyState('محتوى هذا المسار قيد الإعداد', icon: Icons.hourglass_empty),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
