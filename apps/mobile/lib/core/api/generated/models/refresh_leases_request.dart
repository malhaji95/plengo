// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'lease_scope.dart';

part 'refresh_leases_request.g.dart';

@JsonSerializable()
class RefreshLeasesRequest {
  const RefreshLeasesRequest({
    required this.scopes,
  });
  
  factory RefreshLeasesRequest.fromJson(Map<String, Object?> json) => _$RefreshLeasesRequestFromJson(json);
  
  final List<LeaseScope> scopes;

  Map<String, Object?> toJson() => _$RefreshLeasesRequestToJson(this);
}
