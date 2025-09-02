import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/auth_form_widgets.dart';

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
      _errorMessage = null;
    });
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    await authViewModel.completeSignUp(_codeController.text);
    
    if (mounted) {
      if (authViewModel.completeSignupCommand.isCompleted && authViewModel.completeSignupCommand.error == null) {
        context.go('/profile');
      } else if (authViewModel.completeSignupCommand.error != null) {
        setState(() => _errorMessage = authViewModel.completeSignupCommand.error!.userMessage);
      } else if (authViewModel.globalError != null) {
        setState(() => _errorMessage = authViewModel.globalError!.userMessage);
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _errorMessage = null;
    });
    
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    await authViewModel.resendVerification(widget.email);
    
    if (mounted) {
      if (authViewModel.resendVerificationCommand.isCompleted && !authViewModel.resendVerificationCommand.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent! Check your email.'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (authViewModel.resendVerificationCommand.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend: ${authViewModel.resendVerificationCommand.error!.userMessage}'),
            backgroundColor: Colors.red,
          ),
        );
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                      child: Text(
                        'Verification Code',
                        style: TextStyle(
                          color: ArkadColors.arkadTurkos,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          hintText: 'Enter 6-digit code',
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 16.0,
                            horizontal: 16.0,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          letterSpacing:
                              _codeController.text.isEmpty ? 0.5 : 10,
                          fontWeight: FontWeight.bold,
                        ),
                        onChanged: (_) => setState(() {}),
                        autofillHints: const [AutofillHints.oneTimeCode],
                      ),
                    ),
                  ],
                ),

                AuthFormWidgets.buildErrorMessage(_errorMessage),

                const SizedBox(height: 30),

                Consumer<AuthViewModel>(
                  builder: (context, authViewModel, child) {
                    return ElevatedButton(
                      onPressed: authViewModel.isCompletingSignup || !_isCodeComplete ? null : _verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ArkadColors.arkadTurkos,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: authViewModel.isCompletingSignup
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Verify',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                Consumer<AuthViewModel>(
                  builder: (context, authViewModel, child) {
                    return TextButton(
                      onPressed: authViewModel.isResendingVerification ? null : _resendCode,
                      style: TextButton.styleFrom(
                        foregroundColor: ArkadColors.arkadTurkos,
                      ),
                      child: authViewModel.isResendingVerification
                          ? const Text('Sending...')
                          : const Text("Didn't receive the code? Send again"),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
