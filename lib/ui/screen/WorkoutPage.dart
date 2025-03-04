import 'package:flutter/material.dart';
import 'ar_workout_page.dart';
import 'standard_workout_page.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({Key? key}) : super(key: key);

  @override
  _WorkoutPageState createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  int _selectedWorkoutIndex = -1;
  bool _isArMode = false;

  final List<Map<String, dynamic>> workouts = [
    {"name": "Strength", "icon": "assets/dumbel.png"},
    {"name": "Cardio", "icon": "assets/cardio.png"},
    {"name": "Yoga", "icon": "assets/yogaicon.png"},
    {"name": "HIIT", "icon": "assets/hiit.png"},
  ];

  void _navigateToWorkout() {
    if (_selectedWorkoutIndex == -1) return;

    String workoutName = workouts[_selectedWorkoutIndex]["name"];

    if (_isArMode) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ARWorkoutPage(
            workoutType: workoutName,
            onNextExercise: _goToNextExercise,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StandardWorkoutPage(workoutType: workoutName),
        ),
      );
    }
  }

  void _goToNextExercise() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFFB39DDB),
        elevation: 0,
        title: const Text(
          "Choose Your Workout",
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Color(0xFFB39DDB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: workouts.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedWorkoutIndex = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: _selectedWorkoutIndex == index ? const Color(0xFFB39DDB) : const Color(0xFF1E1E2C),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _selectedWorkoutIndex == index
                            ? [
                                BoxShadow(
                                  color: Colors.purpleAccent.withOpacity(0.7),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Image.asset(
                                workouts[index]["icon"],
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            workouts[index]["name"],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildModeSelection(),
            const SizedBox(height: 20),
            _buildStartButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFB39DDB),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          children: [
            const Text(
              "Select Mode",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildModeButton("Standard", Icons.smartphone, false),
                _buildModeButton("AR Mode", Icons.headset, true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(String label, IconData icon, bool isArMode) {
    bool isSelected = _isArMode == isArMode;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isArMode = isArMode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.black : Colors.white, size: 30),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return ElevatedButton(
      onPressed: _selectedWorkoutIndex == -1 ? null : _navigateToWorkout,
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedWorkoutIndex == -1 ? Colors.grey : const Color(0xFFB39DDB),
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Text(
        "Start Workout",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}
