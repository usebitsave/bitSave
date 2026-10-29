import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

final logInterceptor = PrettyDioLogger(
  requestHeader: true,
  requestBody: true,
  responseBody: true,
  responseHeader: false,
  error: true,
  compact: true,
  maxWidth: 90,
);

final requestInterceptors = InterceptorsWrapper(
  onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
    handler.next(options);
  },
  onResponse: (Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  },
  onError: (DioError dioError, ErrorInterceptorHandler handler) async {
    if (kDebugMode) {
      debugPrint('[API Error] ${dioError.requestOptions.path} -> ${dioError.response?.statusCode}: ${dioError.response?.data}');
    }
    // Always pass to caller so ViewModels can handle their own states
    handler.next(dioError);
  },
);