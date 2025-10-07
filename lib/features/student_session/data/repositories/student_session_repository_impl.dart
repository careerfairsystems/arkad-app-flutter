import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../shared/data/repositories/base_repository.dart';
import '../../../../shared/domain/result.dart';
import '../../../../shared/errors/student_session_errors.dart';
import '../../../../shared/infrastructure/services/file_service.dart';
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
    Sentry.logger.info(
      'Starting student sessions loading',
      attributes: {
        'operation': SentryLogAttribute.string('getStudentSessions'),
      },
    );

    return executeOperation(
      () async {
        final response = await _remoteDataSource.getStudentSessions();

        // Resolve company names for all student sessions
        final studentSessions = <StudentSession>[];
        for (final sessionDto in response.studentSessions) {
          String? companyName;
          String? logoUrl;

          // Fetch company data using the cached company service
          final companyResult = await _getCompanyByIdUseCase.call(
            sessionDto.companyId,
          );
          companyResult.when(
            success: (company) {
              companyName = company.name;
              logoUrl = company.fullLogoUrl;
            },
            failure: (_) {
              companyName = null; // Company not found, will use fallback
              logoUrl = null;
            },
          );

          final studentSession = _mapper.fromApiStudentSession(
            sessionDto,
            companyName: companyName,
            logoUrl: logoUrl,
          );
          studentSessions.add(studentSession);
        }

        Sentry.logger.info(
          'Successfully loaded student sessions',
          attributes: {
            'operation': SentryLogAttribute.string('getStudentSessions'),
            'sessions_count': SentryLogAttribute.string(
              studentSessions.length.toString(),
            ),
          },
        );

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
        String? logoUrl;

        // Fetch company data using the cached company service
        final companyResult = await _getCompanyByIdUseCase.call(companyId);
        companyResult.when(
          success: (company) {
            companyName = company.name;
            logoUrl = company.fullLogoUrl;
          },
          failure: (_) {
            companyName = null; // Company not found, will use fallback
            logoUrl = null;
          },
        );

        return _mapper.fromApiStudentSession(
          sessionDto,
          companyName: companyName,
          logoUrl: logoUrl,
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

  /// Get applications with enhanced booking state determined from timeslots
  /// This method provides the real booking status by checking timeslots
  @override
  Future<Result<List<StudentSessionApplicationWithBookingState>>>
  getMyApplicationsWithBookingState() async {
    return executeOperation(() async {
      // Get user's applications directly from the API (replaces removed getMyApplications)
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
          failure: (_) =>
              companyName = null, // Company not found, will use fallback
        );

        final application = _mapper.fromApiStudentSessionToApplication(
          sessionDto,
          companyName: companyName,
        );
        applications.add(application);
      }

      final applicationsWithBookingState =
          <StudentSessionApplicationWithBookingState>[];

      for (final application in applications) {
        // Only check timeslots for accepted applications
        if (application.status == ApplicationStatus.accepted) {
          try {
            final timslotsResult = await getTimeslots(application.companyId);
            final timeslots = timslotsResult.when(
              success: (slots) => slots,
              failure: (_) =>
                  <Timeslot>[], // Fallback to empty list if timeslots fail
            );

            final hasBooking = timeslots.any(
              (slot) => slot.status.isBookedByCurrentUser,
            );
            final bookedTimeslot = timeslots
                .where((slot) => slot.status.isBookedByCurrentUser)
                .firstOrNull;

            applicationsWithBookingState.add(
              StudentSessionApplicationWithBookingState(
                application: application,
                hasBooking: hasBooking,
                bookedTimeslot: bookedTimeslot,
              ),
            );
          } catch (e) {
            // If timeslots fail to load, add application without booking info
            applicationsWithBookingState.add(
              StudentSessionApplicationWithBookingState(
                application: application,
                hasBooking: false,
              ),
            );
          }
        } else {
          // For non-accepted applications, no booking state needed
          applicationsWithBookingState.add(
            StudentSessionApplicationWithBookingState(
              application: application,
              hasBooking: false,
            ),
          );
        }
      }

      return applicationsWithBookingState;
    }, 'load my applications with booking state');
  }

  @override
  Future<Result<List<Timeslot>>> getTimeslots(int companyId) async {
    return executeOperation(() async {
      final timeslots = await _remoteDataSource.getTimeslots(companyId);
      return timeslots
          .map(
            (timeslotDto) =>
                _mapper.fromApiTimeslotUser(timeslotDto, companyId),
          )
          .toList();
    }, 'load timeslots for company $companyId');
  }

  @override
  Future<Result<String>> applyForSession(
    StudentSessionApplicationParams params,
  ) async {
    Sentry.logger.info(
      'Starting student session application',
      attributes: {
        'operation': SentryLogAttribute.string('applyForSession'),
        'company_id': SentryLogAttribute.string(params.companyId.toString()),
        'motivation_length': SentryLogAttribute.string(
          params.motivationText.length.toString(),
        ),
      },
    );

    return executeOperation(() async {
      final apiSchema = _mapper.toApiApplicationSchema(params);
      final response = await _remoteDataSource.applyForSession(apiSchema);

      Sentry.logger.info(
        'Successfully submitted student session application',
        attributes: {
          'operation': SentryLogAttribute.string('applyForSession'),
          'company_id': SentryLogAttribute.string(params.companyId.toString()),
        },
      );

      // API returns a string response for successful applications
      return response.data ?? 'Application submitted successfully';
    }, 'student_session_apply');
  }

  @override
  Future<Result<String>> uploadCVForSession({
    required int companyId,
    required PlatformFile file,
  }) async {
    return executeOperation(
      () async {
        // Note: File validation is handled at FileService and UseCase layers
        // No additional validation needed here - proceed directly to upload

        // Create multipart file using platform-appropriate method
        final MultipartFile multipartFile;
        if (kIsWeb) {
          multipartFile = MultipartFile.fromBytes(
            file.bytes,
            filename: file.name,
          );
        } else {
          multipartFile = await MultipartFile.fromFile(
            file.path!,
            filename: file.name,
          );
        }

        final response = await _remoteDataSource.uploadCV(
          companyId,
          multipartFile,
        );
        return response.data ?? 'CV uploaded successfully';
      },
      'upload CV for company $companyId',
      onError: (error) {
        final fileName = file.name;
        // Handle remaining server-side errors (network, auth, etc.)
        if (error.toString().contains('413') ||
            error.toString().contains('size')) {
          throw StudentSessionFileUploadError(
            fileName,
            details: 'File too large (server limit exceeded)',
          );
        }
        if (error.toString().contains('415') ||
            error.toString().contains('format') ||
            error.toString().contains('type')) {
          throw StudentSessionFileUploadError(
            fileName,
            details: 'Unsupported file format',
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
    Sentry.logger.info(
      'Attempting to book timeslot',
      attributes: {
        'operation': SentryLogAttribute.string('bookTimeslot'),
        'company_id': SentryLogAttribute.string(companyId.toString()),
        'timeslot_id': SentryLogAttribute.string(timeslotId.toString()),
      },
    );

    try {
      final response = await _remoteDataSource.confirmTimeslot(
        companyId,
        timeslotId,
      );

      Sentry.logger.info(
        'Successfully booked timeslot',
        attributes: {
          'operation': SentryLogAttribute.string('bookTimeslot'),
          'company_id': SentryLogAttribute.string(companyId.toString()),
          'timeslot_id': SentryLogAttribute.string(timeslotId.toString()),
        },
      );

      return Result.success(response.data ?? 'Timeslot booked successfully');
    } catch (e) {
      // ENHANCED: Handle booking conflicts directly from original exception
      if (e is DioException) {
        // Check HTTP status code for conflict
        if (e.response?.statusCode == 409) {
          Sentry.logger.error(
            'Booking conflict detected - timeslot already booked',
            attributes: {
              'operation': SentryLogAttribute.string('bookTimeslot'),
              'company_id': SentryLogAttribute.string(companyId.toString()),
              'timeslot_id': SentryLogAttribute.string(timeslotId.toString()),
              'conflict_reason': SentryLogAttribute.string('http_409'),
            },
          );

          return Result.failure(
            const StudentSessionBookingConflictError(
              'Timeslot was just booked by someone else',
            ),
          );
        }
        // Check error message for other conflict indicators
        final errorMessage = e.response?.data?.toString() ?? e.message ?? '';
        if (errorMessage.contains('conflict') ||
            errorMessage.contains('already booked') ||
            errorMessage.contains('taken') ||
            errorMessage.contains('unavailable')) {
          return Result.failure(
            const StudentSessionBookingConflictError(
              'Timeslot was just booked by someone else',
            ),
          );
        }
      }

      // For all other errors, use the base repository error handling
      return executeOperation(
        () => throw e, // Re-throw to trigger base error handling
        'book timeslot $timeslotId for company $companyId',
      );
    }
  }

  @override
  Future<Result<String>> unbookTimeslot(int companyId) async {
    return executeOperation(() async {
      final response = await _remoteDataSource.unbookTimeslot(companyId);
      return response.data ?? 'Timeslot unbooked successfully';
    }, 'unbook timeslot for company $companyId');
  }

  @override
  Future<Result<String>> switchTimeslot({
    required int fromTimeslotId,
    required int newTimeslotId,
  }) async {
    Sentry.logger.info(
      'Attempting to switch timeslot',
      attributes: {
        'operation': SentryLogAttribute.string('switchTimeslot'),
        'from_timeslot_id': SentryLogAttribute.string(
          fromTimeslotId.toString(),
        ),
        'new_timeslot_id': SentryLogAttribute.string(newTimeslotId.toString()),
      },
    );

    try {
      final response = await _remoteDataSource.switchTimeslot(
        fromTimeslotId: fromTimeslotId,
        newTimeslotId: newTimeslotId,
      );

      Sentry.logger.info(
        'Successfully switched timeslot',
        attributes: {
          'operation': SentryLogAttribute.string('switchTimeslot'),
          'from_timeslot_id': SentryLogAttribute.string(
            fromTimeslotId.toString(),
          ),
          'new_timeslot_id': SentryLogAttribute.string(
            newTimeslotId.toString(),
          ),
        },
      );

      return Result.success(response.data ?? 'Timeslot switched successfully');
    } catch (e) {
      // ENHANCED: Handle timeslot conflicts directly from original exception
      if (e is DioException) {
        // Check HTTP status code for conflict (409) or not found (404)
        if (e.response?.statusCode == 409 || e.response?.statusCode == 404) {
          Sentry.logger.error(
            'Switch timeslot conflict - timeslot not found or already taken',
            attributes: {
              'operation': SentryLogAttribute.string('switchTimeslot'),
              'from_timeslot_id': SentryLogAttribute.string(
                fromTimeslotId.toString(),
              ),
              'new_timeslot_id': SentryLogAttribute.string(
                newTimeslotId.toString(),
              ),
              'status_code': SentryLogAttribute.string(
                e.response?.statusCode.toString() ?? 'unknown',
              ),
              'conflict_reason': SentryLogAttribute.string(
                'http_${e.response?.statusCode}',
              ),
            },
          );

          return Result.failure(
            const StudentSessionBookingConflictError(
              'Timeslot was just taken by someone else',
            ),
          );
        }
        // Check error message for other conflict indicators
        final errorMessage = e.response?.data?.toString() ?? e.message ?? '';
        if (errorMessage.contains('conflict') ||
            errorMessage.contains('already taken') ||
            errorMessage.contains('not found') ||
            errorMessage.contains('unavailable')) {
          return Result.failure(
            const StudentSessionBookingConflictError(
              'Timeslot was just taken by someone else',
            ),
          );
        }
      }

      // For all other errors, use the base repository error handling
      return executeOperation(
        () => throw e, // Re-throw to trigger base error handling
        'switch from timeslot $fromTimeslotId to $newTimeslotId',
      );
    }
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
        failure: (_) =>
            companyName = null, // Company not found, will use fallback
      );

      return _mapper.fromApiApplicationOut(
        response.data!,
        companyId,
        companyName: companyName,
      );
    }, 'get application for company $companyId');
  }
}
