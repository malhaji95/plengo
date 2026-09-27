/** API error codes and their Arabic user-facing messages (spec §30.4). */
export const ERROR_MESSAGES = {
  AUTH_INVALID_CREDENTIALS: 'بيانات الدخول غير صحيحة',
  AUTH_EMAIL_NOT_VERIFIED: 'البريد الإلكتروني غير مُفعّل',
  AUTH_OTP_INVALID: 'رمز التحقق غير صحيح أو منتهي',
  AUTH_2FA_REQUIRED: 'مطلوب رمز التحقق الثنائي',
  AUTH_SESSION_EXPIRED: 'انتهت الجلسة، يرجى تسجيل الدخول مجدداً',
  AUTH_EMAIL_TAKEN: 'البريد الإلكتروني مستخدم مسبقاً',
  APP_UPDATE_REQUIRED: 'يرجى تحديث التطبيق للمتابعة',
  COUPON_NOT_FOUND: 'كود التفعيل غير موجود',
  COUPON_ALREADY_USED: 'تم استخدام هذا الكود مسبقاً',
  COUPON_EXPIRED: 'انتهت صلاحية هذا الكود',
  COUPON_REVOKED: 'هذا الكود لم يعد صالحاً',
  COUPON_NOT_ELIGIBLE: 'هذا الكود لا يناسب حسابك',
  ALREADY_ENTITLED: 'لديك وصول مفعّل لهذا المحتوى مسبقاً',
  ENTITLEMENT_EXPIRED: 'انتهت صلاحية وصولك لهذا المحتوى',
  CONTENT_LOCKED: 'هذا المحتوى غير متاح على حسابك',
  ATTEMPT_ALREADY_SUBMITTED: 'تم تسليم هذا الاختبار مسبقاً',
  QUOTA_EXCEEDED: 'وصلت إلى الحد الأقصى المسموح',
  RATE_LIMITED: 'محاولات كثيرة، حاول لاحقاً',
  VALIDATION_ERROR: 'البيانات المدخلة غير صحيحة',
  NOT_FOUND: 'العنصر غير موجود',
  NOT_AUTHORIZED: 'لا تملك صلاحية لهذا الإجراء',
  UNAUTHENTICATED: 'يرجى تسجيل الدخول',
  SERVER_ERROR: 'حدث خطأ، حاول لاحقاً',
} as const;

export type ErrorCode = keyof typeof ERROR_MESSAGES;

export const ERROR_CODES = Object.keys(ERROR_MESSAGES) as ErrorCode[];
