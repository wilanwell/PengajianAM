/// Contains authentication form validation rules.
///
/// Validation is kept outside the page so that the same rules can be reused
/// by login, registration, password reset, and automated tests.
abstract final class AuthValidators {
  static String? email(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Sila masukkan e-mel.';
    }

    final emailPattern = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );

    if (!emailPattern.hasMatch(email)) {
      return 'Sila masukkan e-mel yang sah.';
    }

    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Sila masukkan kata laluan.';
    }

    if (password.length < 6) {
      return 'Kata laluan mestilah sekurang-kurangnya 6 aksara.';
    }

    return null;
  }

  const AuthValidators._();
}
