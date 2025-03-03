import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'WorkoutPage.dart';
import 'NutritionPage.dart';
import 'ProgressPage.dart';
import 'SettingsPage.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardContent(),
      WorkoutPage(), // Added WorkoutPage here
      ProgressPage(),
      SettingsPage(),
      NutritionPage(),
    ];
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Color(0xFFB39DDB),
        unselectedItemColor: Colors.white70,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.poppins(),
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard, size: 30), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center, size: 30), label: "Workout"), // Workout Tab
          BottomNavigationBarItem(icon: Icon(Icons.show_chart, size: 30), label: "Progress"),
          BottomNavigationBarItem(icon: Icon(Icons.settings, size: 30), label: "Settings"),
          BottomNavigationBarItem(icon: Icon(Icons.fastfood, size: 30), label: "Nutrition"),
        ],
      ),
    );
  }
}

class DashboardContent extends StatelessWidget {
  String _getGreeting() {
    int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "Good Morning, Fitness Enthusiast!";
    } else if (hour >= 12 && hour < 18) {
      return "Good Afternoon, Fitness Enthusiast!";
    } else {
      return "Good Evening, Fitness Enthusiast!";
    }
  }

  final List<Map<String, String>> exercises = [
    {"name": "Squat", "image": "assets/Squat.jpg"},
    {"name": "Pushups", "image": "assets/Pushups.jpg"},
    {"name": "Lunges", "image": "assets/Lunges.jpg"},
    {"name": "Plank", "image": "assets/Plank.jpg"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Color(0xFFB39DDB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                _getGreeting(),
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Color(0xFFB39DDB).withOpacity(0.2),
                ),
                child: Text(
                  "Train like a beast, look like a beauty!",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Recommended Workouts",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkoutPage()));
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 16),
                        width: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.black,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              Image.asset(
                                exercises[index]["image"]!,
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                bottom: 10,
                                left: 10,
                                child: Text(
                                  exercises[index]["name"]!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "Nutrition Tips",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              _buildNutritionTip("Eat a variety of whole foods for maximum nutrition.", Icons.food_bank),
              _buildNutritionTip("Stay hydrated! Drink at least 2 liters of water daily.", Icons.local_drink),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionTip(String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFB39DDB).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFFB39DDB), size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
