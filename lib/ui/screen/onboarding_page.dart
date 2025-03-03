import 'package:flutter/material.dart';
//import 'package:provider/provider.dart';
//import 'fitness_app/theme/theme_provider.dart';

class OnboardingPage extends StatefulWidget {
  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int currentIndex = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "quote": "Believe in yourself and all that you are.",
      "image": "assets/Gymboy.jpg", // Ensure images exist in your assets folder
    },
    {
      "quote": "Your only limit is your mind.",
      "image": "assets/Gymgirl.jpg", // Ensure images exist in your assets folder
    },
    {
      "quote": "Every journey begins with a single step.",
      "image": "assets/yoga.jpg", // Ensure images exist in your assets folder
    },
  ];

  void navigateToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              onboardingData[currentIndex]['image']!, // Assets path for images
              fit: BoxFit.cover,
            ),
          ),
          // Content Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          // Skip Button
          Positioned(
            top: 40,
            right: 20,
            child: TextButton(
              onPressed: navigateToLogin,
              child: Text(
                "Skip",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Motivational Quote and Next Button
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  onboardingData[currentIndex]['quote']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (currentIndex < onboardingData.length - 1) {
                    setState(() {
                      currentIndex++;
                    });
                  } else {
                    navigateToLogin();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple, // Corrected to backgroundColor
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  currentIndex < onboardingData.length - 1 ? "Next" : "Get Started",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
