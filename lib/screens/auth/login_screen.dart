import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme_config.dart';
import '../../providers/auth_provider.dart';
import '../profile/profile_screen.dart';

/// Login screen for user authentication.
///
/// Provides email and password fields, error handling, and navigation to signup/reset password.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  /// Handles login logic and navigation on success.
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        if (success) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => ProfileScreen(user: authProvider.user!),
            ),
            (route) => false,
          );
        } else if (authProvider.error != null) {
          setState(() => _errorMessage = authProvider.error);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Navigates to the signup screen.
  void _navigateToSignup() {
    Navigator.of(context).pushNamed('/auth/signup');
  }

  /// Navigates to the reset password screen.
  void _navigateToResetPassword() {
    Navigator.of(context).pushNamed('/auth/reset-password');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // App logo
                Center(
                  child: Image.asset(
                    'assets/icons/arkad_logo_inverted.png',
                    height: 120,
                  ),
                ),
                const SizedBox(height: 40),
                // Welcome text
                Text(
                  'Welcome Back',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email, color: ArkadColors.arkadTurkos),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                // Password field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: Icon(Icons.lock, color: ArkadColors.arkadTurkos),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: ArkadColors.arkadTurkos,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                ),
                // Error message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: ArkadColors.lightRed),
                      textAlign: TextAlign.center,
                    ),
                  ),
                // Forgot password link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _navigateToResetPassword,
                    child: Text("Forgot password?"),
                  ),
                ),
                const SizedBox(height: 30),
                // Login button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ArkadColors.arkadTurkos,
                    foregroundColor: ArkadColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(ArkadColors.white),
                          ),
                        )
                      : const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _navigateToSignup,
                      child: Text(
                        "Sign up",
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
