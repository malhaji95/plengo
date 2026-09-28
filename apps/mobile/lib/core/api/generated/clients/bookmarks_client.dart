// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/bookmark_envelope.dart';
import '../models/bookmark_item_type.dart';
import '../models/bookmark_key_list_envelope.dart';
import '../models/bookmark_list_envelope.dart';
import '../models/bookmark_request.dart';
import '../models/deleted_result_envelope.dart';

part 'bookmarks_client.g.dart';

@RestApi()
abstract class BookmarksClient {
  factory BookmarksClient(Dio dio, {String? baseUrl}) = _BookmarksClient;

  @GET('/api/v1/bookmarks')
  Future<BookmarkListEnvelope> listBookmarks({
    @Query('itemType') BookmarkItemType? itemType,
  });

  @PUT('/api/v1/bookmarks')
  Future<BookmarkEnvelope> addBookmark({
    @Body() required BookmarkRequest body,
  });

  @GET('/api/v1/bookmarks/keys')
  Future<BookmarkKeyListEnvelope> listBookmarkKeys();

  @DELETE('/api/v1/bookmarks/{itemType}/{itemId}')
  Future<DeletedResultEnvelope> removeBookmark({
    @Path('itemType') required BookmarkItemType itemType,
    @Path('itemId') required String itemId,
  });
}
