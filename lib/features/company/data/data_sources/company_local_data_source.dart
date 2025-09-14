import 'package:arkad_api/arkad_api.dart';

/// Simple in-memory data source for company caching
class CompanyLocalDataSource {
  CompanyLocalDataSource();

  List<CompanyOut>? _cachedCompanies;
  DateTime? _lastCacheTime;

  /// Cache expiration duration - extended for stable company data
  /// Company data rarely changes during career fair events
  static const Duration _cacheExpiration = Duration(hours: 24);

  /// Get cached companies if available and not expired
  List<CompanyOut>? getCachedCompanies() {
    if (_cachedCompanies == null || _lastCacheTime == null) {
      return null;
    }

    final now = DateTime.now();
    if (now.difference(_lastCacheTime!) > _cacheExpiration) {
      // Cache expired, clear it
      clearCache();
      return null;
    }

    return _cachedCompanies;
  }

  /// Cache companies data
  void cacheCompanies(List<CompanyOut> companies) {
    _cachedCompanies = companies;
    _lastCacheTime = DateTime.now();
  }

  /// Clear cached data
  void clearCache() {
    _cachedCompanies = null;
    _lastCacheTime = null;
  }

  /// Check if cache is valid (not expired)
  bool get hasCachedData =>
      _cachedCompanies != null &&
      _lastCacheTime != null &&
      DateTime.now().difference(_lastCacheTime!) <= _cacheExpiration;
}