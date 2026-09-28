// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'store_urls.g.dart';

@JsonSerializable()
class StoreUrls {
  const StoreUrls({required this.android, required this.ios});

  factory StoreUrls.fromJson(Map<String, Object?> json) => _$StoreUrlsFromJson(json);

  final String android;
  final String ios;

  Map<String, Object?> toJson() => _$StoreUrlsToJson(this);
}
