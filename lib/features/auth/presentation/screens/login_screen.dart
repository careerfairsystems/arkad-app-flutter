import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/domain/validation/validation_service.dart';
import '../../../../shared/events/app_events.dart';
import '../../../../shared/events/auth_events.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/auth_form_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isEmailValid = false;

  String? _emailErrorText;
  String? _passwordErrorText;

  StreamSubscription? _logoutSubscription;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
    _subscribeToLogoutEvents();

    // Reset command state when entering screen to prevent stale state display
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      authViewModel.signInCommand.reset();
    });
  }

  void _subscribeToLogoutEvents() {
    _logoutSubscription = AppEvents.on<UserLoggedOutEvent>().listen((_) {
      _clearFormState();
    });
  }

  void _clearFormState() {
    if (mounted) {
      setState(() {
        _emailController.clear();
        _passwordController.clear();

        _isEmailValid = false;
        _emailErrorText = null;
        _passwordErrorText = null;

        _obscurePassword = true;
      });
    }
  }

  void _validateEmail() {
    setState(() {
      _isEmailValid = ValidationService.isValidEmail(_emailController.text);
      if (_emailController.text.isNotEmpty) {
        _emailErrorText = null;
      }
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  bool _validateFields() {
    bool isValid = true;

    setState(() {
      _emailErrorText = null;
      _passwordErrorText = null;

      if (_emailController.text.isEmpty) {
        _emailErrorText = 'Email is required';
        isValid = false;
      }

      if (_passwordController.text.isEmpty) {
        _passwordErrorText = 'Password is required';
        isValid = false;
      }
    });

    return isValid;
  }

  Future<void> _handleLogin() async {
    if (!_validateFields()) return;

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    await authViewModel.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (mounted && authViewModel.signInCommand.isCompleted) {
      // Complete autofill context to help password managers save credentials
      TextInput.finishAutofillContext();
      context.go('/profile');
    }
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthFormWidgets.buildLogoHeader(),
                  AuthFormWidgets.buildHeading(
                    'Welcome Back',
                    'Sign in to continue',
                  ),
                  AuthFormWidgets.buildEmailField(
                    _emailController,
                    isValid: _emailController.text.isNotEmpty
                        ? _isEmailValid
                        : null,
                    onChanged: (value) {
                      if (_emailErrorText != null) {
                        setState(() => _emailErrorText = null);
                      }
                    },
                    errorText: _emailErrorText,
                    validator: ValidationService.validateEmail,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 20),

                  AuthFormWidgets.buildPasswordField(
                    _passwordController,
                    obscureText: _obscurePassword,
                    onToggleVisibility: _togglePasswordVisibility,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    onChanged: (value) {
                      if (_passwordErrorText != null) {
                        setState(() => _passwordErrorText = null);
                      }
                    },
                    errorText: _passwordErrorText,
                    validator: ValidationService.validateLoginPassword,
                    autofillHints: const [AutofillHints.password],
                  ),

                  Consumer<AuthViewModel>(
                    builder: (context, authViewModel, child) {
                      return AuthFormWidgets.buildErrorMessage(
                        authViewModel.signInCommand.error?.userMessage,
                      );
                    },
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/auth/reset-password'),
                      child: const Text("Forgot password?"),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Consumer<AuthViewModel>(
                    builder: (context, authViewModel, child) {
                      return AuthFormWidgets.buildSubmitButton(
                        text: 'Sign In',
                        onPressed: authViewModel.signInCommand.isExecuting
                            ? null
                            : _handleLogin,
                        isLoading: authViewModel.signInCommand.isExecuting,
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  AuthFormWidgets.buildAuthLinkRow(
                    question: "Don't have an account?",
                    linkText: "Sign up",
                    onPressed: () => context.push('/auth/signup'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateEmail);
    _emailController.dispose();
    _passwordController.dispose();
    _logoutSubscription?.cancel();
    super.dispose();
  }
}
