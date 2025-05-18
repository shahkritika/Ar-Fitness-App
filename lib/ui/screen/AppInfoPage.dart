import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppInfoPage extends StatelessWidget {
  const AppInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar with a matching color theme
      appBar: AppBar(
        title: Text(
          "App Info",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 12,
            shadowColor: Colors.black.withOpacity(0.2),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Icon Header
                  Center(
                    child: Icon(
                      Icons.fitness_center,
                      size: 100,
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      "Fitness App",
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurpleAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      "Version 1.0.0",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const Divider(height: 30, thickness: 1, color: Colors.deepPurpleAccent),
                  
                  // About Section
                  Text("About the App",
                      style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 10),
                  Text(
                    "Fitness App is designed to help you achieve your health goals. "
                    "Track your workouts, monitor your progress, and stay motivated with "
                    "personalized exercise plans and performance analytics.",
                    style: GoogleFonts.poppins(
                        fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 20),
                  
                  // Features Section
                  Text("Features",
                      style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 10),
                  _buildFeatureItem("Real-time AR workouts"),
                  _buildFeatureItem("Personalized exercise plans"),
                  _buildFeatureItem("Progress tracking and analytics"),
                  _buildFeatureItem("In-app motivational tips"),
                  const SizedBox(height: 20),
                  
                  // Developer Info
                  Text("Developed by",
                      style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 10),
                  Text("Your Name",
                      style: GoogleFonts.poppins(
                          fontSize: 18, color: Colors.white70)),
                  const SizedBox(height: 30),
                  
                  // Back Button
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 35, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 6,
                      ),
                      child: Text("Back to Settings",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for feature list items
  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(Icons.check, color: Colors.deepPurpleAccent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                  fontSize: 16, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
