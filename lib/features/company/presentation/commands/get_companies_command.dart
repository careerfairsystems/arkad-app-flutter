import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../shared/errors/app_error.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/entities/company.dart';
import '../../domain/use_cases/get_companies_use_case.dart';

/// Command for loading all companies
class GetCompaniesCommand extends ParameterizedCommand<GetCompaniesParams, List<Company>> {
  GetCompaniesCommand(this._useCase);

  final GetCompaniesUseCase _useCase;

  @override
  Future<void> executeWithParams(GetCompaniesParams params) async {
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

  /// Convenience method for loading companies
  Future<void> loadCompanies({bool forceRefresh = false}) {
    return executeWithParams(GetCompaniesParams(forceRefresh: forceRefresh));
  }
}