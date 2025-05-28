import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signup() async {
    // Validate inputs
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();

    if (email.isEmpty || password.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if email is already registered
      try {
        final signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
        if (signInMethods.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email is already registered. Please log in.')),
          );
          setState(() => _isLoading = false);
          return;
        }
      } catch (e) {
        print('Error checking email: $e');
        // Continue with signup, as this is just a pre-check
      }

      // Create user with Firebase
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update Firebase user profile
      await credential.user?.updateDisplayName(username);
      await credential.user?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || user.displayName != username) {
        print('Warning: Firebase displayName not set correctly. Current displayName: ${user?.displayName}');
        // Attempt to set again
        await user?.updateDisplayName(username);
        await user?.reload();
      }

      // Save to Hive users box
      final box = await Hive.openBox('users');
      await box.put(credential.user?.uid, {
        'name': username,
        'email': email,
      });

      // Verify Hive data
      final hiveData = box.get(credential.user?.uid) as Map<String, dynamic>?;
      print('Signed up user: uid=${credential.user?.uid}, username=$username, email=$email');
      print('Hive data saved: $hiveData'); // Debug log

      if (hiveData == null || hiveData['name'] != username || hiveData['email'] != email) {
        print('Error: Hive data verification failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save user data locally')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup successful! Please log in.')),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Email is already registered. Please log in.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format.';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak.';
          break;
        default:
          errorMessage = 'Signup failed: ${e.message}';
      }
      print('Signup error: $e, code: ${e.code}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('Unexpected signup error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup failed: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Color(0xFFB39DDB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sign Up',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: GoogleFonts.orbitron(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                    border: const OutlineInputBorder(),
                    errorStyle: GoogleFonts.orbitron(color: Colors.redAccent),
                  ),
                  style: GoogleFonts.orbitron(color: Colors.white),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: GoogleFonts.orbitron(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                    border: const OutlineInputBorder(),
                    errorStyle: GoogleFonts.orbitron(color: Colors.redAccent),
                  ),
                  style: GoogleFonts.orbitron(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: GoogleFonts.orbitron(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                    border: const OutlineInputBorder(),
                    errorStyle: GoogleFonts.orbitron(color: Colors.redAccent),
                  ),
                  style: GoogleFonts.orbitron(color: Colors.white),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _isLoading ? null : _signup(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B48FF),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Sign Up',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pushNamed(context, '/login'),
                  child: Text(
                    'Already have an account? Log In',
                    style: GoogleFonts.orbitron(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}