import 'package:dio/dio.dart';

/// An API failure carrying the server's §30.4 error code and Arabic message.
class ApiException implements Exception {
  const ApiException(this.code, this.message, {this.statusCode});

  final String code;
  final String message;
  final int? statusCode;

  static const networkMessage = 'تعذر الاتصال بالخادم، تحقق من اتصالك بالإنترنت';
  static const genericMessage = 'حدث خطأ، حاول لاحقاً';

  bool get isUnauthenticated => code == 'UNAUTHENTICATED' || code == 'AUTH_SESSION_EXPIRED';

  factory ApiException.fromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['error'] is Map) {
      final err = data['error'] as Map;
      return ApiException(
        err['code'] as String? ?? 'SERVER_ERROR',
        err['message'] as String? ?? genericMessage,
        statusCode: error.response?.statusCode,
      );
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const ApiException('NETWORK_ERROR', networkMessage);
    }
    return ApiException('SERVER_ERROR', genericMessage, statusCode: error.response?.statusCode);
  }

  @override
  String toString() => 'ApiException($code, $message)';
}

/// Runs an API call and converts transport errors into [ApiException].
Future<T> guardApi<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (e) {
    if (e.error is ApiException) throw e.error! as ApiException;
    throw ApiException.fromDio(e);
  }
}
