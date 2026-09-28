// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/my_entitlement_list_envelope.dart';
import '../models/redeem_coupon_request.dart';
import '../models/redeem_result_envelope.dart';

part 'access_client.g.dart';

@RestApi()
abstract class AccessClient {
  factory AccessClient(Dio dio, {String? baseUrl}) = _AccessClient;

  @GET('/api/v1/access')
  Future<MyEntitlementListEnvelope> listMyEntitlements();

  @POST('/api/v1/coupons/redeem')
  Future<RedeemResultEnvelope> redeemCoupon({@Body() required RedeemCouponRequest body});
}
