import 'package:dio/dio.dart';

import '../../../../shared/errors/error_mapper.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/entities/company.dart';
import '../../domain/use_cases/search_companies_use_case.dart';

class SearchCompaniesCommand
    extends ParameterizedCommand<String, List<Company>> {
  SearchCompaniesCommand(this._useCase);

  final SearchCompaniesUseCase _useCase;

  @override
  Future<void> executeWithParams(String query) async {
    if (isExecuting) return;

    clearError();
    setExecuting(true);

    try {
      final result = await _useCase.call(query);

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
            operationContext: 'search_companies',
          ),
        );
      } else {
        setError(
          ErrorMapper.fromException(
            e,
            null,
            operationContext: 'search_companies',
          ),
        );
      }
    } finally {
      setExecuting(false);
    }
  }

  Future<void> searchCompanies(String query) {
    return executeWithParams(query);
  }
}
