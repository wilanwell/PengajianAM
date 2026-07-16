import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/core/config/supabase_config.dart';

void main() {
  test('menerima konfigurasi Supabase yang sah', () {
    const config = SupabaseConfig(
      url: 'https://example.supabase.co',
      publishableKey: 'sb_publishable_example_key',
    );

    expect(config.validate, returnsNormally);
  });

  test('menolak Supabase URL kosong', () {
    const config = SupabaseConfig(
      url: '',
      publishableKey: 'sb_publishable_example_key',
    );

    expect(config.validate, throwsA(isA<StateError>()));
  });

  test('menolak URL yang bukan HTTPS', () {
    const config = SupabaseConfig(
      url: 'http://example.supabase.co',
      publishableKey: 'sb_publishable_example_key',
    );

    expect(config.validate, throwsA(isA<StateError>()));
  });

  test('menolak key yang bukan publishable key', () {
    const config = SupabaseConfig(
      url: 'https://example.supabase.co',
      publishableKey: 'sb_secret_example_key',
    );

    expect(config.validate, throwsA(isA<StateError>()));
  });
}
