import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../shared/errors/app_error.dart';
import 'package:dio/dio.dart';

import '../../../../shared/errors/error_mapper.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/entities/company.dart';
import '../../domain/use_cases/get_companies_use_case.dart';

class GetCompaniesCommand
    extends ParameterizedCommand<GetCompaniesParams, List<Company>> {
  GetCompaniesCommand(this._useCase);

  final GetCompaniesUseCase _useCase;

  @override
  Future<void> executeWithParams(GetCompaniesParams params) async {
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
            operationContext: 'get_companies',
          ),
        );
      } else {
        setError(
          ErrorMapper.fromException(e, null, operationContext: 'get_companies'),
        );
      }
    } finally {
      setExecuting(false);
    }
  }

  Future<void> loadCompanies({bool forceRefresh = false}) {
    return executeWithParams(GetCompaniesParams(forceRefresh: forceRefresh));
  }
}
