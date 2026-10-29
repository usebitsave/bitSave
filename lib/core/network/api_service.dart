import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../app/app.locator.dart';
import '../../app/app.logger.dart';
import '../config/app_config.dart';
import '../services/secure_storage_service.dart';
import 'api_response.dart';
import 'interceptors.dart';

enum HttpMethod { get, post, postRefresh, patch, put, delete }

class ApiService {
  final log = getLogger('ApiService');

  late final Dio dio;

  ApiService() {
    dio = _createDio();
  }

  static const int _timeout = 45000;

  static final Map<String, String> _requestHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Dio _createDio() {
    final options = BaseOptions(
      baseUrl: AppConfig.baseUrl,
      headers: _requestHeaders,
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
      sendTimeout: _timeout,
    );

    final dioInstance = Dio(options);
    if (!kReleaseMode) {
      dioInstance.interceptors.add(logInterceptor);
    }
    dioInstance.interceptors.add(requestInterceptors);
    return dioInstance;
  }

  /// Ensure baseUrl matches current AppConfig
  void updateBaseUrl() {
    dio.options.baseUrl = AppConfig.baseUrl;
  }

  Future<ApiResponse> call({
    required HttpMethod method,
    required String endpoint,
    Map<String, dynamic>? reqBody,
    Map<String, dynamic>? reqParams,
    Map<String, dynamic>? customHeaders,
    FormData? formData,
    bool protected = true,
    bool useFormData = false,
  }) async {
    // Keep baseUrl synchronized with AppConfig
    dio.options.baseUrl = AppConfig.baseUrl;

    // Normalize endpoint slashes
    final formattedEndpoint = endpoint.startsWith('http')
        ? endpoint
        : (endpoint.startsWith('/') ? endpoint : '/$endpoint');

    final headers = <String, dynamic>{
      ..._requestHeaders,
      if (customHeaders != null) ...customHeaders,
    };

    if (protected) {
      final token = await _getToken();
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final options = Options(headers: headers);

    try {
      Response response;
      switch (method) {
        case HttpMethod.post:
        case HttpMethod.postRefresh:
          response = await dio.post(
            formattedEndpoint,
            queryParameters: reqParams,
            data: useFormData ? formData : reqBody,
            options: options,
          );
          break;

        case HttpMethod.get:
          response = await dio.get(
            formattedEndpoint,
            queryParameters: reqParams,
            options: options,
          );
          break;

        case HttpMethod.patch:
          response = await dio.patch(
            formattedEndpoint,
            data: useFormData ? formData : reqBody,
            options: options,
          );
          break;

        case HttpMethod.put:
          response = await dio.put(
            formattedEndpoint,
            data: useFormData ? formData : reqBody,
            options: options,
          );
          break;

        case HttpMethod.delete:
          response = await dio.delete(
            formattedEndpoint,
            data: useFormData ? formData : reqBody,
            options: options,
          );
          break;
      }

      return ApiResponse(response);
    } on DioError catch (e) {
      log.e("DioError on $formattedEndpoint: ${e.message}");

      if (e.response != null) {
        return ApiResponse(e.response!);
      }

      String message;
      int statusCode;
      switch (e.type) {
        case DioErrorType.connectTimeout:
          statusCode = 504;
          message = "Connection timeout";
          break;
        case DioErrorType.receiveTimeout:
          statusCode = 504;
          message = "Receive timeout";
          break;
        case DioErrorType.sendTimeout:
          statusCode = 504;
          message = "Send timeout";
          break;
        case DioErrorType.cancel:
          statusCode = 499;
          message = "Request was cancelled";
          break;
        default:
          statusCode = 503;
          message = "Unable to connect to server. Please check your network.";
          break;
      }

      return ApiResponse(
        Response(
          statusCode: statusCode,
          data: {"error": message},
          requestOptions: e.requestOptions,
        ),
      );
    } catch (e) {
      log.e("Unexpected error calling $formattedEndpoint: $e");
      return ApiResponse(
        Response(
          statusCode: 500,
          data: {"error": e.toString()},
          requestOptions: RequestOptions(path: formattedEndpoint),
        ),
      );
    }
  }

  Future<String> _getToken() async {
    try {
      final secureStorage = locator<SecureStorageService>();
      final token = await secureStorage.getToken();
      return token ?? "";
    } catch (e) {
      log.w("Failed to read token from secure storage: $e");
      return "";
    }
  }
}
