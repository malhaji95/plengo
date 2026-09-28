// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/offline_catalog_envelope.dart';
import '../models/offline_items_page_envelope.dart';
import '../models/offline_leases_envelope.dart';
import '../models/offline_manifest_envelope.dart';
import '../models/offline_scope_catalog_envelope.dart';
import '../models/offline_sync_request.dart';
import '../models/offline_sync_result_envelope.dart';
import '../models/refresh_leases_request.dart';

part 'offline_client.g.dart';

@RestApi()
abstract class OfflineClient {
  factory OfflineClient(Dio dio, {String? baseUrl}) = _OfflineClient;

  @GET('/api/v1/offline/catalog')
  Future<OfflineCatalogEnvelope> offlineCatalog();

  @GET('/api/v1/offline/catalog/scope')
  Future<OfflineScopeCatalogEnvelope> offlineScopeCatalog({
    @Query('subjectId') required String subjectId,
    @Query('teacherTrackId') String? teacherTrackId,
  });

  @GET('/api/v1/offline/packs/{packKey}/manifest')
  Future<OfflineManifestEnvelope> offlineManifest({@Path('packKey') required String packKey});

  @GET('/api/v1/offline/packs/{packKey}/items')
  Future<OfflineItemsPageEnvelope> offlineItems({
    @Path('packKey') required String packKey,
    @Query('ids') String? ids,
    @Query('cursor') String? cursor,
  });

  @POST('/api/v1/offline/licenses/refresh')
  Future<OfflineLeasesEnvelope> refreshOfflineLicenses({@Body() required RefreshLeasesRequest body});

  @POST('/api/v1/offline/sync')
  Future<OfflineSyncResultEnvelope> syncOffline({@Body() required OfflineSyncRequest body});
}
