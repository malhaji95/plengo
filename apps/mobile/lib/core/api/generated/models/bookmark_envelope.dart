// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'bookmark.dart';

part 'bookmark_envelope.g.dart';

@JsonSerializable()
class BookmarkEnvelope {
  const BookmarkEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory BookmarkEnvelope.fromJson(Map<String, Object?> json) => _$BookmarkEnvelopeFromJson(json);
  
  final bool success;
  final Bookmark data;
  final dynamic error;

  Map<String, Object?> toJson() => _$BookmarkEnvelopeToJson(this);
}
