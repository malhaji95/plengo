import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

/// Web builds authenticate with the API's httpOnly cookie (spec §11.2, §24).
void configureHttpAdapter(Dio dio) {
  dio.httpClientAdapter = BrowserHttpClientAdapter(withCredentials: true);
}
