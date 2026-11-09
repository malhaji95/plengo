// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'srs_states_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SrsStatesPage _$SrsStatesPageFromJson(Map<String, dynamic> json) =>
    SrsStatesPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => SrsCardState.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
    );

Map<String, dynamic> _$SrsStatesPageToJson(SrsStatesPage instance) =>
    <String, dynamic>{
      'items': instance.items,
      'nextCursor': instance.nextCursor,
    };
