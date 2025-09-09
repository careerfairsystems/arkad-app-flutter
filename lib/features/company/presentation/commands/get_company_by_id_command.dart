import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../shared/errors/app_error.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/entities/company.dart';
import '../../domain/use_cases/get_company_by_id_use_case.dart';

/// Command for getting a specific company by ID
class GetCompanyByIdCommand extends ParameterizedCommand<int, Company> {
  GetCompanyByIdCommand(this._useCase);

  final GetCompanyByIdUseCase _useCase;

  @override
  Future<void> executeWithParams(int companyId) async {
    setExecuting(true);

    try {
      final result = await _useCase.call(companyId);

      result.when(
        success: (company) => setResult(company),
        failure: (error) => setError(error),
      );
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      setError(UnknownError(e.toString()));
    } finally {
      setExecuting(false);
    }
  }

  /// Convenience method for getting company by ID
  Future<void> getCompanyById(int companyId) {
    return executeWithParams(companyId);
  }
}