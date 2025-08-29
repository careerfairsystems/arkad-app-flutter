import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../utils/login_manager.dart';
import '../../utils/validation_utils.dart';
import '../../view_models/auth_model.dart';
import '../../widgets/auth/auth_form_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = LoginManager.emailController;
  final _passwordController = LoginManager.passwordController;

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _isEmailValid = false;

  String? _emailErrorText;
  String? _passwordErrorText;

  @override
  void initState() {
    super.initState();
    LoginManager.clearCredentials();
    _emailController.addListener(_validateEmail);
  }

  void _validateEmail() {
    setState(() {
      _isEmailValid = ValidationUtils.isValidEmail(_emailController.text);
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
      } else if (!ValidationUtils.isValidEmail(_emailController.text)) {
        _emailErrorText = 'Please enter a valid email';
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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthModel>(context, listen: false);
    try {
      final success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        if (success) {
          context.go('/companies');
        } else if (authProvider.error != null) {
          setState(() => _errorMessage = authProvider.error!.userMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                  'Welcome Back',
                  'Sign in to continue',
                ),
                AuthFormWidgets.buildEmailField(
                  _emailController,
                  isValid:
                      _emailController.text.isNotEmpty ? _isEmailValid : null,
                  onChanged: (value) {
                    if (_emailErrorText != null) {
                      setState(() => _emailErrorText = null);
                    }
                  },
                  errorText: _emailErrorText,
                  validator: ValidationUtils.validateEmail,
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
                  validator: ValidationUtils.validateLoginPassword,
                ),

                AuthFormWidgets.buildErrorMessage(_errorMessage),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/auth/reset-password'),
                    child: const Text("Forgot password?"),
                  ),
                ),

                const SizedBox(height: 30),

                AuthFormWidgets.buildSubmitButton(
                  text: 'Sign In',
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
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
    );
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateEmail);
    super.dispose();
  }
}
