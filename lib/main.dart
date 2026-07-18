import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'app.dart';

String _env(String key) {
  final v = dotenv.env[key];
  if (v != null && v.isNotEmpty) return v;
  const dartDefines = {
    'FIREBASE_API_KEY': String.fromEnvironment('FIREBASE_API_KEY'),
    'FIREBASE_AUTH_DOMAIN': String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
    'FIREBASE_PROJECT_ID': String.fromEnvironment('FIREBASE_PROJECT_ID'),
    'FIREBASE_STORAGE_BUCKET': String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    'FIREBASE_MESSAGING_SENDER_ID': String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    'FIREBASE_APP_ID': String.fromEnvironment('FIREBASE_APP_ID'),
    'FIREBASE_DATABASE_URL': String.fromEnvironment('FIREBASE_DATABASE_URL'),
    'GOOGLE_WEB_CLIENT_ID': String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
  };
  return dartDefines[key] ?? '';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: _env('FIREBASE_API_KEY'),
      authDomain: _env('FIREBASE_AUTH_DOMAIN'),
      projectId: _env('FIREBASE_PROJECT_ID'),
      storageBucket: _env('FIREBASE_STORAGE_BUCKET'),
      messagingSenderId: _env('FIREBASE_MESSAGING_SENDER_ID'),
      appId: _env('FIREBASE_APP_ID'),
    ),
  );

  if (!kIsWeb) {
    await GoogleSignIn.instance.initialize();
  }

  runApp(const ProviderScope(child: GuessTheObjectApp()));
}
