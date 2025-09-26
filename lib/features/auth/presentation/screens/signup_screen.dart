import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/domain/validation/validation_service.dart';
import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/presentation/widgets/error/error_display.dart';
import '../../domain/entities/signup_data.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/auth_form_widgets.dart';

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

  // Step 2 controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _foodPreferencesController = TextEditingController();

  int _currentStep = 1;
  bool _policyAccepted = false;

  String? _emailErrorText;
  String? _passwordErrorText;
  String? _confirmPasswordErrorText;
  String? _policyErrorText;

  // Step 2 validation
  String? _firstNameErrorText;
  String? _lastNameErrorText;

  // Food preferences
  bool _hasFoodPreferences = false;

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

    // Add listeners for step 2 form fields
    _firstNameController.addListener(() => setState(() {}));
    _lastNameController.addListener(() => setState(() {}));
    _foodPreferencesController.addListener(() => setState(() {}));

    // Reset command state when entering screen to prevent stale state display
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      authViewModel.signUpCommand.reset();
      authViewModel.completeSignupCommand.reset();
    });
  }

  void _validateEmail() {
    setState(() {
      _isEmailValid = ValidationService.isValidEmail(_emailController.text);
      if (_emailController.text.isNotEmpty) {
        _emailErrorText = null;
      }
    });
  }

  void _validatePassword() {
    setState(() {
      _passwordStrength = ValidationService.checkPasswordStrength(
        _passwordController.text,
      );
      _isPasswordValid = _passwordStrength.values.every((isValid) => isValid);

      if (_passwordController.text.isNotEmpty) {
        _passwordErrorText = null;
      }

      if (_confirmPasswordController.text.isNotEmpty) {
        _isConfirmPasswordValid = ValidationService.doPasswordsMatch(
          _passwordController.text,
          _confirmPasswordController.text,
        );
        _validateConfirmPassword();
      }
    });
  }

  void _validateConfirmPassword() {
    setState(() {
      _isConfirmPasswordValid = ValidationService.doPasswordsMatch(
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
      } else if (!_isEmailValid) {
        _emailErrorText = 'Enter a valid email';
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
      } else if (!ValidationService.doPasswordsMatch(
        _passwordController.text,
        _confirmPasswordController.text,
      )) {
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

  void _handleSubmit() {
    if (_currentStep == 1) {
      if (_validateStep1()) {
        setState(() => _currentStep = 2);
      }
    } else if (_currentStep == 2) {
      if (_validateStep2()) {
        _handleSignup();
      }
    }
  }

  bool _validateStep2() {
    bool isValid = true;
    setState(() {
      _firstNameErrorText = null;
      _lastNameErrorText = null;

      if (_firstNameController.text.trim().isEmpty) {
        _firstNameErrorText = 'First name is required';
        isValid = false;
      }

      if (_lastNameController.text.trim().isEmpty) {
        _lastNameErrorText = 'Last name is required';
        isValid = false;
      }

      if (_hasFoodPreferences &&
          _foodPreferencesController.text.trim().isEmpty) {
        isValid = false;
      }
    });
    return isValid;
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
    });
  }

  Future<void> _handleSignup() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    final signupData = SignupData(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      foodPreferences:
          _hasFoodPreferences
              ? (_foodPreferencesController.text.trim().isNotEmpty
                  ? _foodPreferencesController.text.trim()
                  : null)
              : null,
    );

    await authViewModel.startSignUp(signupData);

    if (mounted &&
        authViewModel.signUpCommand.isCompleted &&
        !authViewModel.signUpCommand.hasError) {
      // Complete autofill context to help password managers save credentials
      TextInput.finishAutofillContext();
      await context.push('/auth/verification');
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
        AuthFormWidgets.buildHeading('Sign up', 'Create your account'),
        AuthFormWidgets.buildEmailField(
          _emailController,
          isValid: _emailController.text.isNotEmpty ? _isEmailValid : null,
          onChanged: (value) {
            if (_emailErrorText != null) {
              setState(() => _emailErrorText = null);
            }
          },
          errorText: _emailErrorText,
          autofillHints: const [AutofillHints.email],
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
          autofillHints: const [AutofillHints.newPassword],
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
                  'Be at least ${ValidationService.passwordMinLength} characters long',
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
          onFieldSubmitted: (_) => _handleSubmit(),
          onChanged: (value) {
            if (_confirmPasswordErrorText != null) {
              setState(() => _confirmPasswordErrorText = null);
            }
          },
          errorText: _confirmPasswordErrorText,
          autofillHints: const [AutofillHints.newPassword],
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
        Consumer<AuthViewModel>(
          builder: (context, authViewModel, child) {
            final error = authViewModel.signUpCommand.error;
            if (error != null) {
              return Column(
                children: [
                  const SizedBox(height: 16),
                  ErrorDisplay(
                    error: error,
                    onDismiss: () => authViewModel.signUpCommand.clearError(),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(height: 30),
        Consumer<AuthViewModel>(
          builder: (context, authViewModel, child) {
            final canProceed =
                _emailController.text.isNotEmpty &&
                _isEmailValid &&
                _passwordController.text.isNotEmpty &&
                _isPasswordValid &&
                _confirmPasswordController.text.isNotEmpty &&
                _isConfirmPasswordValid &&
                _policyAccepted &&
                !authViewModel.signUpCommand.isExecuting;
            return AuthFormWidgets.buildSubmitButton(
              text: 'Continue',
              onPressed: canProceed ? _handleSubmit : null,
              isLoading: authViewModel.signUpCommand.isExecuting,
            );
          },
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
        AuthFormWidgets.buildHeading('Sign up', 'Tell us about yourself'),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _firstNameController,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.givenName],
                decoration: InputDecoration(
                  labelText: 'First name *',
                  hintText: 'Enter your first name',
                  errorText: _firstNameErrorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  if (_firstNameErrorText != null) {
                    setState(() => _firstNameErrorText = null);
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _lastNameController,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.familyName],
                decoration: InputDecoration(
                  labelText: 'Last name *',
                  hintText: 'Enter your last name',
                  errorText: _lastNameErrorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  if (_lastNameErrorText != null) {
                    setState(() => _lastNameErrorText = null);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        CheckboxListTile(
          value: _hasFoodPreferences,
          onChanged: (value) {
            setState(() {
              _hasFoodPreferences = value ?? false;
              if (!_hasFoodPreferences) {
                _foodPreferencesController.clear();
              }
            });
          },
          title: Text(
            'I have food preferences',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        if (_hasFoodPreferences) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _foodPreferencesController,
            textInputAction: TextInputAction.done,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Food preferences *',
              hintText: 'e.g., Vegetarian, allergic to nuts, etc.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            onFieldSubmitted: (_) => _handleSubmit(),
          ),
        ],
        Consumer<AuthViewModel>(
          builder: (context, authViewModel, child) {
            final error = authViewModel.signUpCommand.error;
            if (error != null) {
              return Column(
                children: [
                  const SizedBox(height: 16),
                  ErrorDisplay(
                    error: error,
                    onDismiss: () => authViewModel.signUpCommand.clearError(),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => _goToStep(1),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Consumer<AuthViewModel>(
                builder: (context, authViewModel, child) {
                  final canComplete =
                      _firstNameController.text.trim().isNotEmpty &&
                      _lastNameController.text.trim().isNotEmpty &&
                      (!_hasFoodPreferences ||
                          _foodPreferencesController.text.trim().isNotEmpty) &&
                      !authViewModel.signUpCommand.isExecuting;
                  return AuthFormWidgets.buildSubmitButton(
                    text: 'Complete',
                    onPressed: canComplete ? _handleSubmit : null,
                    isLoading: authViewModel.signUpCommand.isExecuting,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _currentStep == 1 ? _buildStep1() : _buildStep2(),
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _foodPreferencesController.dispose();
    super.dispose();
  }
}
