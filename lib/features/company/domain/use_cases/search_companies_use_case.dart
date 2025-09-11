import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../entities/company.dart';
import '../repositories/company_repository.dart';

/// Use case for searching companies by query
class SearchCompaniesUseCase extends UseCase<List<Company>, String> {
  const SearchCompaniesUseCase(this._repository);

  final CompanyRepository _repository;

  @override
  Future<Result<List<Company>>> call(String query) {
    return _repository.searchCompanies(query);
  }
}
