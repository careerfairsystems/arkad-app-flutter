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
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  // Step 1 controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  // Step 2 controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _foodPreferencesController = TextEditingController();

  bool _isLoading = false;
  bool _policyAccepted = false;
  String? _errorMessage;

  String? _emailErrorText;
  String? _passwordErrorText;
  String? _confirmPasswordErrorText;
  String? _policyErrorText;
  String? _firstNameErrorText;
  String? _lastNameErrorText;
  String? _foodPreferencesErrorText;

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
      if (_emailController.text.isNotEmpty) {
        _emailErrorText = null;
      }
    });
  }

  void _validatePassword() {
    setState(() {
      _passwordStrength = ValidationUtils.checkPasswordStrength(
        _passwordController.text,
      );
      _isPasswordValid = _passwordStrength.values.every((isValid) => isValid);

      if (_passwordController.text.isNotEmpty) {
        _passwordErrorText = null;
      }

      if (_confirmPasswordController.text.isNotEmpty) {
        _isConfirmPasswordValid = ValidationUtils.doPasswordsMatch(
          _passwordController.text,
          _confirmPasswordController.text,
        );
        _validateConfirmPassword();
      }
    });
  }

  void _validateConfirmPassword() {
    setState(() {
      _isConfirmPasswordValid = ValidationUtils.doPasswordsMatch(
        _passwordController.text,
        _confirmPasswordController.text,
      );

      if (_confirmPasswordController.text.isNotEmpty) {
        if (_isConfirmPasswordValid) {
          _confirmPasswordErrorText = null;
        } else {
          _confirmPasswordErrorText = 'Passwords do not match';
        }
      } else if (_confirmPasswordErrorText != null) {
        _confirmPasswordErrorText = null;
      }
    });
  }

  bool _validateStep1() {
    bool isValid = true;
    setState(() {
      _emailErrorText = null;
      _passwordErrorText = null;
      _confirmPasswordErrorText = null;
      _policyErrorText = null;

      if (_emailController.text.isEmpty) {
        _emailErrorText = 'Email is required';
        isValid = false;
      } else if (!ValidationUtils.isValidEmail(_emailController.text)) {
        _emailErrorText = 'Please enter a valid email';
        isValid = false;
      }

      if (_passwordController.text.isEmpty) {
        _passwordErrorText = 'Password is required';
        isValid = false;
      } else if (!_isPasswordValid) {
        _passwordErrorText = 'Password does not meet requirements';
        isValid = false;
      }

      if (_confirmPasswordController.text.isEmpty) {
        _confirmPasswordErrorText = 'Please confirm your password';
        isValid = false;
      } else if (!_isConfirmPasswordValid) {
        _confirmPasswordErrorText = 'Passwords do not match';
        isValid = false;
      }

      if (!_policyAccepted) {
        _policyErrorText = 'You must accept the privacy policy';
        isValid = false;
      }
    });
    return isValid;
  }

  bool _validateStep2() {
    bool isValid = true;
    setState(() {
      _firstNameErrorText = null;
      _lastNameErrorText = null;
      _foodPreferencesErrorText = null;
      if (_firstNameController.text.isEmpty) {
        _firstNameErrorText = 'First name is required';
        isValid = false;
      }
      if (_lastNameController.text.isEmpty) {
        _lastNameErrorText = 'Last name is required';
        isValid = false;
      }
      if (_foodPreferencesController.text.isEmpty) {
        _foodPreferencesErrorText = 'Food preference is required';
        isValid = false;
      }
    });
    return isValid;
  }

  void _nextStep() {
    if (_currentStep == 0 && _validateStep1()) {
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1 && _validateStep2()) {
      _handleSignup();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _handleSignup() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final success = await authProvider.initialSignUp(
        _emailController.text.trim(),
        _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        foodPreferences: _foodPreferencesController.text.trim(),
      );
      if (mounted) {
        if (success) {
          await context.push(
            '/auth/verification?email=${Uri.encodeComponent(_emailController.text.trim())}',
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

  void _navigateToLogin() {
    context.pop();
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthFormWidgets.buildLogoHeader(),
        AuthFormWidgets.buildHeading(
          'Create Account',
          'Sign up to get started',
        ),
        AuthFormWidgets.buildEmailField(
          _emailController,
          isValid: _emailController.text.isNotEmpty ? _isEmailValid : null,
          onChanged: (value) {
            if (_emailErrorText != null) {
              setState(() => _emailErrorText = null);
            }
          },
          errorText: _emailErrorText,
        ),
        const SizedBox(height: 20),
        AuthFormWidgets.buildPasswordField(
          _passwordController,
          isValid:
              _passwordController.text.isNotEmpty ? _isPasswordValid : null,
          onChanged: (value) {
            if (_passwordErrorText != null) {
              setState(() => _passwordErrorText = null);
            }
          },
          errorText: _passwordErrorText,
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
          isValid:
              _confirmPasswordController.text.isNotEmpty
                  ? _isConfirmPasswordValid
                  : null,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _nextStep(),
          onChanged: (value) {
            if (_confirmPasswordErrorText != null) {
              setState(() => _confirmPasswordErrorText = null);
            }
          },
          errorText: _confirmPasswordErrorText,
        ),
        const SizedBox(height: 20),
        AuthFormWidgets.buildCheckboxWithError(
          value: _policyAccepted,
          onChanged: (value) {
            setState(() {
              _policyAccepted = value ?? false;
              if (_policyAccepted && _policyErrorText != null) {
                _policyErrorText = null;
              }
            });
          },
          errorText: _policyErrorText,
          label: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('I accept the ', style: TextStyle(fontSize: 12)),
              GestureDetector(
                onTap: () async {
                  final url = Uri.parse(
                    'https://www.arkadtlth.se/privacypolicy',
                  );
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
        AuthFormWidgets.buildErrorMessage(_errorMessage),
        const SizedBox(height: 30),
        AuthFormWidgets.buildSubmitButton(
          text: 'Continue',
          onPressed: _isLoading ? null : _nextStep,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 24),
        AuthFormWidgets.buildAuthLinkRow(
          question: "Already have an account?",
          linkText: "Sign in",
          onPressed: _navigateToLogin,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthFormWidgets.buildLogoHeader(),
        AuthFormWidgets.buildHeading(
          'Personal Details',
          'Tell us more about you',
        ),
        TextFormField(
          controller: _firstNameController,
          decoration: InputDecoration(
            labelText: 'First Name',
            errorText: _firstNameErrorText,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _lastNameController,
          decoration: InputDecoration(
            labelText: 'Last Name',
            errorText: _lastNameErrorText,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _foodPreferencesController,
          decoration: InputDecoration(
            labelText: 'Food Preferences',
            errorText: _foodPreferencesErrorText,
            border: OutlineInputBorder(),
            helperText: 'Allergies, vegetarian, etc. or "None"',
          ),
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: AuthFormWidgets.buildSubmitButton(
                text: 'Back',
                onPressed: _isLoading ? null : _prevStep,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AuthFormWidgets.buildSubmitButton(
                text: 'Continue',
                onPressed: _isLoading ? null : _nextStep,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: _currentStep == 0 ? _buildStep1() : _buildStep2(),
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _foodPreferencesController.dispose();
    super.dispose();
  }
}
