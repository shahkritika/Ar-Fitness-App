import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({Key? key}) : super(key: key);

  @override
  _NutritionPageState createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  final List<String> preferences = ["Vegetarian", "High Protein", "Low Carb", "Vegan", "Balanced Diet"];
  String? selectedPreference;
  String recommendedMeal = "Choose a preference to get AI meal recommendations.";
  final String? geminiApiKey = dotenv.env['GOOGLE_GEMINI_API_KEY'];

  Future<void> fetchMealRecommendation(String preference) async {
    if (geminiApiKey == null || geminiApiKey!.isEmpty) {
      setState(() => recommendedMeal = "❌ Error: API Key is missing.");
      return;
    }

    setState(() => recommendedMeal = "⏳ Loading AI meal recommendation...");

    try {
      final response = await http.post(
        Uri.parse("https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=$geminiApiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "role": "user",
              "parts": [
                {"text": "Suggest a healthy meal for a $preference diet."}
              ]
            }
          ]
        }),
      );

      debugPrint("🔄 Full Response: ${response.body}");

      if (response.body.isEmpty) {
        setState(() => recommendedMeal = "❌ Error: Empty response from server.");
        return;
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data.containsKey("candidates")) {
        setState(() => recommendedMeal = data["candidates"][0]["content"]["parts"][0]["text"]);
      } else {
        setState(() => recommendedMeal = "❌ Unexpected API response.");
        debugPrint("❌ API Error: Unexpected response format");
      }
    } catch (error) {
      setState(() => recommendedMeal = "❌ Error: Could not fetch AI meal recommendation.");
      debugPrint("❌ API Error: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Color(0xFFB39DDB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const SizedBox(height: 40),
              Text(
                "AI-Powered Meal Recommendations 🍽️",
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Dropdown for meal preference
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  value: selectedPreference,
                  hint: const Text("Select your meal preference"),
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                  underline: const SizedBox(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedPreference = value);
                      fetchMealRecommendation(value);
                    }
                  },
                  items: preferences.map((String preference) {
                    return DropdownMenuItem<String>(
                      value: preference,
                      child: Text(preference, style: const TextStyle(fontSize: 16)),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 15),

              // AI Meal Suggestion
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade300,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    const BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4)),
                  ],
                ),
                child: Text(
                  recommendedMeal,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 20),
              Text(
                "Nutrition Tips 🥦",
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),

              _buildNutritionTip("🥗 Eat a Variety of Foods", "Include fruits, vegetables, proteins, and whole grains."),
              _buildNutritionTip("💧 Stay Hydrated", "Drink at least 8 glasses of water daily."),
              _buildNutritionTip("🍎 Limit Processed Foods", "Minimize sugar and unhealthy fats."),
              _buildNutritionTip("🕒 Eat at Regular Intervals", "Don't skip meals and eat small portions throughout the day."),
              _buildNutritionTip("🏋️‍♂️ Combine Diet with Exercise", "A balanced diet is best with regular physical activity."),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionTip(String title, String description) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurpleAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(description, style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
        ],
      ),
    );
  }
}
