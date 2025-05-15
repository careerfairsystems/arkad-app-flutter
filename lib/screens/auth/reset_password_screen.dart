import 'package:arkad/config/theme_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme_config.dart';

import '../../utils/validation_utils.dart';
import '../../widgets/auth/auth_form_widgets.dart';
import '../../providers/auth_provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isEmailValid = false;
  bool _isLoading = false;
  bool _isReset = false;
  String? _errorMessage;
  bool _serverError = false;
  String? _serverErrorText = 'Something went wrong. Please try again.';
  String? _emailErrorText;

  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
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

  Future<void> _submitEmailResetPassword() async {
    if (!_validateFields()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final success = await authProvider.resetPassword(
        _emailController.text.trim(),
      );

      if (success) {
        setState(() {
          _isReset = true;
          _serverError = false;
        });
      } else {
        setState(() {
          _serverError = true;
          _isReset = false;
        });
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      return;
    }
  }

  bool _validateFields() {
    bool isValid = true;

    setState(() {
      _emailErrorText = null;

      if (_emailController.text.isEmpty) {
        _emailErrorText = 'Email is required';
        isValid = false;
      } else if (!ValidationUtils.isValidEmail(_emailController.text)) {
        _emailErrorText = 'Please enter a valid email';
        isValid = false;
      }
    });

    return isValid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Align(
        alignment: FractionalOffset(0.5, 0.4), // x: center, y: 1/3 from top
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: _isReset ? _buildSuccessView() : _buildFormView(),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.check_circle, color: Colors.green, size: 80),
        AuthFormWidgets.buildSuccessMessage(
          'Reset link sent to: ${_emailController.text}',
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 130,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ArkadColors.arkadTurkos,
              foregroundColor: ArkadColors.white,
              minimumSize: const Size(double.infinity, 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Back to login",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthFormWidgets.buildHeading(
          'Reset password',
          'Enter your email to reset your password',
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
          validator: ValidationUtils.validateEmail,
        ),
        const SizedBox(height: 15),
        AuthFormWidgets.buildSubmitButton(
          text: "Submit",
          onPressed: _submitEmailResetPassword,
          isLoading: _isLoading,
        ),
        if (_serverError) AuthFormWidgets.buildErrorMessage(_serverErrorText),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateEmail);
    super.dispose();
  }
}
