// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'clients/config_client.dart';
import 'clients/structure_client.dart';
import 'clients/auth_client.dart';
import 'clients/me_client.dart';
import 'clients/sessions_client.dart';
import 'clients/uploads_client.dart';
import 'clients/teachers_client.dart';
import 'clients/access_client.dart';

/// Plengo API `v1.0.0`
class PlengoApi {
  PlengoApi(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '1.0.0';

  ConfigClient? _config;
  StructureClient? _structure;
  AuthClient? _auth;
  MeClient? _me;
  SessionsClient? _sessions;
  UploadsClient? _uploads;
  TeachersClient? _teachers;
  AccessClient? _access;

  ConfigClient get config => _config ??= ConfigClient(_dio, baseUrl: _baseUrl);

  StructureClient get structure => _structure ??= StructureClient(_dio, baseUrl: _baseUrl);

  AuthClient get auth => _auth ??= AuthClient(_dio, baseUrl: _baseUrl);

  MeClient get me => _me ??= MeClient(_dio, baseUrl: _baseUrl);

  SessionsClient get sessions => _sessions ??= SessionsClient(_dio, baseUrl: _baseUrl);

  UploadsClient get uploads => _uploads ??= UploadsClient(_dio, baseUrl: _baseUrl);

  TeachersClient get teachers => _teachers ??= TeachersClient(_dio, baseUrl: _baseUrl);

  AccessClient get access => _access ??= AccessClient(_dio, baseUrl: _baseUrl);
}
