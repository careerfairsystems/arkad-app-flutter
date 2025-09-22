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
              {'type': 'http', 'scheme': 'bearer', 'name': 'AuthBearer'},
            ],
          },
        );

    if (response.isSuccess && response.data != null) {
      return response.data!;
    } else {
      throw Exception('Failed to get student sessions');
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
        throw Exception('Failed to get timeslots}');
      }
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
      throw Exception('Failed to confirm timeslot');
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
          .studentSessionsApiGetStudentSessionApplication(
            companyId: companyId,
            extra: {
              'secure': [
                {'type': 'http', 'scheme': 'bearer', 'name': 'AuthBearer'},
              ],
            },
          );
      return response;
    } catch (e) {
      throw Exception('Failed to get application');
    }
  }
}
