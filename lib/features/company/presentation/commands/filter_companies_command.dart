import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../shared/errors/app_error.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/entities/company.dart';
import '../../domain/use_cases/filter_companies_use_case.dart';

/// Command for filtering companies by criteria
class FilterCompaniesCommand extends ParameterizedCommand<CompanyFilter, List<Company>> {
  FilterCompaniesCommand(this._useCase);

  final FilterCompaniesUseCase _useCase;

  @override
  Future<void> executeWithParams(CompanyFilter filter) async {
    setExecuting(true);

    try {
      final result = await _useCase.call(filter);

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

  /// Convenience method for filtering companies
  Future<void> filterCompanies(CompanyFilter filter) {
    return executeWithParams(filter);
  }
}