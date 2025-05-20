import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_app/ui/screen/AppInfoPage.dart';
import 'package:fitness_app/ui/screen/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, String>? _cachedProfile;

  @override
  void initState() {
    super.initState();
    _loadCachedProfile().then((cache) {
      setState(() {
        _cachedProfile = cache;
      });
    });
  }

  // Cache profile data locally
  Future<void> _cacheProfileData(String name, String? email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', name);
    await prefs.setString('profile_email', email ?? 'No email');
    print('Cached profile: name=$name, email=${email ?? 'No email'}'); // Debug log
    setState(() {
      _cachedProfile = {'name': name, 'email': email ?? 'No email'};
    });
  }

  // Load cached profile data
  Future<Map<String, String>> _loadCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('profile_name') ?? 'User';
    final email = prefs.getString('profile_email') ?? 'No email';
    print('Loaded cached profile: name=$name, email=$email'); // Debug log
    return {'name': name, 'email': email};
  }

  // Clear cached profile data
  Future<void> _clearCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_name');
    await prefs.remove('profile_email');
    print('Cleared cached profile'); // Debug log
    setState(() {
      _cachedProfile = null;
    });
  }

  // Fetch user data from Firestore, prioritizing cache
  Future<DocumentSnapshot> _fetchUserData(String uid) async {
    try {
      print('Fetching Firestore data for UID: $uid'); // Debug log
      // Try cache first
      final cacheResult = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.cache));
      if (cacheResult.exists) {
        print('Data found in cache'); // Debug log
        return cacheResult;
      }
      // Fallback to server
      print('No cache, fetching from server'); // Debug log
      return await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 3), onTimeout: () {
        throw Exception('Firestore request timed out');
      });
    } catch (e) {
      print('Firestore fetch error: $e'); // Debug log
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Enable Firestore offline persistence
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
    print('Firebase app: ${Firebase.app().name}'); // Debug log
    print('Firestore persistence enabled'); // Debug log

    final User? user = FirebaseAuth.instance.currentUser;
    print('User: ${user?.uid}, Email: ${user?.email}, DisplayName: ${user?.displayName}'); // Debug log

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

    // Cache user data
    _cacheProfileData(user.displayName ?? 'User', user.email);

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
              onTap: () => _showDeleteAccountDialog(context, user),
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
    // Show cached or Firebase Auth data immediately
    final defaultName = _cachedProfile?['name'] ?? user.displayName ?? 'User';
    final defaultEmail = _cachedProfile?['email'] ?? user.email ?? 'No email';

    return FutureBuilder<DocumentSnapshot>(
      future: _fetchUserData(user.uid),
      builder: (context, snapshot) {
        print('Future snapshot: ${snapshot.hasData}, Error: ${snapshot.error}, State: ${snapshot.connectionState}'); // Debug log

        String name = defaultName;
        String email = defaultEmail;

        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          print('Firestore data: $userData'); // Debug log
          name = userData['name'] ?? name;
          email = userData['email'] ?? email;
          _cacheProfileData(name, email);
        }

        return Column(
          children: [
            const Icon(Icons.person, size: 80, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              name,
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              email,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
            ),
            if (snapshot.connectionState == ConnectionState.waiting && _cachedProfile == null) ...[
              const SizedBox(height: 8),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB39DDB)),
              ),
            ],
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

  void _showDeleteAccountDialog(BuildContext context, User user) {
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
                            print('Attempting to delete user account for UID: ${user.uid}'); // Debug log
                            await user.delete();
                            print('User account deleted, deleting Firestore document'); // Debug log
                            await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
                            print('Firestore document deleted'); // Debug log
                            await _clearCachedProfile();
                            Navigator.pop(context);
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                              (route) => false,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Account deleted successfully")),
                            );
                          } on FirebaseAuthException catch (e) {
                            print('Delete account error: ${e.code}, ${e.message}'); // Debug log
                            setState(() => isLoading = false);
                            Navigator.pop(context);
                            if (e.code == 'requires-recent-login') {
                              _showReauthenticationDialog(context, user);
                            } else {
                              String errorMessage = e.message ?? 'Failed to delete account';
                              if (e.code == 'user-mismatch') {
                                errorMessage = 'User session invalid. Please log out and log in again.';
                              } else if (e.code == 'invalid-credential') {
                                errorMessage = 'Invalid credentials. Please try again.';
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(errorMessage)),
                              );
                            }
                          } catch (e) {
                            print('Unexpected error: $e'); // Debug log
                            setState(() => isLoading = false);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('An unexpected error occurred')),
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

  void _showReauthenticationDialog(BuildContext context, User user) {
    TextEditingController passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.black,
              title: Text("Re-authenticate", style: GoogleFonts.poppins(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Please enter your password to verify your identity.",
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  _buildPasswordField(passwordController, "Password"),
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
                          final email = user.email;
                          final password = passwordController.text.trim();

                          if (email == null || password.isEmpty) {
                            setState(() => isLoading = false);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Password is required")),
                            );
                            return;
                          }

                          try {
                            print('Attempting re-authentication for email: $email'); // Debug log
                            final cred = EmailAuthProvider.credential(email: email, password: password);
                            await user.reauthenticateWithCredential(cred);
                            print('Re-authentication successful, retrying delete'); // Debug log
                            await user.delete();
                            print('User account deleted, deleting Firestore document'); // Debug log
                            await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
                            print('Firestore document deleted'); // Debug log
                            await _clearCachedProfile();
                            Navigator.pop(context);
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                              (route) => false,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Account deleted successfully")),
                            );
                          } on FirebaseAuthException catch (e) {
                            print('Re-authentication error: ${e.code}, ${e.message}'); // Debug log
                            String errorMessage = 'Failed to verify password';
                            switch (e.code) {
                              case 'wrong-password':
                                errorMessage = 'Incorrect password';
                                break;
                              case 'user-mismatch':
                                errorMessage = 'User session invalid. Please log out and log in again.';
                                break;
                              case 'invalid-credential':
                                errorMessage = 'Invalid credentials. Please try again.';
                                break;
                              case 'network-request-failed':
                                errorMessage = 'Network error. Please check your connection.';
                                break;
                              default:
                                errorMessage = e.message ?? 'Authentication error';
                            }
                            setState(() => isLoading = false);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(errorMessage)),
                            );
                          } catch (e) {
                            print('Unexpected error: $e'); // Debug log
                            setState(() => isLoading = false);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('An unexpected error occurred')),
                            );
                          }
                        },
                  child: isLoading ? const CircularProgressIndicator() : const Text("Verify"),
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