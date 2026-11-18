// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/check_diagram_request.dart';
import '../models/diagram_check_result_envelope.dart';
import '../models/diagram_practice_envelope.dart';
import '../models/diagram_practice_request.dart';
import '../models/student_diagram_list_envelope.dart';

part 'diagrams_client.g.dart';

@RestApi()
abstract class DiagramsClient {
  factory DiagramsClient(Dio dio, {String? baseUrl}) = _DiagramsClient;

  /// Published diagrams of a scope: the subject (general content or a track), a unit with its lessons, or some lessons. Locked ones are listed with `locked: true` and no content.
  @GET('/api/v1/diagrams')
  Future<StudentDiagramListEnvelope> listDiagrams({
    @Query('subjectId') required String subjectId,
    @Query('teacherTrackId') String? teacherTrackId,
    @Query('unitId') String? unitId,
    @Query('lessonIds') String? lessonIds,
  });

  /// Up to `count` random accessible diagrams of the scope with signed image URLs and their labels (numbers and marker positions, never answers).
  @POST('/api/v1/diagrams/practice')
  Future<DiagramPracticeEnvelope> startDiagramPractice({
    @Body() required DiagramPracticeRequest body,
  });

  /// Grades the typed names (normalised like written answers) and reveals every label’s accepted answers. Counts toward the daily goal.
  @POST('/api/v1/diagrams/{id}/check')
  Future<DiagramCheckResultEnvelope> checkDiagram({
    @Path('id') required String id,
    @Body() required CheckDiagramRequest body,
  });
}
