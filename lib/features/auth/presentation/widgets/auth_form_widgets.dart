import 'package:flutter/material.dart';
import '../../../../shared/presentation/themes/arkad_theme.dart';

class AuthFormWidgets {
  static Widget buildLogoHeader() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Image.asset('assets/icons/arkad_logo_inverted.png', height: 120),
        const SizedBox(height: 40),
      ],
    );
  }

  static Widget buildHeading(String title, String subtitle) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
    String? errorText,
    String? Function(String?)? validator,
    Iterable<String>? autofillHints,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'Enter your email',
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        isDense: true,
        alignLabelWithHint: true,
        prefixIconConstraints: const BoxConstraints(minWidth: 50),
        prefixIcon: Align(
          widthFactor: 1.0,
          heightFactor: 1.0,
          child: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Icon(Icons.email, color: ArkadColors.arkadTurkos, size: 24),
          ),
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 40),
        suffixIcon:
            controller.text.isNotEmpty && isValid != null
                ? Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Icon(
                    isValid ? Icons.check_circle : Icons.error,
                    color:
                        isValid ? ArkadColors.arkadGreen : ArkadColors.lightRed,
                    size: 24,
                  ),
                )
                : null,
        errorText: errorText,
        errorStyle: TextStyle(color: ArkadColors.lightRed, fontSize: 12),
        errorBorder:
            errorText != null
                ? OutlineInputBorder(
                  borderSide: BorderSide(color: ArkadColors.lightRed),
                  borderRadius: BorderRadius.circular(8),
                )
                : null,
        focusedErrorBorder:
            errorText != null
                ? OutlineInputBorder(
                  borderSide: BorderSide(color: ArkadColors.lightRed, width: 2),
                  borderRadius: BorderRadius.circular(8),
                )
                : null,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: ArkadColors.arkadTurkos),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: autofillHints,
      onChanged: onChanged,
      validator: validator,
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
    String? errorText,
    String? Function(String?)? validator,
    Iterable<String>? autofillHints,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        isDense: true,
        alignLabelWithHint: true,
        prefixIconConstraints: const BoxConstraints(minWidth: 50),
        prefixIcon: Align(
          widthFactor: 1.0,
          heightFactor: 1.0,
          child: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Icon(Icons.lock, color: ArkadColors.arkadTurkos, size: 24),
          ),
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 40),
        suffixIcon:
            controller.text.isNotEmpty && isValid != null
                ? Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Icon(
                    isValid ? Icons.check_circle : Icons.error,
                    color:
                        isValid ? ArkadColors.arkadGreen : ArkadColors.lightRed,
                    size: 24,
                  ),
                )
                : onToggleVisibility != null
                ? Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: ArkadColors.arkadTurkos,
                      size: 24,
                    ),
                    onPressed: onToggleVisibility,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                )
                : null,
        errorText: errorText,
        errorStyle: TextStyle(color: ArkadColors.lightRed, fontSize: 12),
        errorBorder:
            errorText != null
                ? OutlineInputBorder(
                  borderSide: BorderSide(color: ArkadColors.lightRed),
                  borderRadius: BorderRadius.circular(8),
                )
                : null,
        focusedErrorBorder:
            errorText != null
                ? OutlineInputBorder(
                  borderSide: BorderSide(color: ArkadColors.lightRed, width: 2),
                  borderRadius: BorderRadius.circular(8),
                )
                : null,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: ArkadColors.arkadTurkos),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      obscureText: obscureText,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
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
            size: 18.0,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child:
          isLoading
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

  static Widget buildSuccessMessage(String? errorMessage) {
    if (errorMessage == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        errorMessage,
        style: TextStyle(color: ArkadColors.arkadGreen, fontSize: 18),
        textAlign: TextAlign.center,
      ),
    );
  }

  static Widget buildCheckboxWithError({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required Widget label,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Transform.scale(
              scale: 1.2,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: ArkadColors.arkadTurkos,
                side: BorderSide(
                  color: errorText != null ? ArkadColors.lightRed : Colors.grey,
                  width: errorText != null ? 2 : 1,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(child: label),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 36.0),
            child: Text(
              errorText,
              style: TextStyle(color: ArkadColors.lightRed, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
