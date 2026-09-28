// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refresh_leases_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RefreshLeasesRequest _$RefreshLeasesRequestFromJson(
  Map<String, dynamic> json,
) => RefreshLeasesRequest(
  scopes: (json['scopes'] as List<dynamic>)
      .map((e) => Scopes2.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$RefreshLeasesRequestToJson(
  RefreshLeasesRequest instance,
) => <String, dynamic>{'scopes': instance.scopes};
