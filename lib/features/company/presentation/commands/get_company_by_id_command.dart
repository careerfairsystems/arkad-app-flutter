import 'package:dio/dio.dart';

import '../../../../shared/errors/error_mapper.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/entities/company.dart';
import '../../domain/use_cases/get_company_by_id_use_case.dart';

class GetCompanyByIdCommand extends ParameterizedCommand<int, Company> {
  GetCompanyByIdCommand(this._useCase);

  final GetCompanyByIdUseCase _useCase;

  @override
  Future<void> executeWithParams(int companyId) async {
    if (isExecuting) return;

    clearError();
    setExecuting(true);

    try {
      final result = await _useCase.call(companyId);

      result.when(
        success: (company) => setResult(company),
        failure: (error) => setError(error),
      );
    } catch (e) {
      if (e is DioException) {
        setError(
          ErrorMapper.fromDioException(
            e,
            null,
            operationContext: 'get_company_by_id',
          ),
        );
      } else {
        setError(
          ErrorMapper.fromException(
            e,
            null,
            operationContext: 'get_company_by_id',
          ),
        );
      }
    } finally {
      setExecuting(false);
    }
  }

  Future<void> getCompanyById(int companyId) {
    return executeWithParams(companyId);
  }
}
