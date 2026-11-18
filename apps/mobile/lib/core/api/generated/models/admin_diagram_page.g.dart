// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_diagram_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminDiagramPage _$AdminDiagramPageFromJson(Map<String, dynamic> json) =>
    AdminDiagramPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => AdminDiagram.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
      totalCount: (json['totalCount'] as num).toInt(),
    );

Map<String, dynamic> _$AdminDiagramPageToJson(AdminDiagramPage instance) =>
    <String, dynamic>{
      'items': instance.items,
      'nextCursor': instance.nextCursor,
      'totalCount': instance.totalCount,
    };
