import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart'; // Add go_router import

import '../../config/theme_config.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/auth_form_widgets.dart';

/// Verification screen for email confirmation during authentication.
///
/// Allows the user to enter or paste a 6-digit code sent to their email.
class VerificationScreen extends StatefulWidget {
  final String email;

  const VerificationScreen({super.key, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  bool get _isCodeComplete => _codeController.text.length == 6;

  Future<void> _verifyCode() async {
    if (!_isCodeComplete) return;
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final success = await authProvider.completeSignup(_codeController.text);
      if (mounted) {
        if (success) {
          context.go('/profile');
        } else if (authProvider.error != null) {
          setState(() => _errorMessage = authProvider.error);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final success =
          await authProvider.requestNewVerificationCode(widget.email);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('A new verification code has been sent')));
        } else if (authProvider.error != null) {
          setState(() => _errorMessage = authProvider.error);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(
            () => _errorMessage = 'Failed to resend code: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                AuthFormWidgets.buildLogoHeader(),

                AuthFormWidgets.buildHeading(
                  'Verify Your Email',
                  "We've sent a verification code to",
                ),

                Text(
                  widget.email,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Verification Code',
                    hintText: 'Enter 6-digit code',
                    counterText: '',
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  onChanged: (_) => setState(() {}),
                  autofillHints: const [AutofillHints.oneTimeCode],
                ),

                AuthFormWidgets.buildErrorMessage(_errorMessage),

                const SizedBox(height: 40),

                AuthFormWidgets.buildSubmitButton(
                  text: 'Verify',
                  onPressed:
                      _isVerifying || !_isCodeComplete ? null : _verifyCode,
                  isLoading: _isVerifying,
                ),

                const SizedBox(height: 24),

                TextButton(
                  onPressed: _isResending ? null : _resendCode,
                  child: _isResending
                      ? const Text('Sending...')
                      : const Text("Didn't receive the code? Send again"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
