import 'package:arkad/view_models/auth_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart'; // Add go_router import
import 'package:provider/provider.dart';

import '../../config/theme_config.dart';
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
    final authProvider = Provider.of<AuthModel>(context, listen: false);
    try {
      final success = await authProvider.completeSignup(_codeController.text);
      if (mounted) {
        if (success) {
          context.go('/companies');
        } else if (authProvider.error != null) {
          setState(() => _errorMessage = authProvider.error!.userMessage);
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
    final authProvider = Provider.of<AuthModel>(context, listen: false);
    try {
      final success = await authProvider.requestNewVerificationCode(
        widget.email,
      );
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A new verification code has been sent'),
            ),
          );
        } else if (authProvider.error != null) {
          setState(() => _errorMessage = authProvider.error!.userMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Failed to resend code: ${e.toString()}',
        );
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

                ElevatedButton(
                  onPressed:
                      _isVerifying || !_isCodeComplete ? null : _verifyCode,
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
                      _isVerifying
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
                ),

                const SizedBox(height: 24),

                TextButton(
                  onPressed: _isResending ? null : _resendCode,
                  style: TextButton.styleFrom(
                    foregroundColor: ArkadColors.arkadTurkos,
                  ),
                  child:
                      _isResending
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
