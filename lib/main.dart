import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fitness_app/firebase_options.dart';
import 'package:fitness_app/ui/screen/onboarding_page.dart';
import 'package:fitness_app/ui/screen/login_page.dart';
import 'package:fitness_app/ui/screen/signup_page.dart';
import 'package:fitness_app/ui/screen/Dashboard.dart';
import 'package:fitness_app/ui/screen/SettingsPage.dart';
import 'package:fitness_app/ui/screen/AppInfoPage.dart';
import 'package:fitness_app/ui/screen/PreloaderPage.dart';
import 'package:fitness_app/ui/screen/ARWorkoutPage.dart';
import 'package:fitness_app/ui/screen/ProgressPage.dart';
import 'package:fitness_app/services/list_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await dotenv.load();
  listAvailableModels();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const PreloaderPage(),
      routes: {
        '/onboarding': (context) => OnboardingPage(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/dashboard': (context) => DashboardPage(),
        '/settings': (context) => SettingsPage(),
        '/app_info': (context) => AppInfoPage(),
        '/workout': (context) => ARWorkoutPage(
              workoutType: 'squat',
              workoutCategory: 'Strength',
              targetReps: 10,
            ),
        '/progress': (context) => ProgressPage(),
      },
    );
  }
}