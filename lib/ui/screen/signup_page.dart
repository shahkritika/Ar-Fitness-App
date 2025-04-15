import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false; // For showing a loading indicator

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to handle signup
  Future<void> _signup() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    String email = _emailController.text.trim();

    if (username.isEmpty || password.isEmpty || email.isEmpty) {
      _showSnackBar("Please fill in all fields", Colors.red);
      return;
    }

    setState(() => _isLoading = true); // Show loading

    try {
      // Create a new user with email and password in Firebase
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // User successfully registered
      setState(() => _isLoading = false); // Hide loading
      _showSnackBar("Signup successful!", Colors.green);

      // Optionally, you can set the username in Firebase (this step is optional and depends on your app's requirement)
      User? user = userCredential.user;
      if (user != null) {
        // You can set displayName or save additional user info to Firestore if required.
        await user.updateDisplayName(username);
      }

      // Navigate to login page after successful signup
      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false); // Hide loading
      if (e.code == 'weak-password') {
        _showSnackBar("The password is too weak.", Colors.red);
      } else if (e.code == 'email-already-in-use') {
        _showSnackBar("The email is already in use.", Colors.red);
      } else {
        _showSnackBar("Signup failed: ${e.message}", Colors.red);
      }
    } catch (e) {
      setState(() => _isLoading = false); // Hide loading
      _showSnackBar("Error: $e", Colors.red);
    }
  }

  // Function to show snack bar messages
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark theme
      appBar: AppBar(
        title: Text("Signup"),
        backgroundColor: const Color(0xFF2E1A5F), // Dark purple
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Create Your Account",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFB39DDB), // Light purple
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: const Color(0xFFB39DDB)),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: const Color(0xFFB39DDB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: const Color(0xFFB39DDB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: const Color(0xFFB39DDB)),
                ),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _emailController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: const Color(0xFFB39DDB)),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: const Color(0xFFB39DDB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: const Color(0xFFB39DDB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: const Color(0xFFB39DDB)),
                ),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: const Color(0xFFB39DDB)),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: const Color(0xFFB39DDB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: const Color(0xFFB39DDB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: const Color(0xFFB39DDB)),
                ),
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator(color: const Color(0xFFB39DDB))
                : ElevatedButton(
                    onPressed: _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB39DDB),
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    child: Text(
                      "Sign Up",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: Text(
                "Already have an account? Login here",
                style: TextStyle(color: const Color(0xFFB39DDB)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
