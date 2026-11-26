import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class LatencyBadge extends StatelessWidget {
  const LatencyBadge({super.key, required this.latencyMs});

  final int latencyMs;

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (latencyMs <= 60) {
      color = const Color(0xFF10D978);
    } else if (latencyMs <= 140) {
      color = const Color(0xFFF59E0B);
    } else {
      color = const Color(0xFFEF4444);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            Formatters.latency(latencyMs),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
