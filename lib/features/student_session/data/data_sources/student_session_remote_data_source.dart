import 'package:arkad_api/arkad_api.dart';
import 'package:dio/dio.dart';

import '../../../../api/extensions.dart';
import '../../../../shared/data/api_error_handler.dart';

/// Remote data source for student session operations
class StudentSessionRemoteDataSource {
  final ArkadApi _api;

  StudentSessionRemoteDataSource(this._api);

  /// Get student sessions from the API
  Future<StudentSessionNormalUserListSchema> getStudentSessions() async {
    try {
      final response = await _api
          .getStudentSessionsApi()
          .studentSessionsApiGetStudentSessions(
            extra: {
              'secure': [
                {'type': 'http', 'scheme': 'bearer', 'name': 'AuthBearer'},
              ],
            },
          );

      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        throw Exception('Failed to get student sessions');
      }
    } on DioException catch (e) {
      final exception = await ApiErrorHandler.handleDioException(
        e,
        operationName: 'getStudentSessions',
      );
      throw exception;
    }
  }

  /// Get available timeslots for a company with user-specific status
  Future<List<TimeslotSchemaUser>> getTimeslots(int companyId) async {
    try {
      final response = await _api
          .getStudentSessionsApi()
          .studentSessionsApiGetStudentSessionTimeslots(
            companyId: companyId,
            extra: {
              'secure': [
                {'type': 'http', 'scheme': 'bearer', 'name': 'AuthBearer'},
              ],
            },
          );

      if (response.isSuccess && response.data != null) {
        return response.data!.toList();
      } else {
        throw Exception('Failed to get timeslots');
      }
    } on DioException catch (e) {
      final exception = await ApiErrorHandler.handleDioException(
        e,
        operationName: 'getTimeslots',
        additionalContext: {'company_id': companyId},
      );
      throw exception;
    } catch (e) {
      throw Exception('Failed to get timeslots');
    }
  }

  /// Apply for a student session
  Future<Response<String>> applyForSession(
    StudentSessionApplicationSchema application,
  ) async {
    try {
      final response = await _api
          .getStudentSessionsApi()
          .studentSessionsApiApplyForSession(
            studentSessionApplicationSchema: application,
          );
      return response;
    } on DioException catch (e) {
      final exception = await ApiErrorHandler.handleDioException(
        e,
        operationName: 'applyForSession',
        additionalContext: {'company_id': application.companyId},
      );
      throw exception;
    } catch (e) {
      throw Exception('Failed to apply for student session');
    }
  }

  /// Upload CV for a student session
  Future<Response<String>> uploadCV(int companyId, MultipartFile file) async {
    try {
      final response = await _api
          .getStudentSessionsApi()
          .studentSessionsApiUpdateCvForSession(
            companyId: companyId,
            cv: file,
            extra: {
              'secure': [
                {'type': 'http', 'scheme': 'bearer', 'name': 'AuthBearer'},
              ],
            },
          );
      return response;
    } on DioException catch (e) {
      final exception = await ApiErrorHandler.handleDioException(
        e,
        operationName: 'uploadCV',
        additionalContext: {'company_id': companyId},
      );
      throw exception;
    } catch (e) {
      throw Exception('Failed to upload CV: $e');
    }
  }

  /// Confirm/book a timeslot for a student session
  Future<Response<String>> confirmTimeslot(
    int companyId,
    int timeslotId,
  ) async {
    try {
      final response = await _api
          .getStudentSessionsApi()
          .studentSessionsApiConfirmStudentSession(
            companyId: companyId,
            timeslotId: timeslotId,
            extra: {
              'secure': [
                {'type': 'http', 'scheme': 'bearer', 'name': 'AuthBearer'},
              ],
            },
          );
      return response;
    } on DioException catch (e) {
      // CRITICAL: Preserve original DioException with HTTP status codes for proper conflict detection
      // Let the repository handle the DioException for conflict detection
      await ApiErrorHandler.handleDioException(
        e,
        operationName: 'confirmTimeslot',
        additionalContext: {'company_id': companyId, 'timeslot_id': timeslotId},
      );
      rethrow; // Let repository handle HTTP status codes
    } catch (e) {
      throw Exception('Failed to confirm timeslot: ${e.toString()}');
    }
  }

  /// Unbook a timeslot for a student session
  Future<Response<String>> unbookTimeslot(int companyId) async {
    try {
      final response = await _api
          .getStudentSessionsApi()
          .studentSessionsApiUnbookStudentSession(
            companyId: companyId,
            extra: {
              'secure': [
                {'type': 'http', 'scheme': 'bearer', 'name': 'AuthBearer'},
              ],
            },
          );
      return response;
    } on DioException catch (e) {
      final exception = await ApiErrorHandler.handleDioException(
        e,
        operationName: 'unbookTimeslot',
        additionalContext: {'company_id': companyId},
      );
      throw exception;
    } catch (e) {
      throw Exception('Failed to unbook timeslot: $e');
    }
  }

  /// Get application for a specific company
  Future<Response<StudentSessionApplicationOutSchema?>>
  getApplicationForCompany(int companyId) async {
    try {
      final response = await _api
          .getStudentSessionsApi()
          .studentSessionsApiGetStudentSessionApplication(
            companyId: companyId,
            extra: {
              'secure': [
                {'type': 'http', 'scheme': 'bearer', 'name': 'AuthBearer'},
              ],
            },
          );
      return response;
    } on DioException catch (e) {
      final exception = await ApiErrorHandler.handleDioException(
        e,
        operationName: 'getApplicationForCompany',
        additionalContext: {'company_id': companyId},
      );
      throw exception;
    } catch (e) {
      throw Exception('Failed to get application');
    }
  }
}
