import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      // Kelabu muda di belakang navigation icon atau gesture indicator.
      systemNavigationBarColor: AppColors.surfaceMuted,

      // Garisan pemisah navigation bar.
      systemNavigationBarDividerColor: AppColors.border,

      // Android akan menggunakan icon gelap.
      systemNavigationBarIconBrightness: Brightness.dark,

      // Elakkan Android menambah contrast layer sendiri.
      systemNavigationBarContrastEnforced: false,
    ),
  );

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}