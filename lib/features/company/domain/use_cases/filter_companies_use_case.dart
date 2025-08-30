import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../entities/company.dart';
import '../repositories/company_repository.dart';

/// Use case for filtering companies by criteria
class FilterCompaniesUseCase extends UseCase<List<Company>, CompanyFilter> {
  const FilterCompaniesUseCase(this._repository);

  final CompanyRepository _repository;

  @override
  Future<Result<List<Company>>> call(CompanyFilter filter) {
    return _repository.filterCompanies(filter);
  }
}