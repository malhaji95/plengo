// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/create_upload_request.dart';
import '../models/create_upload_result_envelope.dart';
import '../models/media_file_envelope.dart';

part 'uploads_client.g.dart';

@RestApi()
abstract class UploadsClient {
  factory UploadsClient(Dio dio, {String? baseUrl}) = _UploadsClient;

  @POST('/api/v1/uploads')
  Future<CreateUploadResultEnvelope> studentCreateUpload({@Body() required CreateUploadRequest body});

  @POST('/api/v1/uploads/{id}/complete')
  Future<MediaFileEnvelope> studentCompleteUpload({@Path('id') required String id});

  @GET('/api/v1/uploads/{id}')
  Future<MediaFileEnvelope> studentGetUpload({@Path('id') required String id});
}
