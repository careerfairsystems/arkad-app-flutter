import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../entities/company.dart';
import '../repositories/company_repository.dart';

/// Use case for retrieving all companies
class GetCompaniesUseCase extends UseCase<List<Company>, GetCompaniesParams> {
  const GetCompaniesUseCase(this._repository);

  final CompanyRepository _repository;

  @override
  Future<Result<List<Company>>> call(GetCompaniesParams params) {
    return _repository.getCompanies(forceRefresh: params.forceRefresh);
  }
}

/// Parameters for GetCompaniesUseCase
class GetCompaniesParams {
  const GetCompaniesParams({this.forceRefresh = false});

  final bool forceRefresh;
}