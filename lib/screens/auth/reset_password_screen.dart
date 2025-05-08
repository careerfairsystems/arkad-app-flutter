import 'package:flutter/material.dart';
import '../../utils/validation_utils.dart';
import '../../widgets/auth/auth_form_widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isEmailValid = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _emailErrorText;

  final TextEditingController _emailController = TextEditingController();

  /*   void _validateEmail() {
    setState(() {
      _isEmailValid = ValidationUtils.isValidEmail(_emailController.text);
      if (_emailController.text.isNotEmpty) {
        _emailErrorText = null;
      }
    });
  } */

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

    setState(() {
      _isLoading = true;
    });
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
      appBar: AppBar(title: const Text("Reset Password")),
      body: Center(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // const SizedBox(height: 75),
                AuthFormWidgets.buildHeading(
                  'Reset password',
                  'Enter your email to reset your password',
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
                const SizedBox(height: 15),

                AuthFormWidgets.buildSubmitButton(
                  text: "Submit",
                  onPressed: _submitEmailResetPassword,
                  isLoading: _isLoading,
                ),
                AuthFormWidgets.buildErrorMessage(_errorMessage),
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
