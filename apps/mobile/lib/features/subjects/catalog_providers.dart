import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/generated/export.dart';
import '../../core/catalog/catalog_repository.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.watch(apiClientProvider)),
);

final levelsProvider = FutureProvider<List<EducationLevel>>((ref) => ref.watch(catalogRepositoryProvider).levels());

final universitiesProvider = FutureProvider.autoDispose<List<University>>(
  (ref) => ref.watch(catalogRepositoryProvider).universities(),
);

final facultiesProvider = FutureProvider.autoDispose.family<List<Faculty>, String>(
  (ref, universityId) => ref.watch(catalogRepositoryProvider).faculties(universityId),
);

final academicYearsProvider = FutureProvider.autoDispose.family<List<AcademicYear>, String>(
  (ref, facultyId) => ref.watch(catalogRepositoryProvider).academicYears(facultyId),
);

final subjectsProvider = FutureProvider.autoDispose.family<List<Subject>, SubjectQuery>(
  (ref, query) => ref.watch(catalogRepositoryProvider).subjects(query),
);

final subjectOutlineProvider = FutureProvider.autoDispose.family<SubjectOutline, String>(
  (ref, id) => ref.watch(catalogRepositoryProvider).outline(id),
);
