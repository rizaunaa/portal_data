import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String get supabaseUrl => dotenv.maybeGet('SUPABASE_URL') ?? '';
String get supabaseAnonKey => dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '';

bool get isSupabaseConfigured =>
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

Future<void> initializeSupabase() async {
  await dotenv.load(fileName: '.env');

  if (!isSupabaseConfigured) {
    return;
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
}

SupabaseClient get supabaseClient => Supabase.instance.client;
