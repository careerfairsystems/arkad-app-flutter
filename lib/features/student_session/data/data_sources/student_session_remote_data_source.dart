import 'package:arkad_api/arkad_api.dart';
import 'package:dio/dio.dart';

import '../../../../api/extensions.dart';

/// Remote data source for student session operations
class StudentSessionRemoteDataSource {
  final ArkadApi _api;

  StudentSessionRemoteDataSource(this._api);

  /// Get student sessions from the API
  Future<StudentSessionNormalUserListSchema> getStudentSessions() async {
    final response = await _api
        .getStudentSessionsApi()
        .studentSessionsApiGetStudentSessions(
          extra: {
            'secure': [
              {
                'type': 'http',
                'scheme': 'bearer',
                'name': 'AuthBearer',
              }
            ]
          },
        );

    if (response.isSuccess && response.data != null) {
      return response.data!;
    } else {
      throw Exception('Failed to get student sessions: ${response.error}');
    }
  }

  /// Get available timeslots for a company
  Future<List<TimeslotSchema>> getTimeslots(int companyId) async {
    try {
      final response = await _api
          .getStudentSessionsApi()
          .studentSessionsApiGetStudentSessionTimeslots(companyId: companyId);
      return response.data?.toList() ?? <TimeslotSchema>[];
    } catch (e) {
      throw Exception('Failed to get timeslots for company $companyId: $e');
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
    } catch (e) {
      throw Exception('Failed to apply for student session: $e');
    }
  }

  /// Upload CV for a student session
  Future<Response<String>> uploadCV(int companyId, MultipartFile file) async {
    try {
      final response = await _api
          .getStudentSessionsApi()
          .studentSessionsApiUpdateCvForSession(companyId: companyId, cv: file);
      return response;
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
          );
      return response;
    } catch (e) {
      throw Exception('Failed to confirm timeslot: $e');
    }
  }

  /// Unbook a timeslot for a student session
  Future<Response<String>> unbookTimeslot(int companyId) async {
    try {
      final response = await _api
          .getStudentSessionsApi()
          .studentSessionsApiUnbookStudentSession(companyId: companyId);
      return response;
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
          .studentSessionsApiGetStudentSessionApplication(companyId: companyId);
      return response;
    } catch (e) {
      throw Exception('Failed to get application for company $companyId: $e');
    }
  }
}
