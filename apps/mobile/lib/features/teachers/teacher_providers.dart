import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/generated/export.dart';
import '../../core/catalog/teacher_repository.dart';

final teacherRepositoryProvider = Provider<TeacherRepository>((ref) => TeacherRepository(ref.watch(apiClientProvider)));

final teachersProvider = FutureProvider.autoDispose<List<Teacher>>(
  (ref) => ref.watch(teacherRepositoryProvider).teachers(),
);

final followedTeachersProvider = FutureProvider.autoDispose<List<Teacher>>(
  (ref) => ref.watch(teacherRepositoryProvider).followed(),
);

final teacherProfileProvider = FutureProvider.autoDispose.family<TeacherProfile, String>(
  (ref, id) => ref.watch(teacherRepositoryProvider).profile(id),
);

final trackProvider = FutureProvider.autoDispose.family<TrackDetail, String>(
  (ref, id) => ref.watch(teacherRepositoryProvider).track(id),
);

/// Follow/unfollow, then refresh every view that shows following state.
Future<void> setFollowing(WidgetRef ref, String teacherId, bool following) async {
  await ref.read(teacherRepositoryProvider).setFollowing(teacherId, following);
  ref
    ..invalidate(teacherProfileProvider(teacherId))
    ..invalidate(teachersProvider)
    ..invalidate(followedTeachersProvider);
}

/// Remote flag (spec §10.2): the follow feature can be hidden without an app update.
final teacherFollowingEnabledProvider = Provider<bool>(
  (ref) => ref.watch(remoteConfigProvider).value?.features.teacherFollowing ?? true,
);
