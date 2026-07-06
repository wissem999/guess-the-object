class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email';
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

  static String? roomCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Room code is required';
    }
    if (value.trim().length != 6) {
      return 'Room code must be 6 characters';
    }
    return null;
  }

  static String? displayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 30) {
      return 'Name must be at most 30 characters';
    }
    return null;
  }

  static String? question(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Question is required';
    }
    if (value.trim().length > 200) {
      return 'Question is too long (max 200 characters)';
    }
    return null;
  }
}
