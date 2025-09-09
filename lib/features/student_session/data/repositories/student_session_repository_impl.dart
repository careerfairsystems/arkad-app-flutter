import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../shared/domain/result.dart';
import '../../../../shared/errors/app_error.dart';
import '../../domain/entities/student_session_application.dart';
import '../../domain/entities/timeslot.dart';
import '../../domain/repositories/student_session_repository.dart';
import '../data_sources/student_session_local_data_source.dart';
import '../data_sources/student_session_remote_data_source.dart';
import '../mappers/student_session_mapper.dart';

/// Implementation of student session repository
class StudentSessionRepositoryImpl implements StudentSessionRepository {
  final StudentSessionRemoteDataSource _remoteDataSource;
  final StudentSessionLocalDataSource _localDataSource;
  final StudentSessionMapper _mapper;

  StudentSessionRepositoryImpl({
    required StudentSessionRemoteDataSource remoteDataSource,
    required StudentSessionLocalDataSource localDataSource,
    required StudentSessionMapper mapper,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _mapper = mapper;

  @override
  Future<Result<List<StudentSessionApplication>>> getStudentSessions() async {
    try {
      // Try to get from remote first
      final applications = await _remoteDataSource.getStudentSessions();
      
      // Convert to domain entities (minimal for now)
      final domainApplications = applications.map((app) => 
        _mapper.fromApiApplication(app, 'Unknown Company')).toList();
      
      return Result.success(domainApplications);
    } catch (e) {
      await Sentry.captureException(e);
      return Result.failure(NetworkError(details: 'Failed to get student sessions: $e'));
    }
  }

  @override
  Future<Result<List<Timeslot>>> getTimeslots(int companyId) async {
    try {
      final timeslots = await _remoteDataSource.getTimeslots(companyId);
      
      // Convert to domain entities
      final domainTimeslots = timeslots.map((timeslot) => 
        _mapper.fromApiTimeslot(timeslot).copyWith(companyId: companyId)).toList();
      
      return Result.success(domainTimeslots);
    } catch (e) {
      await Sentry.captureException(e);
      return Result.failure(NetworkError(details: 'Failed to get timeslots: $e'));
    }
  }

  @override
  Future<Result<StudentSessionApplication>> applyForSession({
    required int companyId,
    required String motivationText,
    String? programme,
    String? linkedin,
    String? masterTitle,
    int? studyYear,
    bool updateProfile = false,
  }) async {
    try {
      // Create the application to send
      final application = StudentSessionApplication(
        companyId: companyId,
        companyName: 'Company', // Will be resolved later
        motivationText: motivationText,
        programme: programme,
        linkedin: linkedin,
        masterTitle: masterTitle,
        studyYear: studyYear,
        status: ApplicationStatus.pending,
      );

      // Convert to API schema
      final apiApplication = _mapper.toApiApplication(application, updateProfile: updateProfile);
      
      // Send to remote
      final response = await _remoteDataSource.applyForSession(apiApplication);
      
      // Convert response back to domain entity
      final domainApplication = _mapper.fromApiApplication(response, 'Company');
      
      return Result.success(domainApplication);
    } catch (e) {
      await Sentry.captureException(e);
      return Result.failure(NetworkError(details: 'Failed to apply for session: $e'));
    }
  }

  @override
  Future<Result<void>> cancelApplication(int companyId) async {
    try {
      await _remoteDataSource.cancelApplication(companyId);
      return Result.success(null);
    } catch (e) {
      await Sentry.captureException(e);
      return Result.failure(NetworkError(details: 'Failed to cancel application: $e'));
    }
  }

  @override
  Future<Result<void>> refreshStudentSessions() async {
    try {
      _localDataSource.clearCache();
      // Force refresh from remote
      await getStudentSessions();
      return Result.success(null);
    } catch (e) {
      await Sentry.captureException(e);
      return Result.failure(NetworkError(details: 'Failed to refresh student sessions: $e'));
    }
  }
}