import 'package:dio/dio.dart';

import '../../../../shared/data/repositories/base_repository.dart';
import '../../../../shared/domain/result.dart';
import '../../../../shared/errors/student_session_errors.dart';
import '../../../company/domain/use_cases/get_company_by_id_use_case.dart';
import '../../domain/entities/student_session.dart';
import '../../domain/entities/student_session_application.dart';
import '../../domain/entities/timeslot.dart';
import '../../domain/repositories/student_session_repository.dart';
import '../data_sources/student_session_remote_data_source.dart';
import '../mappers/student_session_mapper.dart';

/// Enhanced implementation of student session repository using BaseRepository pattern
class StudentSessionRepositoryImpl extends BaseRepository
    implements StudentSessionRepository {
  const StudentSessionRepositoryImpl({
    required StudentSessionRemoteDataSource remoteDataSource,
    required StudentSessionMapper mapper,
    required GetCompanyByIdUseCase getCompanyByIdUseCase,
  }) : _remoteDataSource = remoteDataSource,
       _mapper = mapper,
       _getCompanyByIdUseCase = getCompanyByIdUseCase;

  final StudentSessionRemoteDataSource _remoteDataSource;
  final StudentSessionMapper _mapper;
  final GetCompanyByIdUseCase _getCompanyByIdUseCase;

  @override
  Future<Result<List<StudentSession>>> getStudentSessions() async {
    return executeOperation(
      () async {
        final response = await _remoteDataSource.getStudentSessions();

        // Resolve company names for all student sessions
        final studentSessions = <StudentSession>[];
        for (final sessionDto in response.studentSessions) {
          String? companyName;

          // Fetch company name using the cached company data
          final companyResult = await _getCompanyByIdUseCase.call(
            sessionDto.companyId,
          );
          companyResult.when(
            success: (company) => companyName = company.name,
            failure:
                (_) =>
                    companyName = null, // Company not found, will use fallback
          );

          final studentSession = _mapper.fromApiStudentSession(
            sessionDto,
            companyName: companyName,
          );
          studentSessions.add(studentSession);
        }

        return studentSessions;
      },
      'load student sessions',
      onError: (error) {
        if (error is StudentSessionApplicationError) return;
        // Convert generic errors to student session specific errors
        throw StudentSessionApplicationError(
          'Failed to load student sessions',
          details: error.technicalDetails,
        );
      },
    );
  }

  @override
  Future<Result<StudentSession?>> getStudentSessionById(int companyId) async {
    return executeOperation(
      () async {
        final response = await _remoteDataSource.getStudentSessions();
        
        // Find the session for the specified company
        final sessionDto = response.studentSessions
            .where((session) => session.companyId == companyId)
            .firstOrNull;
            
        if (sessionDto == null) {
          return null; // Session not found for this company
        }
        
        String? companyName;
        
        // Fetch company name using the cached company data
        final companyResult = await _getCompanyByIdUseCase.call(companyId);
        companyResult.when(
          success: (company) => companyName = company.name,
          failure: (_) => companyName = null, // Company not found, will use fallback
        );
        
        return _mapper.fromApiStudentSession(
          sessionDto,
          companyName: companyName,
        );
      },
      'load student session for company $companyId',
      onError: (error) {
        if (error is StudentSessionApplicationError) return;
        // Convert generic errors to student session specific errors
        throw StudentSessionApplicationError(
          'Failed to load student session',
          details: error.technicalDetails,
        );
      },
    );
  }

  @override
  Future<Result<List<StudentSessionApplication>>> getMyApplications() async {
    return executeOperation(() async {
      // This would ideally be a separate endpoint, but for now we'll derive from getStudentSessions
      final response = await _remoteDataSource.getStudentSessions();

      // Filter and resolve company names for applications
      final applications = <StudentSessionApplication>[];
      for (final sessionDto in response.studentSessions.where(
        (session) => session.userStatus != null,
      )) {
        String? companyName;

        // Fetch company name using the cached company data
        final companyResult = await _getCompanyByIdUseCase.call(
          sessionDto.companyId,
        );
        companyResult.when(
          success: (company) => companyName = company.name,
          failure:
              (_) => companyName = null, // Company not found, will use fallback
        );

        final application = _mapper.fromApiStudentSessionToApplication(
          sessionDto,
          companyName: companyName,
        );
        applications.add(application);
      }

      return applications;
    }, 'load my applications');
  }

  @override
  Future<Result<List<Timeslot>>> getTimeslots(int companyId) async {
    return executeOperation(() async {
      final timeslots = await _remoteDataSource.getTimeslots(companyId);
      return timeslots
          .map((timeslotDto) => _mapper.fromApiTimeslot(timeslotDto, companyId))
          .toList();
    }, 'load timeslots for company $companyId');
  }

  @override
  Future<Result<String>> applyForSession(
    StudentSessionApplicationParams params,
  ) async {
    return executeOperation(
      () async {
        final apiSchema = _mapper.toApiApplicationSchema(params);
        final response = await _remoteDataSource.applyForSession(apiSchema);

        // API returns a string response for successful applications
        return response.data ?? 'Application submitted successfully';
      },
      'student_session_apply',
    );
  }

  @override
  Future<Result<String>> uploadCVForSession({
    required int companyId,
    required String filePath,
  }) async {
    return executeOperation(
      () async {
        // Create multipart file from path
        final file = await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        );

        final response = await _remoteDataSource.uploadCV(companyId, file);
        return response.data ?? 'CV uploaded successfully';
      },
      'upload CV for company $companyId',
      onError: (error) {
        final fileName = filePath.split('/').last;
        if (error.toString().contains('413') ||
            error.toString().contains('size')) {
          throw StudentSessionFileUploadError(
            fileName,
            details: 'File too large',
          );
        }
        throw StudentSessionFileUploadError(
          fileName,
          details: error.toString(),
        );
      },
    );
  }

  @override
  Future<Result<String>> bookTimeslot({
    required int companyId,
    required int timeslotId,
  }) async {
    return executeOperation(
      () async {
        final response = await _remoteDataSource.confirmTimeslot(
          companyId,
          timeslotId,
        );
        return response.data ?? 'Timeslot booked successfully';
      },
      'book timeslot $timeslotId for company $companyId',
      onError: (error) {
        // Handle booking conflicts
        if (error.toString().contains('409') ||
            error.toString().contains('conflict') ||
            error.toString().contains('already booked')) {
          throw StudentSessionBookingConflictError(
            'Timeslot was just booked by someone else',
          );
        }
      },
    );
  }

  @override
  Future<Result<String>> unbookTimeslot(int companyId) async {
    return executeOperation(() async {
      final response = await _remoteDataSource.unbookTimeslot(companyId);
      return response.data ?? 'Timeslot unbooked successfully';
    }, 'unbook timeslot for company $companyId');
  }

  @override
  Future<Result<StudentSessionApplication?>> getApplicationForCompany(
    int companyId,
  ) async {
    return executeOperation(() async {
      final response = await _remoteDataSource.getApplicationForCompany(
        companyId,
      );
      if (response.data == null) return null;

      // Fetch company name using the cached company data
      String? companyName;
      final companyResult = await _getCompanyByIdUseCase.call(companyId);
      companyResult.when(
        success: (company) => companyName = company.name,
        failure:
            (_) => companyName = null, // Company not found, will use fallback
      );

      return _mapper.fromApiApplicationOut(
        response.data!,
        companyId,
        companyName: companyName,
      );
    }, 'get application for company $companyId');
  }
}
