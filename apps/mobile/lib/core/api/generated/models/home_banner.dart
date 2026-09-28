// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'banner_action.dart';

part 'home_banner.g.dart';

@JsonSerializable()
class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.titleAr,
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.action,
    required this.actionTarget,
  });

  factory HomeBanner.fromJson(Map<String, Object?> json) => _$HomeBannerFromJson(json);

  final String id;
  final String titleAr;
  final String imageUrl;
  @JsonKey(includeIfNull: true)
  final int? width;
  @JsonKey(includeIfNull: true)
  final int? height;
  final BannerAction action;
  @JsonKey(includeIfNull: true)
  final String? actionTarget;

  Map<String, Object?> toJson() => _$HomeBannerToJson(this);
}
