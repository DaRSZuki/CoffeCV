import 'package:flutter/material.dart';

/// Indicador de 5 segmentos para mostrar qué tan común es una enfermedad.
class FrequencyMeter extends StatelessWidget {
  final int level;
  final String label;
  const FrequencyMeter({super.key, required this.level, required this.label});

  @override
  Widget build(BuildContext context) {
    final active = Color.lerp(Colors.amber.shade700, Colors.red.shade700, (level - 1) / 4)!;
    return Row(
      children: [
        for (var i = 1; i <= 5; i++)
          Container(
            width: 18,
            height: 6,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: i <= level ? active : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
