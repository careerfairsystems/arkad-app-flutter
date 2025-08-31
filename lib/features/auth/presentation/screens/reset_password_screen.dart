import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import '../../../../shared/domain/validation/validation_service.dart';
import '../widgets/auth_form_widgets.dart';
import '../../../../shared/presentation/themes/arkad_theme.dart';

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
      _isEmailValid = ValidationService.isValidEmail(_emailController.text);
      if (_emailController.text.isNotEmpty) {
        _emailErrorText = null;
      }
    });
  }

  Future<void> _submitEmailResetPassword() async {
    setState(() {
      _isLoading = true;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    try {
      await authViewModel.resetPassword(_emailController.text.trim());

      if (mounted) {
        if (authViewModel.globalError == null) {
          setState(() {
            _isReset = true;
            _serverError = false;
          });
        } else {
          setState(() {
            _serverError = true;
            _isReset = false;
            _serverErrorText = authViewModel.globalError!.userMessage;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _serverError = true;
          _isReset = false;
          _serverErrorText = 'Failed to reset password: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.check_circle, color: ArkadColors.arkadGreen, size: 80),
        AuthFormWidgets.buildSuccessMessage(
          'Reset link sent to: ${_emailController.text}',
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 130,
          child: ElevatedButton(
            onPressed: () => context.go('/auth/login'),
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
    return Form(
      key: _formKey,
      child: Column(
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
            validator: ValidationService.validateEmail,
          ),
          const SizedBox(height: 15),
          AuthFormWidgets.buildSubmitButton(
            text: "Submit",
            onPressed: _submitEmailResetPassword,
            isLoading: _isLoading,
          ),
          if (_serverError) AuthFormWidgets.buildErrorMessage(_serverErrorText),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateEmail);
    super.dispose();
  }
}
