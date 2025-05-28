import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:fitness_app/ui/screen/Dashboard.dart';
import 'package:fitness_app/ui/screen/ProgressPage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _username;
  String? _email;
  bool _isLoading = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // First try to get fresh data from Firebase
        await user.reload();
        final refreshedUser = _auth.currentUser;

        // Then check Hive for any additional data
        final box = await Hive.openBox('user_data');
        final hiveUserData = box.get(refreshedUser?.uid);

        setState(() {
          _username = refreshedUser?.displayName ?? hiveUserData?['username'] ?? 'User';
          _email = refreshedUser?.email ?? hiveUserData?['email'] ?? 'No email';
          _isLoading = false;
        });

        // Ensure Hive has the latest data
        if (refreshedUser != null) {
          await box.put(refreshedUser.uid, {
            'username': refreshedUser.displayName ?? _username,
            'email': refreshedUser.email ?? _email,
            'lastUpdated': DateTime.now().toIso8601String(),
          });
        }
      } else {
        setState(() {
          _username = 'Guest';
          _email = 'Not logged in';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _username = 'Error';
        _email = 'Error loading data';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUsername(String newUsername) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Update in Firebase
        await user.updateDisplayName(newUsername);
        await user.reload();

        // Update in Hive
        final box = await Hive.openBox('user_data');
        await box.put(user.uid, {
          'username': newUsername,
          'email': user.email ?? _email,
          'lastUpdated': DateTime.now().toIso8601String(),
        });

        setState(() {
          _username = newUsername;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username updated successfully')),
          );
        }
      }
    } catch (e) {
      print('Error updating username: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update username: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('Error logging out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to logout: $e')),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Hive
        final userBox = await Hive.openBox('user_data');
        final workoutBox = await Hive.openBox('workouts_${user.uid}');

        await userBox.delete(user.uid);
        await workoutBox.clear();

        // Delete Firebase account
        await user.delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted successfully')),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      print('Error deleting account: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Create a TextEditingController for the TextField
    final TextEditingController _usernameController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB39DDB),
        title: Text(
          'Settings',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/dumbel.png',
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              height: 24,
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DashboardPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProgressPage()),
              );
            },
          ),
        ],
      ),
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : ListView(
                  children: [
                    _buildProfileSection(),
                    const SizedBox(height: 20),
                    _buildSettingsTile(
                      icon: Icons.edit,
                      title: 'Update Username',
                      onTap: () async {
                        final newUsername = await showDialog<String>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Update Username', style: GoogleFonts.orbitron()),
                            content: TextField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'New Username',
                                labelStyle: GoogleFonts.orbitron(color: Colors.black54),
                              ),
                              style: GoogleFonts.orbitron(color: Colors.black),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel', style: GoogleFonts.orbitron()),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, _usernameController.text);
                                },
                                child: Text('Save', style: GoogleFonts.orbitron()),
                              ),
                            ],
                          ),
                        );
                        _usernameController.dispose();
                        if (newUsername != null && newUsername.isNotEmpty) {
                          await _updateUsername(newUsername);
                        }
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.info,
                      title: 'App Info',
                      onTap: () => Navigator.pushNamed(context, '/app_info'),
                    ),
                    _buildSettingsTile(
                      icon: Icons.logout,
                      title: 'Logout',
                      onTap: () async {
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Logout', style: GoogleFonts.orbitron()),
                            content: Text('Are you sure you want to logout?', style: GoogleFonts.orbitron()),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel', style: GoogleFonts.orbitron()),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await _logout();
                                },
                                child: Text('Logout', style: GoogleFonts.orbitron(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.delete_forever,
                      title: 'Delete Account',
                      titleColor: Colors.red,
                      onTap: () async {
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Delete Account', style: GoogleFonts.orbitron()),
                            content: Text(
                              'Are you sure you want to delete your account? This action cannot be undone.',
                              style: GoogleFonts.orbitron(),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel', style: GoogleFonts.orbitron()),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await _deleteAccount();
                                },
                                child: Text('Delete', style: GoogleFonts.orbitron(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage('assets/default_avatar.jpg'),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _username ?? 'User',
                style: GoogleFonts.orbitron(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                _email ?? 'email@example.com',
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: GoogleFonts.orbitron(
          color: titleColor ?? Colors.white,
          fontSize: 16,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
      onTap: onTap,
    );
  }
}