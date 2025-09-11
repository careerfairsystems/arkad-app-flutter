import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../entities/company.dart';
import '../repositories/company_repository.dart';

/// Use case for retrieving a specific company by ID
class GetCompanyByIdUseCase extends UseCase<Company, int> {
  const GetCompanyByIdUseCase(this._repository);

  final CompanyRepository _repository;

  @override
  Future<Result<Company>> call(int companyId) {
    return _repository.getCompanyById(companyId);
  }
}
