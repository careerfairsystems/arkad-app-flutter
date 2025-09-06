import '../../../../shared/domain/result.dart';
import '../entities/company.dart';

/// Repository interface for company data access
abstract class CompanyRepository {
  /// Get all companies with optional force refresh
  Future<Result<List<Company>>> getCompanies({bool forceRefresh = false});

  /// Get a single company by ID
  Future<Result<Company>> getCompanyById(int id);

  /// Search companies by query
  Future<Result<List<Company>>> searchCompanies(String query);

  /// Filter companies by criteria
  Future<Result<List<Company>>> filterCompanies(CompanyFilter filter);

  /// Search and filter companies in combination
  Future<Result<List<Company>>> searchAndFilterCompanies(
    String query,
    CompanyFilter filter,
  );

  /// Clear cached company data
  Future<void> clearCache();
}
