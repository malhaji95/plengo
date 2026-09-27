// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/academic_year_list_envelope.dart';
import '../models/education_level_list_envelope.dart';
import '../models/faculty_list_envelope.dart';
import '../models/lesson_envelope.dart';
import '../models/subject_list_envelope.dart';
import '../models/subject_outline_envelope.dart';
import '../models/unit_with_lessons_envelope.dart';
import '../models/university_list_envelope.dart';

part 'structure_client.g.dart';

@RestApi()
abstract class StructureClient {
  factory StructureClient(Dio dio, {String? baseUrl}) = _StructureClient;

  @GET('/api/v1/levels')
  Future<EducationLevelListEnvelope> listLevels();

  @GET('/api/v1/universities')
  Future<UniversityListEnvelope> listUniversities();

  @GET('/api/v1/faculties')
  Future<FacultyListEnvelope> listFaculties({
    @Query('universityId') required String universityId,
  });

  @GET('/api/v1/academic-years')
  Future<AcademicYearListEnvelope> listAcademicYears({
    @Query('facultyId') required String facultyId,
  });

  @GET('/api/v1/subjects')
  Future<SubjectListEnvelope> listSubjects({
    @Query('levelId') String? levelId,
    @Query('universityId') String? universityId,
    @Query('facultyId') String? facultyId,
    @Query('academicYearId') String? academicYearId,
  });

  @GET('/api/v1/subjects/{id}')
  Future<SubjectOutlineEnvelope> getSubjectOutline({
    @Path('id') required String id,
  });

  @GET('/api/v1/units/{id}')
  Future<UnitWithLessonsEnvelope> getUnit({
    @Path('id') required String id,
  });

  @GET('/api/v1/lessons/{id}')
  Future<LessonEnvelope> getLesson({
    @Path('id') required String id,
  });
}
