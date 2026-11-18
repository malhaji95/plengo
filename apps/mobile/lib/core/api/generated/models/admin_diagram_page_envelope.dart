// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'admin_diagram_page.dart';

part 'admin_diagram_page_envelope.g.dart';

@JsonSerializable()
class AdminDiagramPageEnvelope {
  const AdminDiagramPageEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory AdminDiagramPageEnvelope.fromJson(Map<String, Object?> json) => _$AdminDiagramPageEnvelopeFromJson(json);
  
  final bool success;
  final AdminDiagramPage data;
  final dynamic error;

  Map<String, Object?> toJson() => _$AdminDiagramPageEnvelopeToJson(this);
}
