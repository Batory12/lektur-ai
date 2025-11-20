


import 'package:flutter/material.dart';

class ChangePasswordWidget extends StatefulWidget {
  const ChangePasswordWidget({super.key});

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
      return 'Please confirm your password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a new password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your current password';
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
            decoration: const InputDecoration(labelText: 'Current Password', border: OutlineInputBorder()),
            obscureText: true,
            validator: _validateCurrentPassword,
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _newPasswordController,
            decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()),
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
            decoration: const InputDecoration(labelText: 'Confirm New Password', border: OutlineInputBorder()),
            obscureText: true,
            validator: _validateConfirmPassword,
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                // TODO: Send password change request to the server
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords match! Ready to change password.')),
                );
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }
}