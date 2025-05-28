import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({Key? key}) : super(key: key);

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  List<Map<String, dynamic>> _summaries = [];
  bool _isLoading = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _auth.authStateChanges().listen((User? user) {
      if (user != null && user.uid != _currentUserId) {
        _currentUserId = user.uid;
        _fetchWorkoutSummaries();
      } else if (user == null) {
        _currentUserId = null;
        setState(() {
          _summaries = [];
          _isLoading = false;
        });
      }
    });

    final user = _auth.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      await _fetchWorkoutSummaries();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchWorkoutSummaries() async {
    try {
      if (_currentUserId == null) {
        setState(() {
          _summaries = [];
          _isLoading = false;
        });
        return;
      }

      final box = await Hive.openBox('workouts_$_currentUserId');
      final summaries = box.values
          .whereType<Map<String, dynamic>>()
          .where((summary) {
            // Filter out summaries with invalid exerciseName
            final exerciseName = summary['exerciseName']?.toString();
            final isValid = exerciseName != null && exerciseName.isNotEmpty && exerciseName.toLowerCase() != 'unknown';
            if (!isValid) {
              print('Filtered out invalid summary: exerciseName=$exerciseName, date=${summary['date']}');
            }
            return isValid;
          })
          .toList()
          .reversed
          .toList();

      // Debug: Log all exercise names
      for (var summary in summaries) {
        print('Workout summary: exerciseName=${summary['exerciseName']}, date=${summary['date']}');
      }

      setState(() {
        _summaries = summaries;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching summaries: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load progress: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFFB39DDB),
        title: Text(
          'Workout Progress',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
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
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _summaries.isEmpty
                ? Center(
                    child: Text(
                      _currentUserId == null
                          ? 'Please login to view your progress'
                          : 'No workouts recorded yet! Start training! 💪',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good vs Bad Reps (Latest Workout)',
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 220,
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(color: Colors.white24, width: 1),
                                ),
                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      getTitlesWidget: (value, meta) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            value == 0 ? 'Good' : 'Bad',
                                            style: GoogleFonts.roboto(color: Colors.white, fontSize: 12),
                                          ),
                                        );
                                      },
                                    ),
                                    axisNameWidget: Text(
                                      'Rep Type',
                                      style: GoogleFonts.roboto(color: Colors.white, fontSize: 14),
                                    ),
                                    axisNameSize: 24,
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (value, meta) => Text(
                                        value.toInt().toString(),
                                        style: GoogleFonts.roboto(color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                    axisNameWidget: Text(
                                      'Number of Reps',
                                      style: GoogleFonts.roboto(color: Colors.white, fontSize: 14),
                                    ),
                                    axisNameSize: 24,
                                  ),
                                ),
                                minY: 0,
                                maxY: _summaries.isNotEmpty
                                    ? (_summaries.first['goodReps'] + _summaries.first['badReps'] + 5).toDouble()
                                    : 10.0,
                                barGroups: [
                                  BarChartGroupData(
                                    x: 0,
                                    barRods: [
                                      BarChartRodData(
                                        toY: _summaries.isNotEmpty ? _summaries.first['goodReps'].toDouble() : 0,
                                        color: Colors.green,
                                        width: 20,
                                      ),
                                    ],
                                  ),
                                  BarChartGroupData(
                                    x: 1,
                                    barRods: [
                                      BarChartRodData(
                                        toY: _summaries.isNotEmpty ? _summaries.first['badReps'].toDouble() : 0,
                                        color: Colors.red,
                                        width: 20,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Workout Mode Distribution',
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 220,
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 50,
                                sections: [
                                  PieChartSectionData(
                                    color: const Color(0xFF6B48FF),
                                    value: _summaries.where((s) => s['mode'] == 'AR').length.toDouble(),
                                    title: 'AR',
                                    radius: 60,
                                    titleStyle: GoogleFonts.roboto(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    color: const Color(0xFFA78BFA),
                                    value: _summaries.where((s) => s['mode'] == 'Standard').length.toDouble(),
                                    title: 'Standard',
                                    radius: 60,
                                    titleStyle: GoogleFonts.roboto(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Workout History',
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._summaries.asMap().entries.map((entry) {
                            final index = entry.key;
                            final summary = entry.value;
                            final date = DateTime.parse(summary['date']);
                            // Format exerciseName for display
                            final rawExerciseName = summary['exerciseName']?.toString() ?? 'Unnamed Workout';
                            final exerciseName = rawExerciseName
                                .split('_')
                                .map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
                                .join(' ');
                            final totalReps = summary['totalReps'] ?? 0;
                            final goodReps = summary['goodReps'] ?? 0;
                            final badReps = summary['badReps'] ?? 0;
                            final mode = summary['mode'] ?? 'Unknown';
                            final duration = summary['durationSeconds']?.toStringAsFixed(1) ?? '0.0';
                            final isLatest = index == 0;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Color(0xFFB39DDB), width: 1),
                              ),
                              color: Colors.white.withOpacity(0.95),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isLatest ? 'Latest Workout: $exerciseName' : 'Workout: $exerciseName',
                                      style: GoogleFonts.roboto(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Date: ${date.day}/${date.month}/${date.year}',
                                      style: GoogleFonts.roboto(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      'Total Reps: $totalReps (Good: $goodReps, Bad: $badReps)',
                                      style: GoogleFonts.roboto(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      'Mode: $mode',
                                      style: GoogleFonts.roboto(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      'Duration: $duration seconds',
                                      style: GoogleFonts.roboto(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _generateSummaryDescription(summary),
                                      style: GoogleFonts.roboto(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 24), // Extra padding at the bottom
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  String _generateSummaryDescription(Map<String, dynamic> summary) {
    final rawExerciseName = summary['exerciseName']?.toString() ?? 'Unnamed Workout';
    final exerciseName = rawExerciseName
        .split('_')
        .map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
        .join(' ');
    final goodReps = summary['goodReps'] ?? 0;
    final badReps = summary['badReps'] ?? 0;
    final totalReps = summary['totalReps'] ?? 0;
    final duration = summary['durationSeconds']?.toDouble() ?? 0.0;
    final mode = summary['mode'] ?? 'Unknown';

    final goodRepPercentage = totalReps > 0 ? (goodReps / totalReps * 100).toStringAsFixed(1) : '0.0';

    if (summary['isRepBased'] == false) {
      return 'You held a $exerciseName in $mode mode for $duration seconds. ' +
             'Your form was ${summary['isGoodForm'] == true ? 'excellent' : 'inconsistent'}, ' +
             'maintaining a stable position throughout.';
    } else {
      return 'You completed $totalReps reps of $exerciseName in $mode mode, ' +
             'with $goodRepPercentage% good reps. ' +
             (goodReps >= badReps ? 'Great form overall!' : 'Focus on improving form for better results.');
    }
  }
}