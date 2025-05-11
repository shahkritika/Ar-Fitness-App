// lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyBIJDtrPEvAi4xTL6z1H2cr8PNgeBZd3Uw",
    appId: "1:771139135272:android:121ab7e61e2337751c521d", // from Firebase
    messagingSenderId: "1234567890",
    projectId: "fitnessapp-72593",
  );
}
