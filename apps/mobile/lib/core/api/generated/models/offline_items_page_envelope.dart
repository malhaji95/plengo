// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'offline_items_page.dart';

part 'offline_items_page_envelope.g.dart';

@JsonSerializable()
class OfflineItemsPageEnvelope {
  const OfflineItemsPageEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory OfflineItemsPageEnvelope.fromJson(Map<String, Object?> json) => _$OfflineItemsPageEnvelopeFromJson(json);
  
  final bool success;
  final OfflineItemsPage data;
  final dynamic error;

  Map<String, Object?> toJson() => _$OfflineItemsPageEnvelopeToJson(this);
}
