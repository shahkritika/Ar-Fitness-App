import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitness_app/ui/screen/AppInfoPage.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.black,
        elevation: 5,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Color(0xFFB39DDB)], // Matching Dashboard Theme
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
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

  // 🔥 Universal Tile for Settings Options
  Widget _buildSettingOption(BuildContext context,
      {required String title, required IconData icon, Color? iconColor, required VoidCallback onTap}) {
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

  // 🔒 Change Password Dialog
  void _showChangePasswordDialog(BuildContext context) {
    TextEditingController oldPasswordController = TextEditingController();
    TextEditingController newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
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
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // ❌ Delete Account Confirmation
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text("Delete Account", style: GoogleFonts.poppins(color: Colors.red)),
          content: Text(
            "Are you sure you want to delete your account? This action is irreversible.",
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  // 🔥 Styled Logout Button with Animation
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
            gradient: LinearGradient(
              colors: [Colors.deepPurpleAccent, Colors.purple], // 🔥 Vibrant colors
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

  // 🚀 Logout Confirmation Dialog
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
              onPressed: () {
                // Handle logout logic here
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text("Log Out"),
            ),
          ],
        );
      },
    );
  }

  // 🔒 Password TextField Builder
  Widget _buildPasswordField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      obscureText: true,
      style: GoogleFonts.poppins(color: Colors.white),
    );
  }
}
