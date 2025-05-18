import 'package:flutter/material.dart';

class WeightSlide extends StatelessWidget {
  final double weight;
  final ValueChanged<double> onChanged;

  const WeightSlide({Key? key, required this.weight, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Weight: ${weight.toStringAsFixed(1)} kg", style: TextStyle(fontSize: 18)),
        Slider(
          value: weight,
          min: 30,
          max: 200,
          divisions: 170,
          label: "${weight.toStringAsFixed(1)} kg",
          onChanged: (value) => onChanged(value),
        ),
      ],
    );
  }
}
