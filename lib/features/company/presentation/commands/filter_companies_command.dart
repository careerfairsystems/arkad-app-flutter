import 'package:dio/dio.dart';

import '../../../../shared/errors/error_mapper.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/entities/company.dart';
import '../../domain/use_cases/filter_companies_use_case.dart';

class FilterCompaniesCommand
    extends ParameterizedCommand<CompanyFilter, List<Company>> {
  FilterCompaniesCommand(this._useCase);

  final FilterCompaniesUseCase _useCase;

  @override
  Future<void> executeWithParams(CompanyFilter filter) async {
    if (isExecuting) return;

    clearError();
    setExecuting(true);

    try {
      final result = await _useCase.call(filter);

      result.when(
        success: (companies) => setResult(companies),
        failure: (error) => setError(error),
      );
    } catch (e) {
      if (e is DioException) {
        setError(
          ErrorMapper.fromDioException(
            e,
            null,
            operationContext: 'filter_companies',
          ),
        );
      } else {
        setError(
          ErrorMapper.fromException(
            e,
            null,
            operationContext: 'filter_companies',
          ),
        );
      }
    } finally {
      setExecuting(false);
    }
  }

  Future<void> filterCompanies(CompanyFilter filter) {
    return executeWithParams(filter);
  }
}
