import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/network_avatar.dart';
import 'teacher_providers.dart';

/// A teacher's profile with follow button and tracks (spec §7, §23.2 #12).
class TeacherScreen extends ConsumerWidget {
  const TeacherScreen({super.key, required this.teacherId});

  final String teacherId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(teacherProfileProvider(teacherId));
    return Scaffold(
      appBar: AppBar(title: Text(profile.value?.teacher.nameAr ?? '')),
      body: AsyncView(
        value: profile,
        onRetry: () => ref.invalidate(teacherProfileProvider(teacherId)),
        data: (p) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _Header(teacher: p.teacher),
                if (p.teacher.bio != null) ...[
                  const SizedBox(height: 16),
                  Text(p.teacher.bio!, style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: 24),
                Text('المسارات', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (p.tracks.isEmpty) const EmptyState('لا توجد مسارات منشورة لهذا المدرس بعد'),
                for (final track in p.tracks)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.route_outlined),
                      title: Text(track.titleAr),
                      subtitle: Text(track.subjectNameAr),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () => context.go('${Routes.tracks}/${track.id}'),
                    ),
                  ),
              ],
            ),
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
    final text = Theme.of(context).textTheme;
    final canFollow = ref.watch(teacherFollowingEnabledProvider);
    return Column(
      children: [
        NetworkAvatar(url: t.photoUrl, name: t.nameAr, radius: 48),
        const SizedBox(height: 12),
        Text(t.nameAr, style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        if (t.shortDescription != null) ...[
          const SizedBox(height: 4),
          Text(t.shortDescription!, textAlign: TextAlign.center, style: text.bodyMedium),
        ],
        const SizedBox(height: 8),
        Text(followersLabel(t.followerCount), style: text.bodySmall),
        if (canFollow) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: 200,
            child: t.isFollowing
                ? OutlinedButton.icon(
                    key: const Key('teacher.unfollow'),
                    onPressed: _busy ? null : _toggle,
                    icon: const Icon(Icons.check),
                    label: const Text('تتابعه'),
                  )
                : FilledButton.icon(
                    key: const Key('teacher.follow'),
                    onPressed: _busy ? null : _toggle,
                    icon: const Icon(Icons.add),
                    label: const Text('متابعة'),
                  ),
          ),
          const SizedBox(height: 4),
          Text('المتابعة تبقيك على اطلاع بجديد المدرس، ولا تفتح المحتوى', style: text.bodySmall),
        ],
      ],
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
