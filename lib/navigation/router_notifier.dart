import 'package:flutter/foundation.dart';

import '../features/auth/domain/entities/user.dart';
import '../features/auth/presentation/view_models/auth_view_model.dart';

/// Router state notifier that bridges AuthViewModel with GoRouter
/// This allows GoRouter to react to authentication state changes in clean architecture
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._authViewModel) {
    _authViewModel.addListener(_onAuthStateChanged);
  }

  final AuthViewModel _authViewModel;

  /// Get current authentication status
  bool get isAuthenticated => _authViewModel.isAuthenticated;

  /// Get current user (if authenticated)
  User? get currentUser => _authViewModel.currentUser;

  /// Get authentication initialization status
  bool get isInitializing => _authViewModel.isInitializing;

  /// Handle authentication state changes
  void _onAuthStateChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _authViewModel.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}
