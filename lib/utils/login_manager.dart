import 'package:flutter/material.dart';

/// A utility class to manage login screen state across navigations
class LoginManager {
  static final TextEditingController emailController = TextEditingController();
  static final TextEditingController passwordController =
      TextEditingController();

  static void clearCredentials() {
    emailController.clear();
    passwordController.clear();
  }
}
