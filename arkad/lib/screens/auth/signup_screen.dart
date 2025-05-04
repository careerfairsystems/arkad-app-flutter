import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme_config.dart';
import 'package:url_launcher/url_launcher.dart';

/// Signup screen for new user registration.
///
/// Provides real-time validation, password requirements, and navigation to login.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _policyAccepted = false;
  String? _errorMessage;

  // Form validation states
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;

  // Regular expressions for validation
  final _emailRegExp = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');

  // Add these regex patterns for password validation
  final _upperCaseRegExp = RegExp(r'[A-Z]');
  final _lowerCaseRegExp = RegExp(r'[a-z]');
  final _numberRegExp = RegExp(r'[0-9]');
  final _specialCharRegExp = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  // Password minimum length constant
  static const int _passwordMinLength = 8;

  // Password validation results
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;
  bool _hasMinLength = false;

  @override
  void initState() {
    super.initState();

    // Add listeners for real-time validation
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  /// Builds a row for password requirement feedback.
  Widget _buildRequirementRow(bool isMet, String requirement) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.cancel,
            color: isMet ? ArkadColors.arkadGreen : ArkadColors.lightRed,
            size: 16.0,
          ),
          const SizedBox(width: 8.0),
          Text(
            requirement,
            style: TextStyle(
              fontSize: 12.0,
              color: isMet ? ArkadColors.arkadGreen : ArkadColors.lightRed,
            ),
          ),
        ],
      ),
    );
  }

  /// Validates the email field in real time.
  void _validateEmail() {
    setState(() {
      _isEmailValid = _emailRegExp.hasMatch(_emailController.text.trim());
    });
  }

  /// Validates the password field in real time.
  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= _passwordMinLength;
      _hasUppercase = _upperCaseRegExp.hasMatch(password);
      _hasLowercase = _lowerCaseRegExp.hasMatch(password);
      _hasNumber = _numberRegExp.hasMatch(password);
      _hasSpecialChar = _specialCharRegExp.hasMatch(password);

      // Password is valid if it meets all requirements
      _isPasswordValid = _hasMinLength &&
          _hasUppercase &&
          _hasLowercase &&
          _hasNumber &&
          _hasSpecialChar;

      // If confirm password was already entered, validate it again
      if (_confirmPasswordController.text.isNotEmpty) {
        _isConfirmPasswordValid =
            _confirmPasswordController.text == _passwordController.text;
      }
    });
  }

  /// Validates the confirm password field in real time.
  void _validateConfirmPassword() {
    setState(() {
      _isConfirmPasswordValid =
          _confirmPasswordController.text == _passwordController.text;
    });
  }

  bool get _isFormValid =>
      _isEmailValid &&
      _isPasswordValid &&
      _isConfirmPasswordValid &&
      _policyAccepted;

  /// Validates the form and shows errors for missing policy acceptance.
  bool _validateAndShowErrors() {
    if (!_formKey.currentState!.validate()) return false;
    if (!_policyAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the privacy policy'),
        ),
      );
      return false;
    }
    return true;
  }

  /// Navigates to the login screen.
  void _navigateToLogin() {
    Navigator.of(context).pop();
  }

  /// Handles signup logic and navigation on success.
  Future<void> _handleSignup() async {
    if (!_validateAndShowErrors()) return;
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final success = await authProvider.initialSignUp(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        if (success) {
          Navigator.of(context).pushNamed(
            '/auth/verification',
            arguments: {'email': _emailController.text.trim()},
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
                  'Create Account',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign up to get started',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Email field with real-time validation
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email, color: ArkadColors.arkadTurkos),
                    suffixIcon: _emailController.text.isNotEmpty
                        ? Icon(
                            _isEmailValid ? Icons.check_circle : Icons.error,
                            color: _isEmailValid ? ArkadColors.arkadGreen : ArkadColors.lightRed,
                          )
                        : null,
                    errorText: _emailController.text.isNotEmpty && !_isEmailValid
                        ? 'Please enter a valid email'
                        : null,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 20),

                // Password field with detailed validation feedback
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: Icon(Icons.lock, color: ArkadColors.arkadTurkos),
                    suffixIcon: _passwordController.text.isNotEmpty
                        ? Icon(
                            _isPasswordValid ? Icons.check_circle : Icons.error,
                            color: _isPasswordValid ? ArkadColors.arkadGreen : ArkadColors.lightRed,
                          )
                        : null,
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                ),

                // Password requirements indicator
                if (_passwordController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password must:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: ArkadColors.gray,
                          ),
                        ),
                        const SizedBox(height: 5),
                        _buildRequirementRow(_hasMinLength, 'Be at least 8 characters long'),
                        _buildRequirementRow(_hasUppercase, 'Contain an uppercase letter'),
                        _buildRequirementRow(_hasLowercase, 'Contain a lowercase letter'),
                        _buildRequirementRow(_hasNumber, 'Contain a number'),
                        _buildRequirementRow(_hasSpecialChar, 'Contain a special character'),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Confirm Password field
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Confirm your password',
                    prefixIcon: Icon(Icons.lock_outline, color: ArkadColors.arkadTurkos),
                    suffixIcon: _confirmPasswordController.text.isNotEmpty
                        ? Icon(
                            _isConfirmPasswordValid ? Icons.check_circle : Icons.error,
                            color: _isConfirmPasswordValid ? ArkadColors.arkadGreen : ArkadColors.lightRed,
                          )
                        : null,
                    errorText: _confirmPasswordController.text.isNotEmpty && !_isConfirmPasswordValid
                        ? 'Passwords do not match'
                        : null,
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSignup(),
                ),

                const SizedBox(height: 20),

                // Privacy Policy Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _policyAccepted,
                      onChanged: (value) {
                        setState(() {
                          _policyAccepted = value ?? false;
                        });
                      },
                      activeColor: ArkadColors.arkadTurkos,
                    ),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'I accept the ',
                            style: TextStyle(fontSize: 12),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final url = Uri.parse('https://www.arkadtlth.se/privacypolicy');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                            child: Text(
                              'privacy policy',
                              style: TextStyle(
                                color: ArkadColors.arkadTurkos,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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

                const SizedBox(height: 30),

                // Sign Up button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
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
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                const SizedBox(height: 24),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?",
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _navigateToLogin,
                      child: Text(
                        "Sign in",
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
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
