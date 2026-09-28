import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/network_avatar.dart';
import 'teacher_providers.dart';
import '../../shared/widgets/responsive.dart';

/// All teachers (spec §23.2 #12).
class TeachersScreen extends ConsumerWidget {
  const TeachersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachers = ref.watch(teachersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('المدرسون')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(teachersProvider.future),
        child: AsyncView(
          value: teachers,
          onRetry: () => ref.invalidate(teachersProvider),
          data: (items) => TeacherList(teachers: items, empty: 'لا يوجد مدرسون بعد'),
        ),
      ),
    );
  }
}

/// Teachers the student follows (spec §23.2 #13).
class FollowedTeachersScreen extends ConsumerWidget {
  const FollowedTeachersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachers = ref.watch(followedTeachersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('المدرسون الذين أتابعهم')),
      body: AsyncView(
        value: teachers,
        onRetry: () => ref.invalidate(followedTeachersProvider),
        data: (items) => TeacherList(teachers: items, empty: 'لا تتابع أي مدرس بعد'),
      ),
    );
  }
}

class TeacherList extends StatelessWidget {
  const TeacherList({super.key, required this.teachers, required this.empty});

  final List<Teacher> teachers;
  final String empty;

  @override
  Widget build(BuildContext context) {
    if (teachers.isEmpty) return ListView(children: [EmptyState(empty, icon: Icons.person_search_outlined)]);
    return ResponsiveList(
      itemCount: teachers.length,
      itemBuilder: (context, i) {
        final t = teachers[i];
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: NetworkAvatar(url: t.photoUrl, name: t.nameAr),
            title: Text(t.nameAr, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: t.shortDescription == null ? null : Text(t.shortDescription!),
            trailing: t.isFollowing
                ? Icon(Icons.notifications_active_outlined, color: Theme.of(context).colorScheme.primary)
                : const Icon(Icons.chevron_left),
            onTap: () => context.go('${Routes.teachers}/${t.id}'),
          ),
        );
      },
    );
  }
}
