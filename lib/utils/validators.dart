/// Input validation helpers.
class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    // Sri Lankan phone number: 0XXXXXXXXX or +94XXXXXXXXX
    final phone = value.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    final slPattern = RegExp(r'^(\+?94|0)\d{9}$');
    if (!slPattern.hasMatch(phone)) {
      return 'Enter a valid Sri Lankan phone number';
    }
    return null;
  }

  static String? message(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please paste a message to analyze';
    }
    if (value.trim().length < 5) {
      return 'Message is too short to analyze';
    }
    return null;
  }
}
