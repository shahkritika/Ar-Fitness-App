import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeData get currentTheme => _isDarkMode ? _darkTheme : _lightTheme;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

final ThemeData _darkTheme = ThemeData.dark().copyWith(
  colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepPurple),
  scaffoldBackgroundColor: Colors.black,
);

final ThemeData _lightTheme = ThemeData.light().copyWith(
  colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepPurple),
  scaffoldBackgroundColor: Colors.white,
);
