import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../shared/errors/app_error.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/entities/company.dart';
import '../../domain/use_cases/search_companies_use_case.dart';

/// Command for searching companies by query
class SearchCompaniesCommand extends ParameterizedCommand<String, List<Company>> {
  SearchCompaniesCommand(this._useCase);

  final SearchCompaniesUseCase _useCase;

  @override
  Future<void> executeWithParams(String query) async {
    setExecuting(true);

    try {
      final result = await _useCase.call(query);

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

  /// Convenience method for searching companies
  Future<void> searchCompanies(String query) {
    return executeWithParams(query);
  }
}