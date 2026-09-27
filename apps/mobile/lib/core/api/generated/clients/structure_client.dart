// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/education_level_list_envelope.dart';

part 'structure_client.g.dart';

@RestApi()
abstract class StructureClient {
  factory StructureClient(Dio dio, {String? baseUrl}) = _StructureClient;

  @GET('/api/v1/levels')
  Future<EducationLevelListEnvelope> listLevels();
}
