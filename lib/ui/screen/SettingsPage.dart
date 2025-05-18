import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_app/ui/screen/AppInfoPage.dart';
import 'package:fitness_app/ui/screen/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:math' as math;
import 'dart:io' show Platform, SocketException, InternetAddress;

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // Check network connectivity
  Future<bool> _checkNetwork() async {
    try {
      final result = await InternetAddress.lookup('firestore.googleapis.com');
      bool isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      print('Network check: firestore.googleapis.com reachable = $isConnected'); // Debug log
      return isConnected;
    } on SocketException catch (e) {
      print('Network check failed: $e'); // Debug log
      return false;
    }
  }

  // Cache profile data locally
  Future<void> _cacheProfileData(String name, String? email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', name);
    await prefs.setString('profile_email', email ?? 'No email');
    print('Cached profile: name=$name, email=${email ?? 'No email'}'); // Debug log
  }

  // Load cached profile data
  Future<Map<String, String>> _loadCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('profile_name') ?? 'User';
    final email = prefs.getString('profile_email') ?? 'No email';
    print('Loaded cached profile: name=$name, email=$email'); // Debug log
    return {'name': name, 'email': email};
  }

  // Retry Firestore query with exponential backoff and jitter
  Future<DocumentSnapshot> _fetchUserData(String uid, {int retryCount = 10, int baseDelayMs = 1000}) async {
    bool hasNetwork = await _checkNetwork();
    print('Network status: $hasNetwork'); // Debug log
    if (!hasNetwork) {
      throw Exception('No internet connection detected');
    }

    print('Firestore instance: ${FirebaseFirestore.instance.app.name}'); // Debug log
    for (int attempt = 1; attempt <= retryCount; attempt++) {
      try {
        print('Attempt $attempt: Fetching Firestore data for UID: $uid'); // Debug log
        return await FirebaseFirestore.instance.collection('users').doc(uid).get();
      } catch (e) {
        print('Firestore attempt $attempt failed: $e'); // Debug log
        if (e.toString().contains('unavailable') && attempt < retryCount) {
          int delay = (baseDelayMs * math.pow(2, attempt - 1)).toInt() + math.Random().nextInt(100);
          print('Retrying after $delay ms'); // Debug log
          await Future.delayed(Duration(milliseconds: delay));
          continue;
        }
        rethrow;
      }
    }
    throw Exception('Failed to fetch Firestore data after $retryCount attempts');
  }

  @override
  Widget build(BuildContext context) {
    // Enable Firestore offline persistence
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
    print('Firebase app: ${Firebase.app().name}'); // Debug log
    print('Firestore persistence enabled'); // Debug log

    final User? user = FirebaseAuth.instance.currentUser;
    print('User: ${user?.uid}, Email: ${user?.email}, RefreshToken: ${user?.refreshToken}'); // Debug log

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.black,
        elevation: 5,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Color(0xFFB39DDB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildProfileSection(user),
            const SizedBox(height: 30),
            _buildSettingOption(
              context,
              title: "Change Password",
              icon: Icons.lock,
              onTap: () => _showChangePasswordDialog(context),
            ),
            _buildSettingOption(
              context,
              title: "Delete Account",
              icon: Icons.delete,
              iconColor: Colors.red,
              onTap: () => _showDeleteAccountDialog(context),
            ),
            _buildSettingOption(
              context,
              title: "App Info",
              icon: Icons.info,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AppInfoPage()),
              ),
            ),
            const SizedBox(height: 20),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(User user) {
    return FutureBuilder<DocumentSnapshot>(
      future: _fetchUserData(user.uid).timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception('Firestore request timed out');
      }),
      builder: (context, snapshot) {
        print('Firestore snapshot: ${snapshot.hasData}, Error: ${snapshot.error}, State: ${snapshot.connectionState}'); // Debug log
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print('Firestore error: ${snapshot.error}'); // Debug log
          String errorMessage = 'Failed to load profile';
          if (snapshot.error.toString().contains('unavailable') || snapshot.error.toString().contains('No internet')) {
            errorMessage = 'No internet connection. Please check your network and try again.';
          } else if (snapshot.error.toString().contains('permission-denied')) {
            errorMessage = 'Permission denied. Check Firebase configuration or contact support.';
          } else if (snapshot.error.toString().contains('timed out')) {
            errorMessage = 'Request timed out. Check your internet and try again.';
          }
          // Load cached profile as fallback
          return FutureBuilder<Map<String, String>>(
            future: _loadCachedProfile(),
            builder: (context, cacheSnapshot) {
              if (!cacheSnapshot.hasData) {
                return Center(
                  child: Column(
                    children: [
                      Text(
                        errorMessage,
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsPage()),
                        ),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                );
              }
              final cache = cacheSnapshot.data!;
              return Column(
                children: [
                  Text(
                    cache['name']!,
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    cache['email']!,
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Using cached data due to: $errorMessage',
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsPage()),
                    ),
                    child: const Text("Retry"),
                  ),
                ],
              );
            },
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          print('Firestore data: No document found for UID: ${user.uid}'); // Debug log
          // Cache default profile
          _cacheProfileData('User', user.email);
          return Column(
            children: [
              Text(
                'User',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                user.email ?? 'No email',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Text(
                'No profile data found. Please update your profile.',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
            ],
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        print('Firestore data: $userData'); // Debug log
        final name = userData['name'] ?? 'User';
        final email = user.email ?? 'No email';
        // Cache successful fetch
        _cacheProfileData(name, email);

        return Column(
          children: [
            Text(
              name,
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              email,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingOption(BuildContext context, {required String title, required IconData icon, Color? iconColor, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.white),
      title: Text(title, style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Colors.white.withOpacity(0.1),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      visualDensity: const VisualDensity(vertical: 3),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    TextEditingController oldPasswordController = TextEditingController();
    TextEditingController newPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.black,
              title: Text("Change Password", style: GoogleFonts.poppins(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPasswordField(oldPasswordController, "Current Password"),
                  const SizedBox(height: 10),
                  _buildPasswordField(newPasswordController, "New Password"),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);
                          final user = FirebaseAuth.instance.currentUser;
                          final email = user?.email;
                          final oldPassword = oldPasswordController.text.trim();
                          final newPassword = newPasswordController.text.trim();

                          print('Change Password - Email: $email, Old Password: $oldPassword, New Password: $newPassword'); // Debug log

                          if (email == null || oldPassword.isEmpty || newPassword.isEmpty) {
                            setState(() => isLoading = false);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("All fields are required")),
                            );
                            return;
                          }

                          if (newPassword.length < 6) {
                            setState(() => isLoading = false);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("New password must be at least 6 characters")),
                            );
                            return;
                          }

                          try {
                            print('Attempting reauthentication'); // Debug log
                            final cred = EmailAuthProvider.credential(email: email, password: oldPassword);
                            await user!.reauthenticateWithCredential(cred);
                            print('Reauthentication successful, updating password'); // Debug log
                            await user.updatePassword(newPassword);
                            print('Password updated successfully'); // Debug log
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Password updated successfully")),
                            );
                          } catch (e) {
                            print('Password change error: $e'); // Debug log
                            String errorMessage = 'An error occurred';
                            if (e is FirebaseAuthException) {
                              print('FirebaseAuthException code: ${e.code}, message: ${e.message}'); // Debug log
                              switch (e.code) {
                                case 'wrong-password':
                                  errorMessage = 'Incorrect current password';
                                  break;
                                case 'requires-recent-login':
                                  errorMessage = 'Session expired. Please log out and log in again.';
                                  break;
                                case 'network-request-failed':
                                  errorMessage = 'Network error. Please check your internet connection.';
                                  break;
                                default:
                                  errorMessage = e.message ?? 'Authentication error';
                              }
                            }
                            setState(() => isLoading = false);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(errorMessage)),
                            );
                          }
                        },
                  child: isLoading ? const CircularProgressIndicator() : const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.black,
              title: Text("Delete Account", style: GoogleFonts.poppins(color: Colors.red)),
              content: Text(
                "Are you sure you want to delete your account? This action is irreversible.",
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);
                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            print('Deleting Firestore document for UID: ${user?.uid}'); // Debug log
                            await FirebaseFirestore.instance.collection('users').doc(user?.uid).delete();
                            print('Deleting user account'); // Debug log
                            await user?.delete();
                            print('Account deleted'); // Debug log
                            Navigator.pop(context);
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                              (route) => false,
                            );
                          } catch (e) {
                            print('Delete account error: $e'); // Debug log
                            String errorMessage = 'An error occurred';
                            if (e is FirebaseAuthException) {
                              print('FirebaseAuthException code: ${e.code}, message: ${e.message}'); // Debug log
                              errorMessage = e.message ?? 'Authentication error';
                            }
                            setState(() => isLoading = false);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(errorMessage)),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: isLoading ? const CircularProgressIndicator() : const Text("Delete"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
      child: GestureDetector(
        onTap: () => _showLogoutDialog(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.deepPurpleAccent, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: TweenAnimationBuilder(
            duration: const Duration(milliseconds: 300),
            tween: Tween<double>(begin: 1, end: 1.05),
            curve: Curves.easeInOut,
            builder: (context, double scale, child) {
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Text(
              "Log Out",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text("Log Out", style: GoogleFonts.poppins(color: Colors.white)),
          content: Text("Are you sure you want to log out?", style: GoogleFonts.poppins(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                print('Logging out'); // Debug log
                await FirebaseAuth.instance.signOut();
                print('Logged out'); // Debug log
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text("Log Out"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      obscureText: true,
      style: GoogleFonts.poppins(color: Colors.white),
    );
  }
}