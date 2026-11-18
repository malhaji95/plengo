// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/admin_diagram_envelope.dart';
import '../models/admin_diagram_page_envelope.dart';
import '../models/create_diagram_request.dart';
import '../models/deleted_result_envelope.dart';
import '../models/diagram_import_request.dart';
import '../models/diagram_import_result_envelope.dart';
import '../models/general_only.dart';
import '../models/import_format.dart';
import '../models/question_free_request.dart';
import '../models/question_status_request.dart';
import '../models/status.dart';
import '../models/update_diagram_request.dart';

part 'admin_diagrams_client.g.dart';

@RestApi()
abstract class AdminDiagramsClient {
  factory AdminDiagramsClient(Dio dio, {String? baseUrl}) = _AdminDiagramsClient;

  @GET('/api/v1/admin/diagrams')
  Future<AdminDiagramPageEnvelope> adminListDiagrams({
    @Query('limit') int? limit = 50,
    @Query('subjectId') String? subjectId,
    @Query('teacherTrackId') String? teacherTrackId,
    @Query('generalOnly') GeneralOnly? generalOnly,
    @Query('unitId') String? unitId,
    @Query('lessonId') String? lessonId,
    @Query('status') Status? status,
    @Query('q') String? q,
    @Query('cursor') String? cursor,
  });

  @POST('/api/v1/admin/diagrams')
  Future<AdminDiagramEnvelope> adminCreateDiagram({
    @Body() required CreateDiagramRequest body,
  });

  /// The diagram import layout with example rows, as CSV or XLSX.
  @GET('/api/v1/admin/diagrams/import/template')
  Future<void> adminDiagramImportTemplate({
    @Query('format') required ImportFormat format,
  });

  /// One row per label (diagram_ref groups rows). A dry run validates and lists the image files needed; the real run creates every diagram in one transaction, or nothing when any row has an error.
  @POST('/api/v1/admin/diagrams/import')
  Future<DiagramImportResultEnvelope> adminImportDiagrams({
    @Body() required DiagramImportRequest body,
  });

  @GET('/api/v1/admin/diagrams/{id}')
  Future<AdminDiagramEnvelope> adminGetDiagram({
    @Path('id') required String id,
  });

  @PATCH('/api/v1/admin/diagrams/{id}')
  Future<AdminDiagramEnvelope> adminUpdateDiagram({
    @Path('id') required String id,
    @Body() required UpdateDiagramRequest body,
  });

  @DELETE('/api/v1/admin/diagrams/{id}')
  Future<DeletedResultEnvelope> adminDeleteDiagram({
    @Path('id') required String id,
  });

  @POST('/api/v1/admin/diagrams/{id}/status')
  Future<AdminDiagramEnvelope> adminSetDiagramStatus({
    @Path('id') required String id,
    @Body() required QuestionStatusRequest body,
  });

  @PUT('/api/v1/admin/diagrams/{id}/free')
  Future<AdminDiagramEnvelope> adminSetDiagramFree({
    @Path('id') required String id,
    @Body() required QuestionFreeRequest body,
  });
}
