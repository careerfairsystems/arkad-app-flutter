import '../services/service_locator.dart';

/// Helper class to access services from the service locator
class ServiceHelper {
  /// Get a service from the service locator
  static T getService<T extends Object>() {
    return serviceLocator<T>();
  }

  /// Check if a service is registered in the locator
  static bool isRegistered<T extends Object>() {
    return serviceLocator.isRegistered<T>();
  }
}
