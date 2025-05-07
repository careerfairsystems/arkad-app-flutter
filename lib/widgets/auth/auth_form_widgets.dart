import 'package:flutter/material.dart';
import '../../config/theme_config.dart';

/// A collection of reusable widgets for authentication screens
class AuthFormWidgets {
  static Widget buildLogoHeader() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Image.asset(
          'assets/icons/arkad_logo_inverted.png',
          height: 120,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  static Widget buildHeading(String title, String subtitle) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  static Widget buildEmailField(
    TextEditingController controller, {
    bool? isValid,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'Enter your email',
        prefixIcon: Icon(Icons.email, color: ArkadColors.arkadTurkos),
        suffixIcon: controller.text.isNotEmpty && isValid != null
            ? Icon(
                isValid ? Icons.check_circle : Icons.error,
                color: isValid ? ArkadColors.arkadGreen : ArkadColors.lightRed,
              )
            : null,
      ),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      onChanged: onChanged,
    );
  }

  static Widget buildPasswordField(
    TextEditingController controller, {
    String labelText = 'Password',
    String hintText = 'Enter your password',
    bool? isValid,
    bool obscureText = true,
    VoidCallback? onToggleVisibility,
    void Function(String)? onChanged,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(Icons.lock, color: ArkadColors.arkadTurkos),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.text.isNotEmpty && isValid != null)
              Icon(
                isValid ? Icons.check_circle : Icons.error,
                color: isValid ? ArkadColors.arkadGreen : ArkadColors.lightRed,
                size: 20,
              ),
            if (onToggleVisibility != null)
              IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: ArkadColors.arkadTurkos,
                ),
                onPressed: onToggleVisibility,
              ),
          ],
        ),
      ),
      obscureText: obscureText,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
    );
  }

  static Widget buildPasswordRequirementRow(bool isMet, String requirement) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.cancel,
            color: isMet ? ArkadColors.arkadGreen : ArkadColors.lightRed,
            size: 16.0,
          ),
          const SizedBox(width: 8.0),
          Text(
            requirement,
            style: TextStyle(
              fontSize: 12.0,
              color: isMet ? ArkadColors.arkadGreen : ArkadColors.lightRed,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildSubmitButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: ArkadColors.arkadTurkos,
        foregroundColor: ArkadColors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(ArkadColors.white),
              ),
            )
          : Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  static Widget buildAuthLinkRow({
    required String question,
    required String linkText,
    required VoidCallback onPressed,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(question),
        TextButton(
          onPressed: onPressed,
          child: Text(
            linkText,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  static Widget buildErrorMessage(String? errorMessage) {
    if (errorMessage == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        errorMessage,
        style: TextStyle(color: ArkadColors.lightRed),
        textAlign: TextAlign.center,
      ),
    );
  }
}
