import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'login_page.dart';

class PreloaderPage extends StatefulWidget {
  const PreloaderPage({Key? key}) : super(key: key);

  @override
  _PreloaderPageState createState() => _PreloaderPageState();
}

class _PreloaderPageState extends State<PreloaderPage> with TickerProviderStateMixin {
  late AnimationController _imageController;
  late AnimationController _textController;
  late Animation<double> _imageOpacity;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    _imageController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _imageOpacity = Tween<double>(begin: 0, end: 1).animate(_imageController);
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(_textController);

    _startAnimations();
    _simulateLoading();
  }

  Future<void> _simulateLoading() async {
    await Future.delayed(const Duration(seconds: 5)); // 5-second delay
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  void _startAnimations() async {
    await _imageController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _textController.forward();
  }

  @override
  void dispose() {
    _imageController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // white background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _imageOpacity,
              child: Image.asset(
                'assets/KayaMove.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _textOpacity,
              child: Text(
                "Your Body. Your Motion. Your Move.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}