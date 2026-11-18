// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'admin_diagram.dart';

part 'admin_diagram_envelope.g.dart';

@JsonSerializable()
class AdminDiagramEnvelope {
  const AdminDiagramEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory AdminDiagramEnvelope.fromJson(Map<String, Object?> json) => _$AdminDiagramEnvelopeFromJson(json);
  
  final bool success;
  final AdminDiagram data;
  final dynamic error;

  Map<String, Object?> toJson() => _$AdminDiagramEnvelopeToJson(this);
}
