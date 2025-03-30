import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'verification_screen.dart';

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

  // Add this missing method
  Widget _buildRequirementRow(bool isMet, String requirement) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.cancel,
            color: isMet ? Colors.green : Colors.red,
            size: 16.0,
          ),
          const SizedBox(width: 8.0),
          Text(
            requirement,
            style: TextStyle(
              fontSize: 12.0,
              color: isMet ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _validateEmail() {
    setState(() {
      _isEmailValid = _emailRegExp.hasMatch(_emailController.text.trim());
    });
  }

  // Update the _validatePassword method to check all requirements
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

  bool _validateAndShowErrors() {
    if (!_formKey.currentState!.validate()) return false;
    if (!_policyAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please accept the privacy policy and terms of service'),
        ),
      );
      return false;
    }
    return true;
  }

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
        setState(() => _isLoading = false);

        if (success) {
          // Navigate to verification screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationScreen(
                email: _emailController.text.trim(),
              ),
            ),
          );
        } else if (authProvider.error != null) {
          setState(() => _errorMessage = authProvider.error);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),

              // Email field with real-time validation
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                  suffixIcon: _emailController.text.isNotEmpty
                      ? Icon(
                          _isEmailValid ? Icons.check_circle : Icons.error,
                          color: _isEmailValid ? Colors.green : Colors.red,
                        )
                      : null,
                  // Use errorText for real-time feedback instead of validator
                  errorText: _emailController.text.isNotEmpty && !_isEmailValid
                      ? 'Please enter a valid email'
                      : null,
                ),
                keyboardType: TextInputType.emailAddress,
                // Remove validator as we're using errorText instead
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 16),

              // Password field with detailed validation feedback
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: _passwordController.text.isNotEmpty
                      ? Icon(
                          _isPasswordValid ? Icons.check_circle : Icons.error,
                          color: _isPasswordValid ? Colors.green : Colors.red,
                        )
                      : null,
                  // No errorText needed here as we show detailed requirements below
                ),
                obscureText: true,
                // Remove validator as detailed requirements are shown separately
                textInputAction: TextInputAction.next,
              ),

              // Password requirements indicator
              if (_passwordController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Password must:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 5),
                      _buildRequirementRow(
                          _hasMinLength, 'Be at least 8 characters'),
                      _buildRequirementRow(_hasUppercase,
                          'Contain at least one uppercase letter'),
                      _buildRequirementRow(_hasLowercase,
                          'Contain at least one lowercase letter'),
                      _buildRequirementRow(
                          _hasNumber, 'Contain at least one number'),
                      _buildRequirementRow(_hasSpecialChar,
                          'Contain at least one special character'),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Confirm password field with real-time validation
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: _confirmPasswordController.text.isNotEmpty
                      ? Icon(
                          _isConfirmPasswordValid
                              ? Icons.check_circle
                              : Icons.error,
                          color: _isConfirmPasswordValid
                              ? Colors.green
                              : Colors.red,
                        )
                      : null,
                  // Use errorText for real-time feedback
                  errorText: _confirmPasswordController.text.isNotEmpty &&
                          !_isConfirmPasswordValid
                      ? 'Passwords do not match'
                      : null,
                ),
                obscureText: true,
                // Remove validator as we're using errorText
                textInputAction: TextInputAction.done,
              ),

              const SizedBox(height: 20),

              // Terms & Policy checkbox with clearer text
              CheckboxListTile(
                title: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    children: const [
                      TextSpan(
                        text: 'I agree to the ',
                      ),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: ' and ',
                      ),
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                value: _policyAccepted,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  setState(() {
                    _policyAccepted = value ?? false;
                  });
                },
              ),

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 30),

              // Sign up button - disabled until form is valid
              ElevatedButton(
                onPressed: (_isFormValid && !_isLoading) ? _handleSignup : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 20),

              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateEmail);
    _passwordController.removeListener(_validatePassword);
    _confirmPasswordController.removeListener(_validateConfirmPassword);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
