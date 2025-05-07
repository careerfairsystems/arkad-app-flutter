import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme_config.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validation_utils.dart';
import '../../widgets/auth/auth_form_widgets.dart';

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

  // Password validation results
  Map<String, bool> _passwordStrength = {
    'minLength': false,
    'hasUppercase': false,
    'hasLowercase': false,
    'hasNumber': false,
    'hasSpecialChar': false,
  };

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  void _validateEmail() {
    setState(() {
      _isEmailValid = ValidationUtils.isValidEmail(_emailController.text);
    });
  }

  void _validatePassword() {
    setState(() {
      _passwordStrength =
          ValidationUtils.checkPasswordStrength(_passwordController.text);
      _isPasswordValid = _passwordStrength.values.every((isValid) => isValid);

      if (_confirmPasswordController.text.isNotEmpty) {
        _isConfirmPasswordValid = ValidationUtils.doPasswordsMatch(
            _passwordController.text, _confirmPasswordController.text);
      }
    });
  }

  void _validateConfirmPassword() {
    setState(() {
      _isConfirmPasswordValid = ValidationUtils.doPasswordsMatch(
          _passwordController.text, _confirmPasswordController.text);
    });
  }

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

  void _navigateToLogin() {
    context.pop(); // Use GoRouter navigation
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
        if (success) {
          await context.push(
              '/auth/verification?email=${Uri.encodeComponent(_emailController.text.trim())}');
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
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthFormWidgets.buildLogoHeader(),
                AuthFormWidgets.buildHeading(
                  'Create Account',
                  'Sign up to get started',
                ),
                AuthFormWidgets.buildEmailField(
                  _emailController,
                  isValid:
                      _emailController.text.isNotEmpty ? _isEmailValid : null,
                  onChanged: (_) => _formKey.currentState?.validate(),
                ),
                const SizedBox(height: 20),
                AuthFormWidgets.buildPasswordField(
                  _passwordController,
                  isValid: _passwordController.text.isNotEmpty
                      ? _isPasswordValid
                      : null,
                ),
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
                        AuthFormWidgets.buildPasswordRequirementRow(
                          _passwordStrength['minLength']!,
                          'Be at least ${ValidationUtils.passwordMinLength} characters long',
                        ),
                        AuthFormWidgets.buildPasswordRequirementRow(
                          _passwordStrength['hasUppercase']!,
                          'Contain an uppercase letter',
                        ),
                        AuthFormWidgets.buildPasswordRequirementRow(
                          _passwordStrength['hasLowercase']!,
                          'Contain a lowercase letter',
                        ),
                        AuthFormWidgets.buildPasswordRequirementRow(
                          _passwordStrength['hasNumber']!,
                          'Contain a number',
                        ),
                        AuthFormWidgets.buildPasswordRequirementRow(
                          _passwordStrength['hasSpecialChar']!,
                          'Contain a special character',
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                AuthFormWidgets.buildPasswordField(
                  _confirmPasswordController,
                  labelText: 'Confirm Password',
                  hintText: 'Confirm your password',
                  isValid: _confirmPasswordController.text.isNotEmpty
                      ? _isConfirmPasswordValid
                      : null,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSignup(),
                ),

                const SizedBox(height: 20),

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
                              final url = Uri.parse(
                                  'https://www.arkadtlth.se/privacypolicy');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url,
                                    mode: LaunchMode.externalApplication);
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

                AuthFormWidgets.buildErrorMessage(_errorMessage),

                const SizedBox(height: 30),

                AuthFormWidgets.buildSubmitButton(
                  text: 'Sign Up',
                  onPressed: _handleSignup,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 24),

                AuthFormWidgets.buildAuthLinkRow(
                  question: "Already have an account?",
                  linkText: "Sign in",
                  onPressed: _navigateToLogin,
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
