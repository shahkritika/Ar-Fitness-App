import 'package:flutter/material.dart';

class WorkoutPreviewPage extends StatelessWidget {
  final Map<String, String> workout;

  WorkoutPreviewPage({required this.workout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(workout['name']!)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(workout['image']!, height: 200),
          SizedBox(height: 20),
          Text(
            'How to Perform ${workout['name']}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Detailed instructions for performing ${workout['name']} effectively.',
              textAlign: TextAlign.center,
            ),
          ),
          Spacer(),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MotionTrackingPage(workout: workout['name']!),
                ),
              );
            },
            child: Text('Start Workout'),
          ),
        ],
      ),
    );
  }
}
