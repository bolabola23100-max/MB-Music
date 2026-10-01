import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';

/// Grid of play count statistics.
class StatsGridDisplay extends StatelessWidget {
  final int today, weekly, monthly, yearly;

  const StatsGridDisplay({
    super.key,
    required this.today,
    required this.weekly,
    required this.monthly,
    required this.yearly,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 18,
      mainAxisSpacing: 18,
      childAspectRatio: 1.15,
      children: [
        _StatItemCard(label: 'TODAY PLAYS', value: _format(today)),
        _StatItemCard(label: 'WEEKLY PLAYS', value: _format(weekly)),
        _StatItemCard(label: 'MONTHLY PLAYS', value: _format(monthly)),
        _StatItemCard(label: 'YEARLY PLAYS', value: _format(yearly)),
      ],
    );
  }

  String _format(int val) => val >= 1000 ? '${(val / 1000).toStringAsFixed(1)}k' : val.toString();
}

/// Individual card for a stat item.
class _StatItemCard extends StatelessWidget {
  final String label, value;

  const _StatItemCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A34D1), Color(0xFF15B2E6)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.75),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
