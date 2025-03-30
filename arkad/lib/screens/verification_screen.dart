import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/profile_screen.dart'; // Import the ProfileScreen

class VerificationScreen extends StatefulWidget {
  final String email;

  const VerificationScreen({super.key, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  bool _isCodeComplete = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Set up listeners to auto-advance focus and check code completion
    for (int i = 0; i < 6; i++) {
      _codeControllers[i].addListener(() {
        if (i < 5 && _codeControllers[i].text.length == 1) {
          _focusNodes[i + 1].requestFocus();
        }
        _checkCodeCompletion();
      });
    }
  }

  void _checkCodeCompletion() {
    final isComplete =
        _codeControllers.every((controller) => controller.text.length == 1);
    if (isComplete != _isCodeComplete) {
      setState(() {
        _isCodeComplete = isComplete;
      });
    }
  }

  String get _fullCode {
    return _codeControllers.map((controller) => controller.text).join();
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  Future<void> _verifyCode() async {
    _clearError();

    if (_fullCode.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit code';
      });
      return;
    }

    setState(() => _isVerifying = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final success = await authProvider.verifyCode(_fullCode);

      if (mounted) {
        if (success) {
          // After verification and automatic sign in, navigate to ProfileScreen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => ProfileScreen(
                user: authProvider.user!,
              ),
            ),
            (route) => false,
          );
        } else if (authProvider.error != null) {
          setState(() {
            _isVerifying = false;
            _errorMessage = authProvider.error;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _resendCode() async {
    _clearError();
    setState(() => _isResending = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final success =
          await authProvider.requestNewVerificationCode(widget.email);

      if (mounted) {
        setState(() => _isResending = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('A new verification code has been sent')));
        } else if (authProvider.error != null) {
          setState(() => _errorMessage = authProvider.error);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResending = false;
          _errorMessage = 'Failed to resend code: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Your Email")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.mail_outline,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            Text(
              "We've sent a verification code to ${widget.email}",
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // 6 digit code input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                6,
                (index) => SizedBox(
                  width: 45,
                  child: TextField(
                    controller: _codeControllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      // If backspace is pressed on empty field, go back to previous field
                      if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                    },
                  ),
                ),
              ),
            ),

            // Error message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 40),

            // Verify button - disabled until code is complete
            ElevatedButton(
              onPressed:
                  (_isVerifying || !_isCodeComplete) ? null : _verifyCode,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isVerifying
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Verify',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
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
    );
  }

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}
