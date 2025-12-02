
/// A utility class for validating user input forms
class FormValidators {
  // Private constructor to prevent instantiation
  FormValidators._();

  /// Validates email address format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Wprowadź adres email';
    }
    
    // More robust email regex pattern
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Wprowadź prawidłowy adres email';
    }
    return null;
  }

  /// Validates password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Wprowadź hasło';
    }
    
    if (value.length < 8) {
      return 'Hasło musi mieć co najmniej 8 znaków';
    }
    
    // Check for at least one letter and one number or special character
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
    final hasDigitOrSpecial = RegExp(r'[0-9!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]').hasMatch(value);
    
    if (!hasLetter) {
      return 'Hasło musi zawierać co najmniej jedną literę';
    }
    
    if (!hasDigitOrSpecial) {
      return 'Hasło musi zawierać co najmniej jedną cyfrę lub znak specjalny';
    }
    
    return null;
  }

  /// Validates password confirmation
  static String? validatePasswordConfirmation(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Potwierdź hasło';
    }
    
    if (value != originalPassword) {
      return 'Hasła nie są zgodne';
    }
    
    return null;
  }

  /// Validates display name/full name
  static String? validateDisplayName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Wprowadź swoją nazwę';
    }
    
    final trimmedValue = value.trim();
    if (trimmedValue.length < 2) {
      return 'Nazwa musi mieć co najmniej 2 znaki';
    }
    
    if (trimmedValue.length > 50) {
      return 'Nazwa nie może być dłuższa niż 50 znaków';
    }
    
    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    final nameRegex = RegExp(r"^[a-zA-ZąćęłńóśźżĄĆĘŁŃÓŚŹŻ\s\-']+$");
    if (!nameRegex.hasMatch(trimmedValue)) {
      return 'Nazwa może zawierać tylko litery, spacje, myślniki i apostrofy';
    }
    
    return null;
  }

  /// Validates current password (for password change)
  static String? validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Wprowadź obecne hasło';
    }
    return null;
  }
}