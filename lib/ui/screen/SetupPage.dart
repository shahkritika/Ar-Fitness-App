import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/theme/theme_provider.dart';
//import 'package:fitness_app/ui/widgets/age_slide.dart';
//import 'package:fitness_app/ui/widgets/weight_slide.dart';
//import 'package:fitness_app/ui/widgets/height_slide.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SetupPage(),
        );
      },
    );
  }
}

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  _SetupPageState createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.currentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: _currentPage > 0
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: themeProvider.currentTheme.iconTheme.color),
                onPressed: _previousPage,
              )
            : null,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: PageView(
        controller: _controller,
        onPageChanged: (index) {
          setState(() => _currentPage = index);
        },
        children: [
          GenderSlide(onContinue: _nextPage),
          AgeSlide(onContinue: _nextPage),
          WeightSlide(onContinue: _nextPage),
          HeightSlide(onContinue: _nextPage),
          ProfileSlide(onStart: _startApp),
        ],
      ),
    );
  }

  void _nextPage() {
    _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  void _previousPage() {
    _controller.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  void _startApp() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const HomePage()));
  }
}

class GenderSlide extends StatelessWidget {
  final VoidCallback onContinue;

  const GenderSlide({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Text(
            "Select Your Gender",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, color: themeProvider.currentTheme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Column(
            children: [
              GenderIcon(icon: Icons.male, label: "Male"),
              const SizedBox(height: 40),
              GenderIcon(icon: Icons.female, label: "Female"),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(backgroundColor: themeProvider.currentTheme.primaryColor, padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15)),
            child: const Text("Continue", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class GenderIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const GenderIcon({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Column(
      children: [
        GestureDetector(
          onTap: () {},
          child: Container(
            decoration: BoxDecoration(color: themeProvider.currentTheme.primaryColor, shape: BoxShape.circle),
            padding: const EdgeInsets.all(40),
            child: Icon(icon, color: Colors.white, size: 60),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: TextStyle(fontSize: 20, color: themeProvider.currentTheme.textTheme.bodyLarge?.color)),
      ],
    );
  }
}

class ProfileSlide extends StatelessWidget {
  final VoidCallback onStart;

  const ProfileSlide({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Text(
            "Create Your Profile",
            style: TextStyle(fontSize: 28, color: themeProvider.currentTheme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          CircleAvatar(
            radius: 50,
            backgroundColor: themeProvider.currentTheme.primaryColor,
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 30),
          _buildTextField("Full Name"),
          _buildTextField("Nickname"),
          _buildTextField("Email"),
          _buildTextField("Mobile Number"),
          const Spacer(),
          ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(backgroundColor: themeProvider.currentTheme.primaryColor, padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15)),
            child: const Text("Start", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.withOpacity(0.1),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.currentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Home Page"),
        backgroundColor: themeProvider.currentTheme.primaryColor,
      ),
      body: Center(
        child: Text(
          "Welcome to the Fitness App!",
          style: TextStyle(color: themeProvider.currentTheme.textTheme.bodyLarge?.color, fontSize: 24),
        ),
      ),
    );
  }
}
