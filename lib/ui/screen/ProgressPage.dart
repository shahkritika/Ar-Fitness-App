import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({Key? key}) : super(key: key);

  @override
  _ProgressPageState createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Please log in to view progress 😎',
            style: GoogleFonts.orbitron(
              fontSize: 20,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 10,
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(2, 2),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('workouts')
          .doc(user.uid)
          .collection('sessions')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 7))))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading progress: ${snapshot.error}',
              style: GoogleFonts.orbitron(fontSize: 16, color: Colors.white),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No workouts this week. Get moving! 🚀',
              style: GoogleFonts.orbitron(fontSize: 16, color: Colors.white),
            ),
          );
        }

        // Process workout data
        final workouts = snapshot.data!.docs;
        final weeklyData = List<double>.filled(7, 0.0); // Reps or seconds per day
        final categoryData = {
          'Cardio': 0.0,
          'Strength': 0.0,
          'Yoga': 0.0,
          'Flexibility': 0.0,
        };

        for (var doc in workouts) {
          final data = doc.data() as Map<String, dynamic>;
          final bool isRepBased = data['isRepBased'] ?? true;
          final int reps = data['reps'] ?? 0;
          final double duration = (data['durationSeconds'] ?? 0.0).toDouble();
          final String category = data['category'] ?? 'Strength';
          final Timestamp? timestamp = data['timestamp'];

          if (timestamp != null) {
            final date = timestamp.toDate();
            final dayOfWeek = date.weekday - 1; // 0=Monday, 6=Sunday
            final value = isRepBased ? reps.toDouble() : duration;

            weeklyData[dayOfWeek] += value;

            // Map category to chart categories
            if (category.toLowerCase().contains('cardio')) {
              categoryData['Cardio'] = categoryData['Cardio']! + value;
            } else if (category.toLowerCase().contains('strength')) {
              categoryData['Strength'] = categoryData['Strength']! + value;
            } else if (category.toLowerCase().contains('yoga')) {
              categoryData['Yoga'] = categoryData['Yoga']! + value;
            } else {
              categoryData['Flexibility'] = categoryData['Flexibility']! + value;
            }
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              "Progress 📊",
              style: GoogleFonts.orbitron(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: const Color(0xFF6B48FF),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.fitness_center, color: Colors.white),
                onPressed: () {
                  Navigator.pushNamed(context, '/workout');
                },
                tooltip: 'Start Workout',
              ),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6B48FF), Color(0xFFA78BFA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  const SizedBox(height: 20),
                  _buildSectionTitle("📈 Weekly Workout Progress"),
                  _buildBarChart(weeklyData),
                  const SizedBox(height: 30),
                  _buildSectionTitle("🔥 Workout Breakdown"),
                  _buildPieChart(categoryData),
                  const SizedBox(height: 30),
                  _buildSectionTitle("💡 Progress Tips"),
                  _buildProgressTip("🏋️‍♂️ Consistency is Key", "Stick to your workout plan for best results."),
                  _buildProgressTip("🥗 Nutrition Matters", "Eat a balanced diet to fuel your body."),
                  _buildProgressTip("🛌 Recovery is Essential", "Ensure proper rest and recovery time."),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: GoogleFonts.orbitron(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildBarChart(List<double> weeklyData) {
    final maxY = weeklyData.reduce((a, b) => a > b ? a : b) * 1.2;
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4))],
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY > 0 ? maxY : 10.0, // Prevent zero maxY
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ["M", "T", "W", "T", "F", "S", "S"];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      days[value.toInt()],
                      style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (index) => _buildBar(index, weeklyData[index])),
        ),
      ),
    );
  }

  BarChartGroupData _buildBar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: Colors.white,
          width: 18,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  Widget _buildPieChart(Map<String, double> categoryData) {
    final total = categoryData.values.fold(0.0, (sum, value) => sum + value);
    if (total == 0) {
      return Container(
        height: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4))],
        ),
        child: const Center(
          child: Text(
            'No data to display',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4))],
      ),
      child: PieChart(
        PieChartData(
          sections: [
            if (categoryData['Cardio']! > 0)
              _buildPieChartSection(categoryData['Cardio']! / total * 100, Colors.blue, "Cardio"),
            if (categoryData['Strength']! > 0)
              _buildPieChartSection(categoryData['Strength']! / total * 100, Colors.green, "Strength"),
            if (categoryData['Yoga']! > 0)
              _buildPieChartSection(categoryData['Yoga']! / total * 100, Colors.orange, "Yoga"),
            if (categoryData['Flexibility']! > 0)
              _buildPieChartSection(categoryData['Flexibility']! / total * 100, Colors.red, "Flexibility"),
          ],
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  PieChartSectionData _buildPieChartSection(double value, Color color, String title) {
    return PieChartSectionData(
      value: value,
      color: color,
      radius: 50,
      title: title,
      titleStyle: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  Widget _buildProgressTip(String title, String description) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA78BFA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.orbitron(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}