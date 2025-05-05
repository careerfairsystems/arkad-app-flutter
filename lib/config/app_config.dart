import 'package:flutter/foundation.dart';

enum Environment { staging, production }

class AppConfig {
  // Singleton instance
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  // Current environment
  static Environment _environment = Environment.staging;

  // Environment setters and getters
  static void setEnvironment(Environment env) => _environment = env;
  static Environment get environment => _environment;

  // Base URL based on environment
  static String get baseUrl {
    switch (_environment) {
      case Environment.staging:
        return 'https://staging.backend.arkadtlth.se/api';
      case Environment.production:
        return '';
    }
  }

  // Timeout durations
  static const int connectionTimeoutSeconds = 30;
  static const int receiveTimeoutSeconds = 30;
}
