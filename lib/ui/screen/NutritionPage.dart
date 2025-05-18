import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class NutritionPage extends StatefulWidget {
  const NutritionPage({Key? key}) : super(key: key);

  @override
  _NutritionPageState createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  final List<String> preferences = [
    "Vegetarian",
    "High Protein",
    "Low Carb",
    "Vegan",
    "Balanced Diet"
  ];

  final List<String> nutritionTips = [
    "💧 Stay Hydrated: Drink at least 2-3 liters of water daily.",
    "🥦 Eat More Greens: Include leafy veggies & fruits in every meal.",
    "🍽️ Portion Control: Eat until you're 80% full.",
    "⏰ Don't Skip Meals: Maintain regular meal timings.",
    "🍳 Balanced Plate: Mix protein, carbs, fats & fiber.",
  ];

  String? selectedPreference;
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  String recommendedMeal =
      "Choose your preference, height, and weight to get AI meal recommendations.";

  final String? geminiApiKey = dotenv.env['GOOGLE_GEMINI_API_KEY'];

  Future<void> fetchMealRecommendation(
      String preference, String height, String weight) async {
    if (geminiApiKey == null || geminiApiKey!.isEmpty) {
      setState(() => recommendedMeal = "❌ Error: API Key is missing in .env file.");
      print('API Key missing: Ensure GOOGLE_GEMINI_API_KEY is set in .env');
      return;
    }

    setState(() => recommendedMeal = "⏳ Loading AI meal recommendation...");

    const maxRetries = 3;
    const baseDelayMs = 1000;
    int attempt = 0;

    while (attempt < maxRetries) {
      attempt++;
      try {
        print('Attempt $attempt: Sending request to Gemini API');
        final response = await http.post(
          Uri.parse(
              "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-latest:generateContent?key=$geminiApiKey"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "contents": [
              {
                "role": "user",
                "parts": [
                  {
                    "text":
                        "Suggest a healthy meal plan for a person who is $height cm tall, weighs $weight kg, and prefers a $preference diet."
                  }
                ]
              }
            ]
          }),
        ).timeout(const Duration(seconds: 15));

        print('API Response: Status=${response.statusCode}, Body=${response.body}');

        if (response.body.isEmpty) {
          setState(() => recommendedMeal = "❌ Error: Empty response from server.");
          print('Empty response received');
          return;
        }

        final data = jsonDecode(response.body);

        if (response.statusCode == 200 && data.containsKey("candidates")) {
          final content = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];
          if (content != null && content.isNotEmpty) {
            setState(() => recommendedMeal = content);
            print('Meal recommendation received: $content');
            return;
          } else {
            setState(() => recommendedMeal = "❌ Error: Invalid response structure.");
            print('Invalid response structure: Missing content');
            return;
          }
        } else if (data.containsKey("error")) {
          final errorMessage = data["error"]["message"] ?? "Unknown error";
          final errorCode = data["error"]["code"] ?? response.statusCode;
          print('API Error: Code=$errorCode, Message=$errorMessage');

          if (errorCode == 429 || errorCode == 500) {
            if (attempt < maxRetries) {
              final delay = (baseDelayMs * math.pow(2, attempt - 1)).toInt() +
                  math.Random().nextInt(100);
              print('Retrying after $delay ms due to error $errorCode');
              await Future.delayed(Duration(milliseconds: delay));
              continue;
            }
          }

          setState(() => recommendedMeal = "❌ Error: $errorMessage");
          return;
        } else {
          setState(() => recommendedMeal = "❌ Error: Unexpected API response.");
          print('Unexpected response: $data');
          return;
        }
      } catch (error) {
        print('Request error (Attempt $attempt): $error');
        if (error.toString().contains('SocketException') ||
            error.toString().contains('TimeoutException')) {
          if (attempt < maxRetries) {
            final delay = (baseDelayMs * math.pow(2, attempt - 1)).toInt() +
                math.Random().nextInt(100);
            print('Retrying after $delay ms due to network error');
            await Future.delayed(Duration(milliseconds: delay));
            continue;
          }
        }
        setState(() => recommendedMeal = "❌ Error: Failed to connect to server.");
        return;
      }
    }

    setState(() => recommendedMeal =
        "❌ Error: Failed to fetch recommendation after $maxRetries attempts.");
    print('Failed after $maxRetries attempts');
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
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: heightController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Height (cm)",
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white12,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Weight (kg)",
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white12,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedPreference,
                dropdownColor: Colors.deepPurple,
                decoration: const InputDecoration(
                  labelText: "Select Diet Preference",
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white12,
                ),
                items: preferences
                    .map((pref) => DropdownMenuItem(
                          value: pref,
                          child: Text(pref,
                              style: const TextStyle(color: Colors.white)),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => selectedPreference = value);
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final height = double.tryParse(heightController.text);
                  final weight = double.tryParse(weightController.text);

                  if (height == null || weight == null) {
                    setState(() {
                      recommendedMeal =
                          "❌ Please enter valid numeric values for height and weight.";
                    });
                  } else if (height < 50 || height > 250) {
                    setState(() {
                      recommendedMeal =
                          "❌ Height must be between 50 cm and 250 cm.";
                    });
                  } else if (weight < 10 || weight > 300) {
                    setState(() {
                      recommendedMeal =
                          "❌ Weight must be between 10 kg and 300 kg.";
                    });
                  } else if (selectedPreference == null) {
                    setState(() {
                      recommendedMeal = "❌ Please select a diet preference.";
                    });
                  } else {
                    fetchMealRecommendation(
                      selectedPreference!,
                      height.toString(),
                      weight.toString(),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: const Text("Get Meal Recommendation"),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  recommendedMeal,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "Quick Nutrition Tips 🥗",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              ...nutritionTips.map(
                (tip) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade300.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.deepPurpleAccent),
                  ),
                  child: Text(
                    tip,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}