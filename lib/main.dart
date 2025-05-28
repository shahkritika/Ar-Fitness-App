import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/firebase_options.dart';
import 'package:fitness_app/ui/screen/login_page.dart';
import 'package:fitness_app/ui/screen/signup_page.dart';
import 'package:fitness_app/ui/screen/Dashboard.dart';
import 'package:fitness_app/ui/screen/SettingsPage.dart';
import 'package:fitness_app/ui/screen/AppInfoPage.dart';
import 'package:fitness_app/ui/screen/PreloaderPage.dart';
import 'package:fitness_app/ui/screen/ARWorkoutPage.dart';
import 'package:fitness_app/ui/screen/ProgressPage.dart';
import 'package:fitness_app/services/list_models.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('users');
  await Hive.openBox('workout_summaries');

  // Load environment variables
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
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/dashboard': (context) => DashboardPage(),
        '/settings': (context) => SettingsPage(),
        '/app_info': (context) => AppInfoPage(),
        '/progress': (context) => ProgressPage(),
        '/workout': (context) => ARWorkoutPage(
          workoutType:'squat',
          workoutCategory: 'Strength',
          targetReps: 10,
          ),
      },
    );
  }
}