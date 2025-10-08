import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/domain/validation/validation_service.dart';
import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/auth_form_widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEmailValid = false;
  String? _emailErrorText;

  final TextEditingController _emailController = TextEditingController();

  // 30s resend cooldown
  int _resendCooldownSeconds = 0;
  Timer? _resendCooldownTimer;
  bool get _isResendOnCooldown => _resendCooldownSeconds > 0;

  void _startResendCooldown([int seconds = 30]) {
    _resendCooldownTimer?.cancel();
    setState(() {
      _resendCooldownSeconds = seconds;
    });
    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldownSeconds <= 1) {
        timer.cancel();
        setState(() {
          _resendCooldownSeconds = 0;
        });
      } else {
        setState(() {
          _resendCooldownSeconds--;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);

    // Reset command state when entering screen to prevent stale success display
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      authViewModel.resetPasswordCommand.reset();
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

  Future<void> _submitEmailResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_isResendOnCooldown) {
      return;
    }

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    await authViewModel.resetPassword(_emailController.text.trim());

    if (mounted && !authViewModel.resetPasswordCommand.hasError) {
      _startResendCooldown();
    }
  }

  // Resend from success view (no form validation)
  Future<void> _resendResetEmail() async {
    if (_isResendOnCooldown) return;

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    await authViewModel.resetPassword(_emailController.text.trim());

    if (mounted && !authViewModel.resetPasswordCommand.hasError) {
      _startResendCooldown();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Align(
        alignment: const FractionalOffset(
          0.5,
          0.4,
        ), // x: center, y: 1/3 from top
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Consumer<AuthViewModel>(
              builder: (context, authViewModel, child) {
                if (authViewModel.resetPasswordCommand.isCompleted) {
                  return _buildSuccessView();
                }
                return _buildFormView();
              },
            ),
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
          'Password reset link sent to ${_emailController.text}',
        ),
        Consumer<AuthViewModel>(
          builder: (context, authViewModel, child) {
            return TextButton(
              onPressed:
                  authViewModel.isResettingPassword || _isResendOnCooldown
                  ? null
                  : _resendResetEmail,
              style: TextButton.styleFrom(
                foregroundColor: ArkadColors.arkadTurkos,
              ),
              child: authViewModel.isResettingPassword
                  ? const Text('Sending...')
                  : (_isResendOnCooldown
                        ? Text('Resend again in $_resendCooldownSeconds')
                        : const Text("Didn't receive the email? Send again")),
            );
          },
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
          Consumer<AuthViewModel>(
            builder: (context, authViewModel, child) {
              return AuthFormWidgets.buildSubmitButton(
                text: _isResendOnCooldown
                    ? 'Resend again in $_resendCooldownSeconds'
                    : "Submit",
                onPressed:
                    authViewModel.isResettingPassword || _isResendOnCooldown
                    ? null
                    : _submitEmailResetPassword,
                isLoading: authViewModel.isResettingPassword,
              );
            },
          ),
          Consumer<AuthViewModel>(
            builder: (context, authViewModel, child) {
              if (authViewModel.resetPasswordCommand.hasError) {
                return AuthFormWidgets.buildErrorMessage(
                  authViewModel.resetPasswordCommand.error!,
                  onDismiss: () =>
                      authViewModel.resetPasswordCommand.clearError(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateEmail);
    _emailController.dispose();
    _resendCooldownTimer?.cancel();
    super.dispose();
  }
}
