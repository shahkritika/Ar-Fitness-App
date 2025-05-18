import 'package:flutter/material.dart';

class HeightSlide extends StatelessWidget {
  final double height;
  final ValueChanged<double> onChanged;

  const HeightSlide({Key? key, required this.height, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Height: ${height.toStringAsFixed(1)} cm", style: TextStyle(fontSize: 18)),
        Slider(
          value: height,
          min: 100,
          max: 250,
          divisions: 150,
          label: "${height.toStringAsFixed(1)} cm",
          onChanged: (value) => onChanged(value),
        ),
      ],
    );
  }
}
