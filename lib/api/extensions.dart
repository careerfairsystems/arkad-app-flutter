import 'package:arkad_api/arkad_api.dart';
import 'package:built_collection/src/list.dart';
import 'package:dio/src/response.dart';

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
}

extension on int {
  bool get isSuccess => this >= 200 && this < 300;
}
