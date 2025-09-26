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
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Reset command state to prevent stale state display
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      authViewModel.completeSignupCommand.reset();
      authViewModel.resendVerificationCommand.reset();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  bool get _isCodeComplete => _codeController.text.length == 6;

  Future<void> _verifyCode() async {
    if (!_isCodeComplete) return;

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    await authViewModel.completeSignUp(_codeController.text);

    // Only navigate on successful completion, not on error
    if (mounted &&
        authViewModel.completeSignupCommand.isCompleted &&
        authViewModel.completeSignupCommand.result != null &&
        !authViewModel.completeSignupCommand.hasError) {
      context.go('/profile');
    }
  }

  Future<void> _resendCode() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final email = authViewModel.pendingSignupData?.email;

    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No email found for verification'),
          backgroundColor: ArkadColors.lightRed,
        ),
      );
      return;
    }

    await authViewModel.resendVerification(email);

    if (mounted) {
      if (authViewModel.resendVerificationCommand.isCompleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent! Check your email.'),
            backgroundColor: ArkadColors.arkadGreen,
          ),
        );
      } else if (authViewModel.resendVerificationCommand.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to resend: ${authViewModel.resendVerificationCommand.error!.userMessage}',
            ),
            backgroundColor: ArkadColors.lightRed,
          ),
        );
      }
    }
  }

  void _goBackToSignup() {
    context.pop();
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

                Consumer<AuthViewModel>(
                  builder: (context, authViewModel, child) {
                    final email =
                        authViewModel.pendingSignupData?.email ??
                        'Unknown email';
                    return Text(
                      email,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                const SizedBox(height: 40),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
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

                Consumer<AuthViewModel>(
                  builder: (context, authViewModel, child) {
                    final error = authViewModel.completeSignupCommand.error;
                    if (error != null) {
                      return AuthFormWidgets.buildErrorMessage(
                        error.userMessage,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                const SizedBox(height: 30),

                Consumer<AuthViewModel>(
                  builder: (context, authViewModel, child) {
                    return ElevatedButton(
                      onPressed:
                          authViewModel.isCompletingSignup || !_isCodeComplete
                              ? null
                              : _verifyCode,
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
                      child:
                          authViewModel.isCompletingSignup
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

                // Back button
                TextButton(
                  onPressed: _goBackToSignup,
                  style: TextButton.styleFrom(
                    foregroundColor: ArkadColors.gray,
                  ),
                  child: const Text('← Back to signup'),
                ),

                const SizedBox(height: 8),

                Consumer<AuthViewModel>(
                  builder: (context, authViewModel, child) {
                    return TextButton(
                      onPressed:
                          authViewModel.isResendingVerification
                              ? null
                              : _resendCode,
                      style: TextButton.styleFrom(
                        foregroundColor: ArkadColors.arkadTurkos,
                      ),
                      child:
                          authViewModel.isResendingVerification
                              ? const Text('Sending...')
                              : const Text(
                                "Didn't receive the code? Send again",
                              ),
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
