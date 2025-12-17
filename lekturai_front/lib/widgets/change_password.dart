import 'package:flutter/material.dart';
import '../tools/password_validator.dart';
import '../theme/spacing.dart';
import '../services/auth_service.dart';

class ChangePasswordWidget extends StatefulWidget {
  final VoidCallback? onCancel;
  final VoidCallback? onSuccess;

  const ChangePasswordWidget({super.key, this.onCancel, this.onSuccess});

  @override
  State<StatefulWidget> createState() {
    return _ChangePasswordWidgetState();
  }

}

class _ChangePasswordWidgetState extends State<ChangePasswordWidget> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool password_updated = false;

  String? _validateConfirmPassword(String? value) {
    return FormValidators.validatePasswordConfirmation(value, _newPasswordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _currentPasswordController,
            decoration: InputDecoration(
              labelText: 'Aktualne Hasło',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscureCurrentPassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _obscureCurrentPassword = !_obscureCurrentPassword;
                  });
                },
              ),
            ),
            obscureText: _obscureCurrentPassword,
            validator: FormValidators.validateCurrentPassword,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.xl),
          TextFormField(
            controller: _newPasswordController,
            decoration: InputDecoration(
              labelText: 'Nowe Hasło',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _obscureNewPassword = !_obscureNewPassword;
                  });
                },
              ),
            ),
            obscureText: _obscureNewPassword,
            validator: FormValidators.validatePassword,
            textInputAction: TextInputAction.next,
            onChanged: (value) {
              // Trigger validation of confirm password field when new password changes
              if (_confirmPasswordController.text.isNotEmpty) {
                _formKey.currentState?.validate();
              }
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Potwierdź nowe hasło',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            obscureText: _obscureConfirmPassword,
            validator: _validateConfirmPassword,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.onCancel != null)
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Anuluj'),
                ),
              const SizedBox(width: AppSpacing.sm),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    password_updated = await AuthService().changePassword(_newPasswordController.text);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(password_updated ? 'Hasło zostało zmienione pomyślnie!' : 'Wystąpił błąd podczas zmiany hasła'),
                        backgroundColor: password_updated ? Colors.green : Colors.red,
                      ),
                    );
                    widget.onSuccess?.call();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                ),
                child: const Text('Zmień Hasło'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}