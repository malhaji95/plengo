// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'features.dart';
import 'latest_version.dart';
import 'min_supported_version.dart';
import 'srs_defaults.dart';
import 'store_urls.dart';
import 'support.dart';

part 'remote_config.g.dart';

@JsonSerializable()
class RemoteConfig {
  const RemoteConfig({
    required this.minSupportedVersion,
    required this.latestVersion,
    required this.features,
    required this.srsDefaults,
    required this.support,
    required this.storeUrls,
    required this.privacyPolicyUrl,
    required this.termsUrl,
  });

  factory RemoteConfig.fromJson(Map<String, Object?> json) => _$RemoteConfigFromJson(json);

  final MinSupportedVersion minSupportedVersion;
  final LatestVersion latestVersion;
  final Features features;
  final SrsDefaults srsDefaults;
  final Support support;
  final StoreUrls storeUrls;
  final String privacyPolicyUrl;
  final String termsUrl;

  Map<String, Object?> toJson() => _$RemoteConfigToJson(this);
}
