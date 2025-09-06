import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../entities/company.dart';
import '../repositories/company_repository.dart';

/// Use case for combining search and filter operations
class SearchAndFilterCompaniesUseCase
    extends UseCase<List<Company>, SearchAndFilterParams> {
  const SearchAndFilterCompaniesUseCase(this._repository);

  final CompanyRepository _repository;

  @override
  Future<Result<List<Company>>> call(SearchAndFilterParams params) {
    return _repository.searchAndFilterCompanies(params.query, params.filter);
  }
}

/// Parameters for SearchAndFilterCompaniesUseCase
class SearchAndFilterParams {
  const SearchAndFilterParams({required this.query, required this.filter});

  final String query;
  final CompanyFilter filter;
}
