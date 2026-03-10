import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../calendar/data/cleaning_repository.dart';
import '../../calendar/domain/cleaning_assignment.dart';
import '../../../core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class MetricsScreen extends ConsumerWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(allCleaningAssignmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cleaning Metrics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: assignmentsAsync.when(
        data: (assignments) {
          final now = DateTime.now();
          
          // Helper to get Monday of the week
          DateTime getMonday(DateTime date) {
            return date.subtract(Duration(days: date.weekday - 1));
          }

          final thisMonday = getMonday(now);
          final lastMonday = thisMonday.subtract(const Duration(days: 7));
          
          final DateFormat df = DateFormat('yyyy-MM-dd');
          
          bool isThisWeek(String dateStr) {
            final date = df.parse(dateStr);
            return (date.isAtSameMomentAs(thisMonday) || date.isAfter(thisMonday)) && 
                   date.isBefore(thisMonday.add(const Duration(days: 7)));
          }

          bool isLastWeek(String dateStr) {
            final date = df.parse(dateStr);
            return (date.isAtSameMomentAs(lastMonday) || date.isAfter(lastMonday)) && 
                   date.isBefore(thisMonday);
          }

          final Map<String, int> thisWeekCounts = {};
          final Map<String, int> lastWeekCounts = {};
          final Set<String> cleanerNames = {};

          for (final a in assignments) {
            if (a.status != CleaningStatus.approved) continue;
            
            cleanerNames.add(a.cleanerName);
            
            if (isThisWeek(a.date)) {
              thisWeekCounts[a.cleanerName] = (thisWeekCounts[a.cleanerName] ?? 0) + 1;
            } else if (isLastWeek(a.date)) {
              lastWeekCounts[a.cleanerName] = (lastWeekCounts[a.cleanerName] ?? 0) + 1;
            }
          }

          final sortedCleaners = cleanerNames.toList()..sort();

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryCards(thisWeekCounts, lastWeekCounts),
                const SizedBox(height: 32),
                Text(
                  'Performance by Cleaner',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: sortedCleaners.length,
                    itemBuilder: (context, index) {
                      final name = sortedCleaners[index];
                      final thisCount = thisWeekCounts[name] ?? 0;
                      final lastCount = lastWeekCounts[name] ?? 0;
                      
                      return _buildCleanerRow(context, name, thisCount, lastCount);
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, int> thisWeek, Map<String, int> lastWeek) {
    final totalThis = thisWeek.values.fold(0, (a, b) => a + b);
    final totalLast = lastWeek.values.fold(0, (a, b) => a + b);

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Last Week',
            value: totalLast.toString(),
            subtitle: 'Total Cleanings',
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'This Week',
            value: totalThis.toString(),
            subtitle: 'Total Cleanings',
            color: AppColors.teal,
          ),
        ),
      ],
    );
  }

  Widget _buildCleanerRow(BuildContext context, String name, int thisCount, int lastCount) {
    final bool isUp = thisCount > lastCount;
    final bool isDown = thisCount < lastCount;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.tealLight,
              child: Text(name.substring(0, 1).toUpperCase(), style: const TextStyle(color: AppColors.primaryDark)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('$lastCount last week', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(thisCount.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isUp) const Icon(Icons.arrow_upward, color: Colors.green, size: 14),
                    if (isDown) const Icon(Icons.arrow_downward, color: Colors.red, size: 14),
                    Text(
                      isUp ? 'Increased' : (isDown ? 'Decreased' : 'Same'),
                      style: TextStyle(
                        color: isUp ? Colors.green : (isDown ? Colors.red : Colors.grey),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 28)),
          Text(subtitle, style: TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
        ],
      ),
    );
  }
}
