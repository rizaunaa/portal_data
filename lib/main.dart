import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/supabase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();
  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  runApp(EmployeeApp(savedThemeMode: savedThemeMode));
}
