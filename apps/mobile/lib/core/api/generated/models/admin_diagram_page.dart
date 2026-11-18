// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'admin_diagram.dart';

part 'admin_diagram_page.g.dart';

@JsonSerializable()
class AdminDiagramPage {
  const AdminDiagramPage({
    required this.items,
    required this.nextCursor,
    required this.totalCount,
  });
  
  factory AdminDiagramPage.fromJson(Map<String, Object?> json) => _$AdminDiagramPageFromJson(json);
  
  final List<AdminDiagram> items;
  @JsonKey(includeIfNull: true)
  final String? nextCursor;
  final int totalCount;

  Map<String, Object?> toJson() => _$AdminDiagramPageToJson(this);
}
