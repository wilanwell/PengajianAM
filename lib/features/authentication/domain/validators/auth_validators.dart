/// Contains reusable authentication form validation rules.
///
/// Validation is separated from the UI so that the rules can be reused by
/// login, registration, password reset, profile, and automated tests.
abstract final class AuthValidators {
  static String? name(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Sila masukkan nama anda.';
    }

    if (name.length < 3) {
      return 'Nama mestilah sekurang-kurangnya 3 aksara.';
    }

    if (name.length > 60) {
      return 'Nama tidak boleh melebihi 60 aksara.';
    }

    return null;
  }

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

  static String? confirmPassword(String? value, String password) {
    final confirmPassword = value ?? '';

    if (confirmPassword.isEmpty) {
      return 'Sila sahkan kata laluan.';
    }

    if (confirmPassword != password) {
      return 'Pengesahan kata laluan tidak sepadan.';
    }

    return null;
  }

  const AuthValidators._();
}
