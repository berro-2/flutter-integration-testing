import 'package:flutter/material.dart';

class StatisticsScreen extends StatelessWidget {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;

  const StatisticsScreen({
    super.key,
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
  });

  @override
  Widget build(BuildContext context) {
    final completionRate =
        totalTasks == 0 ? 0.0 : completedTasks / totalTasks.toDouble();

    return Scaffold(
      key: const Key('statistics_screen'),
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.analytics_outlined,
                      key: Key('statistics_icon'),
                      size: 70,
                      color: Color(0xFF6C63FF),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Progress Overview',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: completionRate,
                        minHeight: 12,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF00BFA6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${(completionRate * 100).round()}% completed',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              _StatisticsTile(
                title: 'Total Tasks',
                value: '$totalTasks',
                keyValue: 'statistics_total_tasks',
                icon: Icons.list_alt,
                color: const Color(0xFF6C63FF),
              ),

              const SizedBox(height: 12),

              _StatisticsTile(
                title: 'Completed Tasks',
                value: '$completedTasks',
                keyValue: 'statistics_completed_tasks',
                icon: Icons.check_circle,
                color: const Color(0xFF00BFA6),
              ),

              const SizedBox(height: 12),

              _StatisticsTile(
                title: 'Pending Tasks',
                value: '$pendingTasks',
                keyValue: 'statistics_pending_tasks',
                icon: Icons.pending_actions,
                color: const Color(0xFFFF9800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatisticsTile extends StatelessWidget {
  final String title;
  final String value;
  final String keyValue;
  final IconData icon;
  final Color color;

  const _StatisticsTile({
    required this.title,
    required this.value,
    required this.keyValue,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            key: Key(keyValue),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}