

import 'package:flutter/material.dart';

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

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Potwierdź swoje hasło';
    }
    if (value != _newPasswordController.text) {
      return 'Hasła nie są zgodne';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Wprowadź nowe hasło';
    }
    if (value.length < 6) {
      return 'Hasło musi mieć co najmniej 6 znaków';
    }
    return null;
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Wprowadź obecne hasło';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _currentPasswordController,
            decoration: const InputDecoration(labelText: 'Aktualne Hasło', border: OutlineInputBorder()),
            obscureText: true,
            validator: _validateCurrentPassword,
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _newPasswordController,
            decoration: const InputDecoration(labelText: 'Nowe Hasło', border: OutlineInputBorder()),
            obscureText: true,
            validator: _validateNewPassword,
            onChanged: (value) {
              // Trigger validation of confirm password field when new password changes
              if (_confirmPasswordController.text.isNotEmpty) {
                _formKey.currentState?.validate();
              }
            },
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: const InputDecoration(labelText: 'Potwierdź nowe hasło', border: OutlineInputBorder()),
            obscureText: true,
            validator: _validateConfirmPassword,
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.onCancel != null)
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Anuluj'),
                ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    // TODO: Send password change request to the server
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hasło zostało zmienione pomyślnie!')),
                    );
                    widget.onSuccess?.call();
                  }
                },
                child: const Text('Zmień Hasło'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}