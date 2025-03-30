import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/profile_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String email;

  const VerificationScreen({super.key, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupTextFieldListeners();
  }

  void _setupTextFieldListeners() {
    for (int i = 0; i < 6; i++) {
      _controllers[i].addListener(() {
        final value = _controllers[i].text;

        // Auto-advance to next field when a digit is entered
        if (value.length == 1 && i < 5) {
          _nodes[i + 1].requestFocus();
        }
      });

      // Set up focus listeners for handling backspace navigation
      _nodes[i].addListener(() {
        if (_nodes[i].hasFocus && i > 0 && _controllers[i].text.isEmpty) {
          // When focusing an empty field, pre-select the previous field
          // This helps with backspace navigation
          _controllers[i - 1].selection = TextSelection.fromPosition(
            TextPosition(offset: _controllers[i - 1].text.length),
          );
        }
      });
    }
  }

  bool get _isCodeComplete =>
      _controllers.every((controller) => controller.text.length == 1);

  String get _fullCode =>
      _controllers.map((controller) => controller.text).join();

  Future<void> _verifyCode() async {
    if (!_isCodeComplete) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final success = await authProvider.verifyCode(_fullCode);

      if (mounted) {
        if (success) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => ProfileScreen(user: authProvider.user!),
            ),
            (route) => false,
          );
        } else if (authProvider.error != null) {
          setState(() {
            _errorMessage = authProvider.error;
          });
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

            // Verification code input fields
            _buildVerificationCodeInputs(),

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

            // Verify button
            ElevatedButton(
              onPressed: _isVerifying || !_isCodeComplete ? null : _verifyCode,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isVerifying
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verify'),
            ),

            const SizedBox(height: 24),

            // Resend code button
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

  Widget _buildVerificationCodeInputs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        6,
        (index) => SizedBox(
          width: 45,
          child: RawKeyboardListener(
            focusNode: FocusNode(),
            onKey: (event) {
              // Handle backspace navigation
              if (event is RawKeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.backspace &&
                  _controllers[index].text.isEmpty &&
                  index > 0) {
                _nodes[index - 1].requestFocus();
              }
            },
            child: TextField(
              controller: _controllers[index],
              focusNode: _nodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              decoration: InputDecoration(
                counterText: "",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                // Clear field if more than one character somehow gets in
                if (value.length > 1) {
                  _controllers[index].text = value[0];
                }

                setState(() {}); // Update button state
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }
}
