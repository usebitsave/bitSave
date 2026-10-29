import 'package:dio/dio.dart';

class ApiResponse {
  final Response response;

  ApiResponse(this.response);

  dynamic get data => response.data;

  int? get statusCode => response.statusCode;

  bool get isSuccess {
    final code = response.statusCode ?? 500;
    return code >= 200 && code < 300;
  }

  String get errorMessage {
    if (response.data != null) {
      if (response.data is Map) {
        final map = response.data as Map;
        if (map.containsKey('error') && map['error'] != null) {
          return map['error'].toString();
        }
        if (map.containsKey('message') && map['message'] != null) {
          return map['message'].toString();
        }
      } else if (response.data is String && (response.data as String).isNotEmpty) {
        return response.data as String;
      }
    }
    return response.statusMessage ?? 'An unexpected error occurred';
  }
}
