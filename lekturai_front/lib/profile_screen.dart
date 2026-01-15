import 'package:flutter/material.dart';
import 'package:lekturai_front/services/auth_service.dart';
import 'package:lekturai_front/services/profile_service.dart';
import 'package:lekturai_front/widgets/change_password.dart';
import 'package:lekturai_front/widgets/school_picker.dart';
import 'package:lekturai_front/widgets/common_scaffold.dart';
import '../models/user_profile.dart';
import '../models/user_stats.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _notificationFrequency = 'Codziennie';
  int _notificationHour = 10;
  int _notificationMinute = 0;
  final List<String> _frequencies = [
    'Codziennie',
    'Co 3 dni',
    'Raz w tygodniu',
    'Nigdy',
  ];
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();

  // Profile State
  UserProfile? _userProfile;
  UserStats? _userStats;
  bool _isLoading = true;

  // UI State
  bool _isEditingSchool = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadUserStats();
  }

  Future<void> _loadUserProfile() async {
    try {
      UserProfile? profile = await _profileService.getUserProfile();
      setState(() {
        _userProfile = profile;
        _notificationFrequency = profile?.notificationFrequency ?? 'Codziennie';
        _notificationHour = profile?.notificationHour ?? 10;
        _notificationMinute = profile?.notificationMinute ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas ładowania profilu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  Future<void> _loadUserStats() async {
    try {
      UserStats? stats = await _profileService.getUserStats();
      setState(() {
        _userStats = stats;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas ładowania statystyk: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Widget _buildSchoolSection() {
    if (_isEditingSchool) {
      return SchoolPicker(
        initialCity: _userProfile?.city,
        initialSchool: _userProfile?.school,
        initialClass: _userProfile?.className,
        onSaved: (city, school, className) async {
          setState(() {
            _isEditingSchool = false;
          });

          // Update in Firestore
          ProfileUpdateResult result = await _profileService.updateSchoolInfo(
            city: city,
            school: school,
            className: className,
          );

          if (mounted) {
            if (result.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result.message ?? 'Dane zostały zaktualizowane',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              // Reload profile to get updated data
              _loadUserProfile();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.error ?? 'Wystąpił błąd'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
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
          _buildInfoRow('Miejscowość', _userProfile?.city ?? 'Nie ustawiono'),
          const SizedBox(height: 8),
          _buildInfoRow('Szkoła', _userProfile?.school ?? 'Nie ustawiono'),
          const SizedBox(height: 8),
          _buildInfoRow('Klasa', _userProfile?.className ?? 'Nie ustawiono'),
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
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }

  String _getNotificationDescription(String frequency) {
    String timeStr = '${_notificationHour.toString().padLeft(2, '0')}:${_notificationMinute.toString().padLeft(2, '0')}';
    switch (frequency) {
      case 'Codziennie':
        return 'Otrzymasz przypomnienie codziennie o $timeStr';
      case 'Co 3 dni':
        return 'Otrzymasz przypomnienie co 3 dni o $timeStr';
      case 'Raz w tygodniu':
        return 'Otrzymasz przypomnienie w każdy poniedziałek o $timeStr';
      case 'Nigdy':
        return 'Nie będziesz otrzymywać przypomnień';
      default:
        return '';
    }
  }

  Future<void> _selectNotificationTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _notificationHour, minute: _notificationMinute),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteShape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _notificationHour = picked.hour;
        _notificationMinute = picked.minute;
      });

      // Update in Firestore
      ProfileUpdateResult result = await _profileService
          .updateNotificationTime(_notificationHour, _notificationMinute);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success
                  ? 'Zmieniono godzinę powiadomień na: ${_notificationHour.toString().padLeft(2, '0')}:${_notificationMinute.toString().padLeft(2, '0')}'
                  : result.error ?? 'Wystąpił błąd',
            ),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    }
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
    return CommonScaffold(
      title: 'Twój Profil',
      showDrawer: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Info Section
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              _userProfile?.displayName.isNotEmpty == true
                                  ? _userProfile!.displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _userProfile?.displayName ?? 'Użytkownik',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userProfile?.email ?? '',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
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
                            '${_userStats?.points ?? 0}',
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(
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
                      onChanged: (String? newValue) async {
                        if (newValue != null) {
                          setState(() {
                            _notificationFrequency = newValue;
                          });

                          // Update in Firestore
                          ProfileUpdateResult result = await _profileService
                              .updateNotificationFrequency(newValue);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result.success
                                      ? 'Zmieniono częstotliwość na: $newValue'
                                      : result.error ?? 'Wystąpił błąd',
                                ),
                                backgroundColor: result.success
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getNotificationDescription(_notificationFrequency),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 16),
                    // Time picker for notifications
                    if (_notificationFrequency != 'Nigdy')
                      OutlinedButton.icon(
                        onPressed: _selectNotificationTime,
                        icon: const Icon(Icons.access_time),
                        label: Text(
                          'Zmień godzinę (${_notificationHour.toString().padLeft(2, '0')}:${_notificationMinute.toString().padLeft(2, '0')})',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 40),
                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Show confirmation dialog
                          bool? confirmLogout = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Wyloguj się'),
                                content: const Text(
                                  'Czy na pewno chcesz się wylogować?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Anuluj'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text('Wyloguj się'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmLogout == true) {
                            await _authService.signOut();
                            if (mounted) {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/',
                                (route) => false,
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Wyloguj się'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Delete Account Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          // Show confirmation dialog
                          bool? confirmDelete = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Usuń konto'),
                                content: const Text(
                                  'Czy na pewno chcesz usunąć swoje konto? '
                                  'Ta operacja jest nieodwracalna i spowoduje '
                                  'trwałe usunięcie wszystkich Twoich danych.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Anuluj'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[900],
                                    ),
                                    child: const Text('Usuń konto'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmDelete == true) {
                            // Show loading indicator
                            if (mounted) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                              );
                            }

                            // Delete account
                            AuthResult result =
                                await _authService.deleteAccount();

                            // Close loading indicator
                            if (mounted) {
                              Navigator.of(context).pop();
                            }

                            if (mounted) {
                              if (result.success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      result.message ??
                                          'Konto zostało pomyślnie usunięte',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                // Navigate to login screen
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/',
                                  (route) => false,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      result.error ?? 'Wystąpił błąd',
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 5),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Usuń konto'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red[900],
                          side: BorderSide(color: Colors.red[900]!),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Add extra bottom padding to ensure content is always visible
                    SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 16,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
