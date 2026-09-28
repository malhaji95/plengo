// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum MyEntitlementSource {
  @JsonValue('coupon')
  coupon('coupon'),
  @JsonValue('admin_grant')
  adminGrant('admin_grant'),
  @JsonValue('promotion')
  promotion('promotion'),
  @JsonValue('future_purchase')
  futurePurchase('future_purchase');

  const MyEntitlementSource(this.json);

  final String? json;
  String toJson() {
    final value = json;
    if (value == null) {
      throw StateError(
        'Cannot convert enum value with null JSON representation to String. '
        'This usually happens for \$unknown or @JsonValue(null) entries.',
      );
    }
    return value as String;
  }

  @override
  String toString() => json?.toString() ?? super.toString();
}
