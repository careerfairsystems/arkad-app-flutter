import 'package:dio/dio.dart';

import '../../../../shared/errors/app_error.dart';
import '../../../../shared/errors/error_mapper.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/entities/company.dart';
import '../../domain/use_cases/search_and_filter_companies_use_case.dart';

class SearchAndFilterCompaniesCommand
    extends ParameterizedCommand<SearchAndFilterParams, List<Company>> {
  SearchAndFilterCompaniesCommand(this._useCase);

  final SearchAndFilterCompaniesUseCase _useCase;

  @override
  Future<void> executeWithParams(SearchAndFilterParams params) async {
    if (isExecuting) return;

    clearError();
    setExecuting(true);

    try {
      final result = await _useCase.call(params);

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
            operationContext: 'search_and_filter_companies',
          ),
        );
      } else {
        setError(UnknownError(e.toString()));
      }
    } finally {
      setExecuting(false);
    }
  }

  Future<void> searchAndFilterCompanies(String query, CompanyFilter filter) {
    return executeWithParams(
      SearchAndFilterParams(query: query, filter: filter),
    );
  }
}
