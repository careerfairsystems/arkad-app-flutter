import '../../../../shared/errors/app_error.dart';

/// Error when company data fails to load
class CompanyLoadError extends AppError {
  const CompanyLoadError({String? details})
      : super(
          userMessage: 'Unable to load companies. Please try again.',
          technicalDetails: details,
          severity: ErrorSeverity.error,
        );
}

/// Error when a specific company is not found
class CompanyNotFoundError extends AppError {
  const CompanyNotFoundError(this.companyId)
      : super(
          userMessage: 'Company not found',
          technicalDetails: 'Company with ID $companyId was not found',
          severity: ErrorSeverity.error,
        );

  final int companyId;
}

/// Error when company search fails
class CompanySearchError extends AppError {
  const CompanySearchError(this.query, {String? details})
      : super(
          userMessage: 'Search failed',
          technicalDetails: details ?? 'Failed to search for "$query"',
          severity: ErrorSeverity.error,
        );

  final String query;
}

/// Error when company cache fails
class CompanyCacheError extends AppError {
  const CompanyCacheError({String? details})
      : super(
          userMessage: 'Cache error',
          technicalDetails: details ?? 'Failed to access company cache',
          severity: ErrorSeverity.warning,
        );
}