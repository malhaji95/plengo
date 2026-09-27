import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/generated/export.dart';

/// Which subjects to list: a level plus an optional college filter (spec §6, §8.9).
typedef SubjectQuery = ({String levelId, String? universityId, String? facultyId, String? academicYearId});

/// A student's placement: level plus the optional University → Faculty → Year layers.
typedef Placement = ({String levelId, String? universityId, String? facultyId, String? academicYearId});

/// Read access to the education structure, and the student's own placement.
class CatalogRepository {
  CatalogRepository(this.client);

  final ApiClient client;

  Future<List<EducationLevel>> levels() => guardApi(() async => (await client.api.structure.listLevels()).data);

  Future<List<University>> universities() =>
      guardApi(() async => (await client.api.structure.listUniversities()).data);

  Future<List<Faculty>> faculties(String universityId) =>
      guardApi(() async => (await client.api.structure.listFaculties(universityId: universityId)).data);

  Future<List<AcademicYear>> academicYears(String facultyId) =>
      guardApi(() async => (await client.api.structure.listAcademicYears(facultyId: facultyId)).data);

  Future<List<Subject>> subjects(SubjectQuery q) => guardApi(
        () async => (await client.api.structure.listSubjects(
          levelId: q.levelId,
          universityId: q.universityId,
          facultyId: q.facultyId,
          academicYearId: q.academicYearId,
        ))
            .data,
      );

  Future<SubjectOutline> outline(String subjectId) =>
      guardApi(() async => (await client.api.structure.getSubjectOutline(id: subjectId)).data);

  /// Sends the whole placement; layers left null are cleared on the server.
  Future<Me> updatePlacement(Placement p) => guardApi(
        () async => (await client.api.me.updateMe(
          body: UpdateProfileRequest(
            educationLevelId: p.levelId,
            // Only the deepest chosen layer is needed; the API derives the ones above it.
            academicYearId: p.academicYearId,
            facultyId: p.academicYearId == null ? p.facultyId : null,
            universityId: p.academicYearId == null && p.facultyId == null ? p.universityId : null,
          ),
        ))
            .data,
      );
}
