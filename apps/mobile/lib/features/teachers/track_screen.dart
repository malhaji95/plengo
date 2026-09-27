import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/network_avatar.dart';
import '../access/access_banner.dart';
import 'teacher_providers.dart';

/// A teacher track page (spec §7.2, §23.2 #12). Its questions, decks and quizzes arrive with
/// Phases 5–7. A track is its own access scope: a subject entitlement does not open it (§8.1).
class TrackScreen extends ConsumerWidget {
  const TrackScreen({super.key, required this.trackId});

  final String trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(trackProvider(trackId));
    final text = Theme.of(context).textTheme;
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
                Text(d.track.titleAr, style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                if (d.track.description != null) ...[
                  const SizedBox(height: 8),
                  Text(d.track.description!, style: text.bodyMedium),
                ],
                const SizedBox(height: 16),
                ScopeAccessBanner(access: d.access),
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: NetworkAvatar(url: d.teacher.photoUrl, name: d.teacher.nameAr),
                    title: Text(d.teacher.nameAr),
                    subtitle: const Text('المدرس'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => context.go('${Routes.teachers}/${d.teacher.id}'),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: const Icon(Icons.menu_book_outlined),
                    title: Text(d.subject.nameAr),
                    subtitle: const Text('المادة'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => context.go('${Routes.subjects}/${d.subject.id}'),
                  ),
                ),
                const EmptyState('محتوى هذا المسار قيد الإعداد', icon: Icons.hourglass_empty),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
