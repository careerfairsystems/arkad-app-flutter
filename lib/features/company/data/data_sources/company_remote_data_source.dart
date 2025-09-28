import 'package:arkad_api/arkad_api.dart';
import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../api/extensions.dart';
import '../../../../shared/data/api_error_handler.dart';
import '../../domain/errors/company_errors.dart';

class CompanyRemoteDataSource {
  const CompanyRemoteDataSource(this._api);

  final ArkadApi _api;

  Future<List<CompanyOut>> getCompanies() async {
    try {
      final response = await _api.getCompaniesApi().companiesApiGetCompanies();

      if (response.isSuccess && response.data != null) {
        return response.data!.toList();
      } else {
        response.logResponse('getCompanies');
        throw CompanyLoadError(details: response.detailedError);
      }
    } on DioException catch (e) {
      final exception = await ApiErrorHandler.handleDioException(
        e,
        operationName: 'getCompanies',
      );
      throw exception;
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw CompanyLoadError(details: e.toString());
    }
  }

  Future<CompanyOut?> getCompanyById(int id) async {
    try {
      final companies = await getCompanies();
      return companies.firstWhere((company) => company.id == id);
    } catch (e) {
      await Sentry.captureException(e);
      return null;
    }
  }
}
