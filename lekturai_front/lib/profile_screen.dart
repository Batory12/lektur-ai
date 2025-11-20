import 'package:flutter/material.dart';
import 'package:lekturai_front/widgets/change_password.dart';
import 'package:lekturai_front/widgets/school_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _notificationFrequency = 'Codziennie';
  final List<String> _frequencies = ['Codziennie', 'Co 3 dni', 'Raz w tygodniu', 'Nigdy'];

  // Profile State
  String? _userCity = 'Warszawa';
  String? _userSchool = 'Liceum Ogólnokształcące im. Stefana Batorego';
  String? _userClass = '3a';

  // UI State
  bool _isEditingSchool = false;
  bool _isChangingPassword = false;

  Widget _buildSchoolSection() {
    if (_isEditingSchool) {
      return SchoolPicker(
        initialCity: _userCity,
        initialSchool: _userSchool,
        initialClass: _userClass,
        onSaved: (city, school, className) {
          setState(() {
            _userCity = city;
            _userSchool = school;
            _userClass = className;
            _isEditingSchool = false;
          });
        },
        onCancel: () {
          setState(() {
            _isEditingSchool = false;
          });
        },
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Miejscowość', _userCity ?? 'Nie ustawiono'),
          const SizedBox(height: 8),
          _buildInfoRow('Szkoła', _userSchool ?? 'Nie ustawiono'),
          const SizedBox(height: 8),
          _buildInfoRow('Klasa', _userClass ?? 'Nie ustawiono'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isEditingSchool = true;
              });
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edytuj dane szkoły'),
          ),
        ],
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildPasswordSection() {
    if (_isChangingPassword) {
      return ChangePasswordWidget(
        onCancel: () {
          setState(() {
            _isChangingPassword = false;
          });
        },
        onSuccess: () {
          setState(() {
            _isChangingPassword = false;
          });
        },
      );
    } else {
      return ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _isChangingPassword = true;
          });
        },
        icon: const Icon(Icons.lock_reset),
        label: const Text('Zmień hasło'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Twój Profil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Points Section
            Center(
              child: Column(
                children: [
                  Text(
                    'Twoje Punkty',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1250', // Mock points
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const Divider(height: 40),

            // Change Password Section
            Text(
              'Bezpieczeństwo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildPasswordSection(),
            const Divider(height: 40),

            // School Section
            Text(
              'Twoja Szkoła',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildSchoolSection(),
            const Divider(height: 40),

            // Notification Settings
            Text(
              'Powiadomienia',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _notificationFrequency,
              decoration: const InputDecoration(
                labelText: 'Częstotliwość przypomnień',
                border: OutlineInputBorder(),
              ),
              items: _frequencies.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _notificationFrequency = newValue!;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Zmieniono częstotliwość na: $newValue')),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}