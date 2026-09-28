// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'bookmark_list.dart';

part 'bookmark_list_envelope.g.dart';

@JsonSerializable()
class BookmarkListEnvelope {
  const BookmarkListEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory BookmarkListEnvelope.fromJson(Map<String, Object?> json) => _$BookmarkListEnvelopeFromJson(json);
  
  final bool success;
  final BookmarkList data;
  final dynamic error;

  Map<String, Object?> toJson() => _$BookmarkListEnvelopeToJson(this);
}
