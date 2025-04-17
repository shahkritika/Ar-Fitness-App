import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> listAvailableModels() async {
  const String apiKey = "AIzaSyBazLN34dDI9gjo0yA_L3Ls8lH01m1oQHk"; 
  const String url = "https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey";

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("Available Models: ${data['models']}");
    } else {
      print("Failed to fetch models: ${response.statusCode}");
    }
  } catch (e) {
    print("Error fetching models: $e");
  }
}

void main() {
  listAvailableModels();
}