import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../subjects/scope_widgets.dart';
import 'teacher_avatar.dart';
import 'teacher_providers.dart';

/// A teacher's profile with follow button and tracks (spec §7, §23.2 #12).
class TeacherScreen extends ConsumerWidget {
  const TeacherScreen({super.key, required this.teacherId});

  final String teacherId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(teacherProfileProvider(teacherId));
    final s = context.surface;
    return Scaffold(
      appBar: AppBar(leading: const PlengoBackButton(), leadingWidth: kPlengoLeadingWidth),
      body: AsyncView(
        value: profile,
        onRetry: () => ref.invalidate(teacherProfileProvider(teacherId)),
        data: (p) => ContentWidthBox(
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 0, PlengoSpace.screen, 28),
            children: [
              _Header(teacher: p.teacher),
              if (p.teacher.bio != null) ...[
                const SizedBox(height: PlengoSpace.section),
                PlengoCard(
                  child: Text(p.teacher.bio!, style: PlengoType.sub.copyWith(color: s.ink)),
                ),
              ],
              const SectionHeader('المسارات'),
              if (p.tracks.isEmpty)
                const PlengoEmptyState(
                  title: 'لا توجد مسارات منشورة لهذا المدرس بعد',
                  icon: Icons.route_outlined,
                  hue: PlengoColors.pink,
                ),
              for (final track in p.tracks)
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: PlengoSpace.listGap),
                  child: ListRow(
                    leading: SubjectIconTile.forSubject(track.subjectId, icon: Icons.route_rounded),
                    title: track.titleAr,
                    caption: track.subjectNameAr,
                    onTap: () => context.go('${Routes.tracks}/${track.id}'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerStatefulWidget {
  const _Header({required this.teacher});

  final TeacherDetail teacher;

  @override
  ConsumerState<_Header> createState() => _HeaderState();
}

class _HeaderState extends ConsumerState<_Header> {
  bool _busy = false;

  Future<void> _toggle() async {
    setState(() => _busy = true);
    try {
      await setFollowing(ref, widget.teacher.id, !widget.teacher.isFollowing);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.teacher;
    final canFollow = ref.watch(teacherFollowingEnabledProvider);
    final pink = PlengoColors.pink;
    return PlengoCard(
      color: pink.soft,
      radius: PlengoRadius.hero,
      padding: const EdgeInsetsDirectional.all(PlengoSpace.heroPadding),
      child: Column(
        children: [
          TeacherAvatar(url: t.photoUrl, name: t.nameAr, radius: 44),
          const SizedBox(height: 12),
          Semantics(
            header: true,
            child: Text(
              t.nameAr,
              textAlign: TextAlign.center,
              style: PlengoType.section.copyWith(color: PlengoColors.ink, fontSize: 22),
            ),
          ),
          if (t.shortDescription != null) ...[
            const SizedBox(height: 2),
            Text(
              t.shortDescription!,
              textAlign: TextAlign.center,
              style: PlengoType.sub.copyWith(color: PlengoColors.ink),
            ),
          ],
          const SizedBox(height: 8),
          PlengoChip(
            label: followersLabel(t.followerCount),
            hue: pink,
            background: Colors.white,
            icon: Icons.people_alt_rounded,
          ),
          if (canFollow) ...[
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 200),
              child: t.isFollowing
                  ? PlengoButton(
                      key: const Key('teacher.unfollow'),
                      label: 'تتابعه',
                      icon: Icons.check_rounded,
                      variant: PlengoButtonVariant.secondary,
                      expand: false,
                      onPressed: _busy ? null : _toggle,
                    )
                  : PlengoButton(
                      key: const Key('teacher.follow'),
                      label: 'متابعة',
                      icon: Icons.add_rounded,
                      expand: false,
                      onPressed: _busy ? null : _toggle,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              'المتابعة تبقيك على اطلاع بجديد المدرس، ولا تفتح المحتوى',
              textAlign: TextAlign.center,
              style: PlengoType.caption.copyWith(color: pink.ink),
            ),
          ],
        ],
      ),
    );
  }
}

/// Arabic count agreement for followers.
String followersLabel(num n) => switch (n) {
  0 => 'لا متابعين بعد',
  1 => 'متابع واحد',
  2 => 'متابعان',
  >= 3 && <= 10 => '$n متابعين',
  _ => '$n متابعاً',
};
