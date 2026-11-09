// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/forgot_password_request.dart';
import '../models/mobile_login_request.dart';
import '../models/mobile_logout_request.dart';
import '../models/mobile_refresh_request.dart';
import '../models/register_request.dart';
import '../models/resend_otp_request.dart';
import '../models/reset_password_request.dart';
import '../models/reset_result_envelope.dart';
import '../models/sent_result_envelope.dart';
import '../models/signed_in_result_envelope.dart';
import '../models/signed_out_result_envelope.dart';
import '../models/token_pair_envelope.dart';
import '../models/verification_required_result_envelope.dart';
import '../models/verified_result_envelope.dart';
import '../models/verify_email_request.dart';
import '../models/web_login_request.dart';

part 'auth_client.g.dart';

@RestApi()
abstract class AuthClient {
  factory AuthClient(Dio dio, {String? baseUrl}) = _AuthClient;

  @POST('/api/v1/auth/register')
  Future<VerificationRequiredResultEnvelope> register({
    @Body() required RegisterRequest body,
  });

  @POST('/api/v1/auth/verify-email')
  Future<VerifiedResultEnvelope> verifyEmail({
    @Body() required VerifyEmailRequest body,
  });

  @POST('/api/v1/auth/resend-otp')
  Future<SentResultEnvelope> resendOtp({
    @Body() required ResendOtpRequest body,
  });

  @POST('/api/v1/auth/forgot-password')
  Future<SentResultEnvelope> forgotPassword({
    @Body() required ForgotPasswordRequest body,
  });

  @POST('/api/v1/auth/reset-password')
  Future<ResetResultEnvelope> resetPassword({
    @Body() required ResetPasswordRequest body,
  });

  @POST('/api/v1/auth/mobile/login')
  Future<TokenPairEnvelope> mobileLogin({
    @Body() required MobileLoginRequest body,
  });

  @POST('/api/v1/auth/mobile/refresh')
  Future<TokenPairEnvelope> mobileRefresh({
    @Body() required MobileRefreshRequest body,
  });

  @POST('/api/v1/auth/mobile/logout')
  Future<SignedOutResultEnvelope> mobileLogout({
    @Body() required MobileLogoutRequest body,
  });

  @POST('/api/v1/auth/web/login')
  Future<SignedInResultEnvelope> webLogin({
    @Body() required WebLoginRequest body,
  });

  @POST('/api/v1/auth/web/logout')
  Future<SignedOutResultEnvelope> webLogout();
}
