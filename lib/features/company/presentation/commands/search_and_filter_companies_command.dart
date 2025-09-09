import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../shared/errors/app_error.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/entities/company.dart';
import '../../domain/use_cases/search_and_filter_companies_use_case.dart';

/// Command for searching and filtering companies simultaneously
class SearchAndFilterCompaniesCommand extends ParameterizedCommand<SearchAndFilterParams, List<Company>> {
  SearchAndFilterCompaniesCommand(this._useCase);

  final SearchAndFilterCompaniesUseCase _useCase;

  @override
  Future<void> executeWithParams(SearchAndFilterParams params) async {
    setExecuting(true);

    try {
      final result = await _useCase.call(params);

      result.when(
        success: (companies) => setResult(companies),
        failure: (error) => setError(error),
      );
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      setError(UnknownError(e.toString()));
    } finally {
      setExecuting(false);
    }
  }

  /// Convenience method for searching and filtering companies
  Future<void> searchAndFilterCompanies(String query, CompanyFilter filter) {
    return executeWithParams(SearchAndFilterParams(
      query: query,
      filter: filter,
    ));
  }
}