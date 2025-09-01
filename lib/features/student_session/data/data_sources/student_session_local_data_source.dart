/// Local data source for caching student session data
class StudentSessionLocalDataSource {
  // For now, this is a simple in-memory cache
  // In the future, this could use a database like Hive or SQLite
  
  List<Map<String, dynamic>>? _cachedApplications;
  
  /// Cache student session applications
  void cacheApplications(List<Map<String, dynamic>> applications) {
    _cachedApplications = applications;
  }
  
  /// Get cached applications
  List<Map<String, dynamic>>? getCachedApplications() {
    return _cachedApplications;
  }
  
  /// Clear cached data
  void clearCache() {
    _cachedApplications = null;
  }
  
  /// Check if cache is valid (for now, always false - no expiry logic)
  bool get isCacheValid => _cachedApplications != null;
}