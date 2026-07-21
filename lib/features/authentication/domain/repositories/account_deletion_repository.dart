abstract interface class AccountDeletionRepository {
  /// Memadam akaun pengguna semasa.
  ///
  /// Kata laluan semasa diperlukan untuk
  /// mengesahkan identiti pengguna sebelum
  /// Edge Function dipanggil.
  Future<void> deleteAccount({required String currentPassword});
}
