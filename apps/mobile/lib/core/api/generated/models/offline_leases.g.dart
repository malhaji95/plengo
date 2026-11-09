// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_leases.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineLeases _$OfflineLeasesFromJson(Map<String, dynamic> json) =>
    OfflineLeases(
      serverTime: json['serverTime'] as String,
      leases: (json['leases'] as List<dynamic>)
          .map((e) => OfflineLease.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OfflineLeasesToJson(OfflineLeases instance) =>
    <String, dynamic>{
      'serverTime': instance.serverTime,
      'leases': instance.leases,
    };
