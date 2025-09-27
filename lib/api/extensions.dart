import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

extension SuccessResponse<T> on Response<T> {
  bool get isSuccess =>
      statusCode != null && statusCode! >= 200 && statusCode! < 300;

  String get error {
    if (isSuccess) return '';
    if (data is String) return data as String;
    if (data is Map<String, dynamic> &&
        data != null &&
        (data as Map<String, dynamic>).containsKey('message')) {
      return (data as Map<String, dynamic>)['message'] as String;
    }
    return 'An error occurred';
  }

  /// Extract detailed error message from response data
  String get detailedError {
    if (isSuccess) return '';

    if (data is String) {
      return data as String;
    }

    if (data is Map<String, dynamic>) {
      final dataMap = data as Map<String, dynamic>;

      // Try common error message fields
      for (final key in ['message', 'error', 'detail', 'description']) {
        if (dataMap.containsKey(key) && dataMap[key] is String) {
          return dataMap[key] as String;
        }
      }

      // Return formatted map if no standard field found
      return dataMap.toString();
    }

    return data?.toString() ?? 'Unknown error occurred';
  }

  /// Log response details for debugging
  void logResponse(String operation) {
    if (kDebugMode) {
      print('=== Response Details ===');
      print('Operation: $operation');
      print('Status Code: $statusCode');
      print('Status Message: $statusMessage');
      if (!isSuccess && data != null) {
        print('Error Data: $data');
      }
      print('========================');
    }
  }
}
