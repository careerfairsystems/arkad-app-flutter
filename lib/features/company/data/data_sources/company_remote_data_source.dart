import 'package:arkad_api/arkad_api.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../api/extensions.dart';
import '../../domain/errors/company_errors.dart';

class CompanyRemoteDataSource {
  const CompanyRemoteDataSource(this._api);

  final ArkadApi _api;

  Future<List<CompanyOut>> getCompanies() async {
    final response = await _api.getCompaniesApi().companiesApiGetCompanies();

    if (response.isSuccess && response.data != null) {
      return response.data!.toList();
    } else {
      throw CompanyLoadError(details: response.error);
    }
  }

  Future<CompanyOut?> getCompanyById(int id) async {
    final companies = await getCompanies();

    try {
      return companies.firstWhere((company) => company.id == id);
    } catch (e) {
      return null;
    }
  }
}
