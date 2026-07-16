class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.publishableKey});

  const SupabaseConfig.fromEnvironment()
    : url = const String.fromEnvironment('SUPABASE_URL'),
      publishableKey = const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  final String url;
  final String publishableKey;

  void validate() {
    final normalizedUrl = url.trim();
    final normalizedKey = publishableKey.trim();

    if (normalizedUrl.isEmpty) {
      throw StateError(
        'SUPABASE_URL belum ditetapkan. '
        'Jalankan aplikasi menggunakan --dart-define.',
      );
    }

    final parsedUrl = Uri.tryParse(normalizedUrl);

    if (parsedUrl == null ||
        parsedUrl.scheme != 'https' ||
        parsedUrl.host.isEmpty) {
      throw StateError(
        'SUPABASE_URL tidak sah. '
        'Gunakan HTTPS Project URL daripada Supabase.',
      );
    }

    if (normalizedKey.isEmpty) {
      throw StateError(
        'SUPABASE_PUBLISHABLE_KEY belum ditetapkan. '
        'Jalankan aplikasi menggunakan --dart-define.',
      );
    }

    if (!normalizedKey.startsWith('sb_publishable_')) {
      throw StateError(
        'Gunakan publishable key yang bermula dengan '
        'sb_publishable_. Jangan gunakan secret key.',
      );
    }
  }
}
