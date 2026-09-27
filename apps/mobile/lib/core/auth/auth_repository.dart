import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/generated/export.dart';
import 'token_store.dart';

/// Email + password authentication (spec §11.1). Mobile holds a token pair; web relies on the
/// API's httpOnly cookie and never sees a token.
class AuthRepository {
  AuthRepository({required this.client, required this.platform});

  final ApiClient client;

  /// 'android' | 'ios' | 'web'
  final String platform;

  bool get _web => client.useCookies;

  Future<Me?> restoreSession() async {
    if (!_web && await client.tokens.read() == null) return null;
    try {
      return await currentUser();
    } on ApiException catch (e) {
      if (e.isUnauthenticated || e.code == 'NOT_AUTHORIZED') {
        await client.tokens.clear();
        return null;
      }
      rethrow;
    }
  }

  Future<Me> currentUser() => guardApi(() async => (await client.api.me.getMe()).data);

  Future<Me> login({required String email, required String password, String? appVersion}) async {
    await guardApi(() async {
      if (_web) {
        await client.api.auth.webLogin(body: WebLoginRequest(email: email, password: password));
      } else {
        final res = await client.api.auth.mobileLogin(
          body: MobileLoginRequest(
            email: email,
            password: password,
            platform: platform == 'ios' ? MobileLoginRequestPlatform.ios : MobileLoginRequestPlatform.android,
            appVersion: appVersion,
          ),
        );
        await client.tokens.write(
          StoredTokens(accessToken: res.data.accessToken, refreshToken: res.data.refreshToken),
        );
      }
    });
    return currentUser();
  }

  Future<void> logout() async {
    try {
      if (_web) {
        await client.api.auth.webLogout();
      } else {
        final stored = await client.tokens.read();
        if (stored != null) {
          await client.api.auth.mobileLogout(body: MobileLogoutRequest(refreshToken: stored.refreshToken));
        }
      }
    } catch (_) {
      // Logging out locally must succeed even offline; the server session expires on its own.
    } finally {
      await client.tokens.clear();
    }
  }

  /// Only the deepest chosen college layer is sent; the API derives the ones above it.
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String? educationLevelId,
    String? universityId,
    String? facultyId,
    String? academicYearId,
  }) {
    return guardApi(
      () => client.api.auth.register(
        body: RegisterRequest(
          fullName: fullName,
          email: email,
          password: password,
          educationLevelId: educationLevelId,
          academicYearId: academicYearId,
          facultyId: academicYearId == null ? facultyId : null,
          universityId: academicYearId == null && facultyId == null ? universityId : null,
        ),
      ),
    );
  }

  Future<void> verifyEmail({required String email, required String otp}) =>
      guardApi(() => client.api.auth.verifyEmail(body: VerifyEmailRequest(email: email, otp: otp)));

  Future<void> resendVerification(String email) =>
      guardApi(() => client.api.auth.resendOtp(body: ResendOtpRequest(email: email)));

  Future<void> requestPasswordReset(String email) =>
      guardApi(() => client.api.auth.forgotPassword(body: ForgotPasswordRequest(email: email)));

  Future<void> resetPassword({required String email, required String otp, required String newPassword}) {
    return guardApi(
      () => client.api.auth.resetPassword(
        body: ResetPasswordRequest(email: email, otp: otp, newPassword: newPassword),
      ),
    );
  }

  Future<List<SessionSummary>> sessions() =>
      guardApi(() async => (await client.api.sessions.listSessions()).data);

  Future<void> revokeSession(String id) => guardApi(() => client.api.sessions.revokeSession(id: id));
}
