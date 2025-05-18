import 'package:flutter/material.dart';
import 'ExerciseListPage.dart';
import 'ProgressPage.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({Key? key}) : super(key: key);

  @override
  _WorkoutPageState createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  int _selectedWorkoutIndex = -1;

  final List<Map<String, dynamic>> workouts = [
    {"name": "Strength", "icon": "assets/dumbel.png"},
    {"name": "Cardio", "icon": "assets/cardio.png"},
    {"name": "Yoga", "icon": "assets/yogaicon.png"},
    {"name": "HIIT", "icon": "assets/hiit.png"},
  ];

  void _navigateToExerciseList() {
    if (_selectedWorkoutIndex == -1) return;

    String workoutName = workouts[_selectedWorkoutIndex]["name"];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseListPage(workoutType: workoutName),
      ),
    );
  }

  void _navigateToProgress() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProgressPage()),
    );
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
          style: TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            onPressed: _navigateToProgress,
            tooltip: 'View Progress',
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
                        color: _selectedWorkoutIndex == index
                            ? const Color(0xFFB39DDB)
                            : const Color(0xFF1E1E2C),
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
            ElevatedButton(
              onPressed: _selectedWorkoutIndex == -1 ? null : _navigateToExerciseList,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB39DDB),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Select Exercises',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}