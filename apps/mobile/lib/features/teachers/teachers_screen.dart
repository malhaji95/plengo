import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../subjects/scope_widgets.dart';
import 'teacher_avatar.dart';
import 'teacher_providers.dart';

/// All teachers (spec §23.2 #12).
class TeachersScreen extends ConsumerWidget {
  const TeachersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachers = ref.watch(teachersProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const PlengoBackButton(),
        leadingWidth: kPlengoLeadingWidth,
        title: const Text('المدرسون'),
      ),
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
      appBar: AppBar(
        leading: const PlengoBackButton(),
        leadingWidth: kPlengoLeadingWidth,
        title: const Text('المدرسون الذين أتابعهم'),
      ),
      body: AsyncView(
        value: teachers,
        onRetry: () => ref.invalidate(followedTeachersProvider),
        data: (items) => TeacherList(teachers: items, empty: 'لا تتابع أي مدرس بعد'),
      ),
    );
  }
}

/// Teacher rows: photo in a pink ring, name, short description, and «تتابعه» for followed teachers.
class TeacherList extends StatelessWidget {
  const TeacherList({super.key, required this.teachers, required this.empty});

  final List<Teacher> teachers;
  final String empty;

  @override
  Widget build(BuildContext context) {
    if (teachers.isEmpty) {
      return ListView(
        children: [PlengoEmptyState(title: empty, icon: Icons.person_search_outlined, hue: PlengoColors.pink)],
      );
    }
    return ContentWidthBox(
      child: ListView.separated(
        padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 8, PlengoSpace.screen, 28),
        itemCount: teachers.length,
        separatorBuilder: (_, _) => const SizedBox(height: PlengoSpace.listGap),
        itemBuilder: (context, i) {
          final t = teachers[i];
          return ListRow(
            leading: TeacherAvatar(url: t.photoUrl, name: t.nameAr, radius: 22),
            title: t.nameAr,
            caption: t.shortDescription,
            trailing: t.isFollowing
                ? const PlengoChip(label: 'تتابعه', hue: PlengoColors.pink, icon: Icons.notifications_active_rounded)
                : null,
            onTap: () => context.go('${Routes.teachers}/${t.id}'),
          );
        },
      ),
    );
  }
}
