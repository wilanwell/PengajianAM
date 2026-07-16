import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/theme/app_colors.dart';
import 'core/config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseConfig = SupabaseConfig.fromEnvironment();

  supabaseConfig.validate();

  await Supabase.initialize(
    url: supabaseConfig.url,
    publishableKey: supabaseConfig.publishableKey,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: AppColors.surfaceMuted,
      systemNavigationBarDividerColor: AppColors.border,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  runApp(const ProviderScope(child: App()));
}
