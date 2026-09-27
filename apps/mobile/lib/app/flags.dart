/// Build-time configuration passed with `--dart-define` (spec §10.1, §36).
///
/// `COUPON_REDEMPTION` is compile-time only and must never become a remote flag (spec §0.6).
abstract final class AppFlags {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:4000');
  static const couponRedemption = bool.fromEnvironment('COUPON_REDEMPTION', defaultValue: true);
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN_PUBLIC');
}
