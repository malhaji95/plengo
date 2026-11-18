// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plengo_deck_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlengoDeckList _$PlengoDeckListFromJson(Map<String, dynamic> json) =>
    PlengoDeckList(
      groups: (json['groups'] as List<dynamic>)
          .map((e) => PlengoDeckGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PlengoDeckListToJson(PlengoDeckList instance) =>
    <String, dynamic>{'groups': instance.groups};
