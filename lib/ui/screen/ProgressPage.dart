import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Progress 📊",
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple.shade700,
        elevation: 0,
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
          child: ListView(
            children: [
              const SizedBox(height: 20),
              _buildSectionTitle("📈 Weekly Workout Progress"),
              _buildBarChart(),
              const SizedBox(height: 30),
              _buildSectionTitle("🔥 Workout Breakdown"),
              _buildPieChart(),
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
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildBarChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade300,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4))],
      ),
      child: BarChart(
        BarChartData(
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ["M", "T", "W", "T", "F", "S", "S"];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      days[value.toInt()],
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            _buildBar(0, 6),
            _buildBar(1, 7),
            _buildBar(2, 5),
            _buildBar(3, 8),
            _buildBar(4, 6),
            _buildBar(5, 9),
            _buildBar(6, 4),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [BarChartRodData(toY: y, color: Colors.white, width: 18, borderRadius: BorderRadius.circular(6))],
    );
  }

  Widget _buildPieChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade300,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4))],
      ),
      child: PieChart(
        PieChartData(
          sections: [
            _buildPieChartSection(40, Colors.blue, "Cardio"),
            _buildPieChartSection(30, Colors.green, "Strength"),
            _buildPieChartSection(20, Colors.orange, "Yoga"),
            _buildPieChartSection(10, Colors.red, "Flexibility"),
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
      titleStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  Widget _buildProgressTip(String title, String description) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurpleAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(description, style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
        ],
      ),
    );
  }
}
