// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'bookmark_key_list.dart';

part 'bookmark_key_list_envelope.g.dart';

@JsonSerializable()
class BookmarkKeyListEnvelope {
  const BookmarkKeyListEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory BookmarkKeyListEnvelope.fromJson(Map<String, Object?> json) => _$BookmarkKeyListEnvelopeFromJson(json);
  
  final bool success;
  final BookmarkKeyList data;
  final dynamic error;

  Map<String, Object?> toJson() => _$BookmarkKeyListEnvelopeToJson(this);
}
