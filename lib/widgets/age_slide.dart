import 'package:flutter/material.dart';

class AgeSlide extends StatelessWidget {
  final int age;
  final ValueChanged<int> onChanged;

  const AgeSlide({Key? key, required this.age, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Age: $age", style: TextStyle(fontSize: 18)),
        Slider(
          value: age.toDouble(),
          min: 10,
          max: 100,
          divisions: 90,
          label: "$age",
          onChanged: (value) => onChanged(value.toInt()),
        ),
      ],
    );
  }
}