// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/create_report_request.dart';
import '../models/report_envelope.dart';
import '../models/report_list_envelope.dart';

part 'reports_client.g.dart';

@RestApi()
abstract class ReportsClient {
  factory ReportsClient(Dio dio, {String? baseUrl}) = _ReportsClient;

  @POST('/api/v1/reports')
  Future<ReportEnvelope> createReport({
    @Body() required CreateReportRequest body,
  });

  @GET('/api/v1/reports')
  Future<ReportListEnvelope> listMyReports();
}
