import 'package:arkad_api/arkad_api.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Remote data source for student session operations
class StudentSessionRemoteDataSource {
  final ArkadApi _api;

  StudentSessionRemoteDataSource(this._api);

  /// Get student sessions from the API
  Future<List<StudentSessionApplicationOutSchema>> getStudentSessions() async {
    try {
      final _ =
          await _api
              .getStudentSessionsApi()
              .studentSessionsApiGetStudentSessions();
      // For now, return empty list - will implement proper parsing when API structure is clear
      return <StudentSessionApplicationOutSchema>[];
    } catch (e) {
      await Sentry.captureException(e);
      throw Exception('Failed to get student sessions: $e');
    }
  }

  /// Get available timeslots for a company
  Future<List<TimeslotSchemaUser>> getTimeslots(int companyId) async {
    try {
      final response = await _api
          .getStudentSessionsApi()
          .studentSessionsApiGetStudentSessionTimeslots(companyId: companyId);
      return response.data?.toList() ?? <TimeslotSchemaUser>[];
    } catch (e) {
      await Sentry.captureException(e);
      throw Exception('Failed to get timeslots for company $companyId: $e');
    }
  }

  /// Apply for a student session
  Future<StudentSessionApplicationOutSchema> applyForSession(
    StudentSessionApplicationSchema application,
  ) async {
    try {
      final _ = await _api
          .getStudentSessionsApi()
          .studentSessionsApiApplyForSession(
            studentSessionApplicationSchema: application,
          );
      // Create a minimal response for now
      return StudentSessionApplicationOutSchema(
        (b) =>
            b
              ..companyId = application.companyId
              ..motivationText = application.motivationText,
      );
    } catch (e) {
      await Sentry.captureException(e);
      throw Exception('Failed to apply for student session: $e');
    }
  }

  /// Cancel/unbook a student session
  Future<void> cancelApplication(int companyId) async {
    try {
      await _api.getStudentSessionsApi().studentSessionsApiUnbookStudentSession(
        companyId: companyId,
      );
    } catch (e) {
      await Sentry.captureException(e);
      throw Exception('Failed to cancel student session application: $e');
    }
  }
}
