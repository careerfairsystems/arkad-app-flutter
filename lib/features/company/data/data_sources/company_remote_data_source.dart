import 'package:arkad_api/arkad_api.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../api/extensions.dart';
import '../../../../shared/errors/app_error.dart';
import '../../domain/errors/company_errors.dart';

/// Remote data source for company operations
class CompanyRemoteDataSource {
  const CompanyRemoteDataSource(this._api);

  final ArkadApi _api;

  /// Fetch all companies from the API
  Future<List<CompanyOut>> getCompanies() async {
    try {
      final response = await _api.getCompaniesApi().companiesApiGetCompanies();
      
      if (response.isSuccess && response.data != null) {
        return response.data!.toList();
      } else {
        throw CompanyLoadError(details: response.error);
      }
    } catch (e, stackTrace) {
      if (e is CompanyLoadError) rethrow;
      
      await Sentry.captureException(e, stackTrace: stackTrace);
      
      // Check for network/connection errors
      if (_isNetworkError(e)) {
        throw NetworkError(details: e.toString());
      }
      
      throw CompanyLoadError(details: e.toString());
    }
  }

  /// Get a specific company by ID from the loaded companies list
  Future<CompanyOut?> getCompanyById(int id) async {
    try {
      // For now, get all companies and find by ID
      // In a real app, there might be a specific endpoint for this
      final companies = await getCompanies();
      
      try {
        return companies.firstWhere((company) => company.id == id);
      } catch (e, stackTrace) {
        await Sentry.captureException(e, stackTrace: stackTrace);
        return null; // Company not found
      }
    } catch (e, stackTrace) {
      if (e is CompanyLoadError) rethrow;
      
      await Sentry.captureException(e, stackTrace: stackTrace);
      
      if (_isNetworkError(e)) {
        throw NetworkError(details: e.toString());
      }
      
      throw CompanyLoadError(details: e.toString());
    }
  }

  /// Check if an error is related to network connectivity
  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('socket');
  }
}