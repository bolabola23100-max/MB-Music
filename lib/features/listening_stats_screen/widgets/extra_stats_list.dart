import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';

/// List of additional stats tiles.
class ExtraStatsList extends StatelessWidget {
  final int totalTime;

  const ExtraStatsList({super.key, required this.totalTime});

  @override
  Widget build(BuildContext context) {
    final formattedTime = totalTime >= 1000 ? '${(totalTime / 1000).toStringAsFixed(1)}k' : totalTime.toString();

    return Column(
      children: [
        const _StatTileRow(
          icon: Icons.auto_graph_rounded,
          title: 'Top 1%',
          subtitle: 'GLOBAL LISTENERS RANK',
        ),
        const SizedBox(height: 18),
        _StatTileRow(
          icon: Icons.timer_outlined,
          title: '$formattedTime min',
          subtitle: 'TOTAL TIME STREAMED',
        ),
      ],
    );
  }
}

/// Individual tile for extra stats.
class _StatTileRow extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;

  const _StatTileRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF2A2A2A),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.blue, size: 22),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
