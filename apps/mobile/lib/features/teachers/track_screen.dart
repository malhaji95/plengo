import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../access/access_banner.dart';
import '../offline/download_widgets.dart';
import '../offline/offline_providers.dart';
import '../subjects/scope_widgets.dart';
import 'teacher_avatar.dart';
import 'teacher_providers.dart';

/// A teacher track page (spec §7.2, §23.2 #12), in the subject page's style: blue header with
/// progress, access state, teacher and subject links, the shortcuts and the download tile. A track
/// is its own access scope: a subject entitlement does not open it (§8.1).
class TrackScreen extends ConsumerStatefulWidget {
  const TrackScreen({super.key, required this.trackId});

  final String trackId;

  @override
  ConsumerState<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends ConsumerState<TrackScreen> {
  final _downloadKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(trackProvider(widget.trackId));
    if (!detail.hasValue) {
      return Scaffold(
        appBar: AppBar(leading: const PlengoBackButton(), leadingWidth: kPlengoLeadingWidth),
        body: AsyncView(
          value: detail,
          onRetry: () => ref.invalidate(trackProvider(widget.trackId)),
          data: (_) => const SizedBox.shrink(),
        ),
      );
    }
    final d = detail.requireValue;
    final canDownload = ref.watch(offlinePacksAvailableProvider);
    return ScopePage(
      header: ScopeHeader(
        title: d.track.titleAr,
        subtitle: d.track.description ?? '${d.teacher.nameAr} · ${d.subject.nameAr}',
        subjectId: d.subject.id,
        teacherTrackId: d.track.id,
        downloadLabel: 'تحميل المسار للاستخدام دون اتصال',
        onDownload: canDownload
            ? () {
                final target = _downloadKey.currentContext;
                if (target != null) Scrollable.ensureVisible(target, alignment: 0.3);
              }
            : null,
      ),
      children: [
        ScopeAccessBanner(access: d.access, subjectId: d.subject.id, teacherTrackId: d.track.id),
        ListRow(
          leading: TeacherAvatar(url: d.teacher.photoUrl, name: d.teacher.nameAr, radius: 20),
          title: d.teacher.nameAr,
          caption: 'المدرس',
          onTap: () => context.go('${Routes.teachers}/${d.teacher.id}'),
        ),
        const SizedBox(height: PlengoSpace.listGap),
        ListRow(
          leading: SubjectIconTile.forSubject(d.subject.id, icon: Icons.menu_book_rounded),
          title: d.subject.nameAr,
          caption: 'المادة',
          onTap: () => context.go('${Routes.subjects}/${d.subject.id}'),
        ),
        const SizedBox(height: PlengoSpace.section),
        ScopeShortcuts(
          subjectId: d.subject.id,
          teacherTrackId: d.track.id,
          quizCount: d.quizCount,
          questionCount: d.questionCount,
          deckCount: d.deckCount,
          quizzesPath: '${Routes.tracks}/${d.track.id}/quizzes',
          decksPath: '${Routes.tracks}/${d.track.id}/decks',
          decksLabel: 'بطاقات المسار',
          questionsPath: '${Routes.tracks}/${d.track.id}/questions',
          questionsLabel: 'أسئلة المسار',
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: _downloadKey,
          child: OfflineDownloadTile(
            scope: (subjectId: d.subject.id, teacherTrackId: d.track.id),
            label: 'تحميل الكل',
            doneLabel: 'المسار محمّل',
          ),
        ),
        if (d.deckCount.total == 0 && d.quizCount.total == 0 && d.questionCount.total == 0)
          const PlengoEmptyState(title: 'محتوى هذا المسار قيد الإعداد', icon: Icons.hourglass_empty),
      ],
    );
  }
}
