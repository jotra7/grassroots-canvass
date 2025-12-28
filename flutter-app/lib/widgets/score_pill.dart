import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/platform_utils.dart';

class ScorePill extends StatelessWidget {
  final int score;

  const ScorePill({super.key, required this.score});

  Color get _color {
    if (score >= 8) return Colors.green;
    if (score >= 5) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PlatformUtils.isApple
                ? CupertinoIcons.chart_bar
                : Icons.bar_chart,
            size: 12,
            color: _color,
          ),
          const SizedBox(width: 2),
          Text(
            score.toString(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
