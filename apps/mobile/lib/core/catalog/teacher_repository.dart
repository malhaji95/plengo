import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/generated/export.dart';

/// Teachers, their tracks and following (spec §7). Following never grants access.
class TeacherRepository {
  TeacherRepository(this.client);

  final ApiClient client;

  Future<List<Teacher>> teachers() => guardApi(() async => (await client.api.teachers.listTeachers()).data);

  Future<List<Teacher>> followed() => guardApi(() async => (await client.api.teachers.listFollowedTeachers()).data);

  Future<TeacherProfile> profile(String id) =>
      guardApi(() async => (await client.api.teachers.getTeacherProfile(id: id)).data);

  Future<TrackDetail> track(String id) => guardApi(() async => (await client.api.teachers.getTrack(id: id)).data);

  Future<FollowResult> setFollowing(String teacherId, bool following) => guardApi(
    () async =>
        (following
                ? await client.api.teachers.followTeacher(id: teacherId)
                : await client.api.teachers.unfollowTeacher(id: teacherId))
            .data,
  );
}
