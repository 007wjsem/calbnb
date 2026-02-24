import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../calendar/data/cleaning_repository.dart';
import '../../calendar/domain/cleaning_assignment.dart';
import '../../auth/data/auth_repository.dart';
import '../../admin/presentation/property_management_screen.dart';
import '../../admin/domain/property.dart';
import 'package:intl/intl.dart';

class CleanerEarningsView extends ConsumerWidget {
  const CleanerEarningsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(allCleaningAssignmentsProvider);
    final propertiesAsync = ref.watch(propertyRepositoryProvider);
    final currentUser = ref.watch(authControllerProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'My Earnings',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0D2E63)
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: assignmentsAsync.when(
              data: (assignments) {
                return FutureBuilder<List<Property>>(
                  future: propertiesAsync.fetchAll(),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Error loading properties: ${snap.error}'));
                    }

                    final properties = snap.data ?? [];
                    
                    // Filter exclusively for the current user's completed/approved jobs
                    final myCompletedJobs = assignments.where((a) =>
                        a.cleanerId == currentUser?.id && a.status == CleaningStatus.approved).toList();

                    // Calculate the start and end of the current week (Monday-Sunday)
                    final now = DateTime.now();
                    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
                    final currentWeekStartMidnight = DateTime(currentWeekStart.year, currentWeekStart.month, currentWeekStart.day);
                    
                    final currentWeekEnd = currentWeekStartMidnight.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
                    
                    // Previous week boundaries
                    final previousWeekStart = currentWeekStartMidnight.subtract(const Duration(days: 7));
                    final previousWeekEnd = currentWeekStartMidnight.subtract(const Duration(seconds: 1));

                    // Filter jobs into current vs previous week
                    final currentWeekJobs = <CleaningAssignment>[];
                    final previousWeekJobs = <CleaningAssignment>[];

                    for (var job in myCompletedJobs) {
                      final jobDate = DateTime.parse(job.date);
                      if (jobDate.isAfter(currentWeekStartMidnight.subtract(const Duration(seconds: 1))) && 
                          jobDate.isBefore(currentWeekEnd.add(const Duration(seconds: 1)))) {
                        currentWeekJobs.add(job);
                      } else if (jobDate.isAfter(previousWeekStart.subtract(const Duration(seconds: 1))) && 
                                 jobDate.isBefore(previousWeekEnd.add(const Duration(seconds: 1)))) {
                        previousWeekJobs.add(job);
                      }
                    }

                    // Sort jobs by date descending (newest first)
                    currentWeekJobs.sort((a, b) => b.date.compareTo(a.date));

                    // Calculate totals
                    double currentWeekTotal = 0;
                    double previousWeekTotal = 0;

                    for (var job in currentWeekJobs) {
                       final property = properties.where((p) => p.name == job.propertyId).firstOrNull;
                       if (property != null) {
                          currentWeekTotal += property.cleaningFee;
                       }
                    }

                    for (var job in previousWeekJobs) {
                       final property = properties.where((p) => p.name == job.propertyId).firstOrNull;
                       if (property != null) {
                          previousWeekTotal += property.cleaningFee;
                       }
                    }

                    final difference = currentWeekTotal - previousWeekTotal;
                    final isPositive = difference >= 0;

                    return Column(
                      children: [
                        // Totals Summary Cards
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryCard(
                                title: 'This Week',
                                amount: currentWeekTotal,
                                subtitle: '${currentWeekJobs.length} properties cleaned',
                                icon: Icons.attach_money,
                                color: Colors.green.shade600,
                                isPrimary: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _SummaryCard(
                                title: 'Last Week',
                                amount: previousWeekTotal,
                                subtitle: '${previousWeekJobs.length} properties cleaned',
                                icon: Icons.history,
                                color: Colors.blueGrey,
                                isPrimary: false,
                              ),
                            ),
                          ],
                        ),
                        
                        // Trending Indicator
                        if (previousWeekTotal > 0 || currentWeekTotal > 0) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isPositive ? Icons.trending_up : Icons.trending_down,
                                color: isPositive ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${isPositive ? "+" : ""}\$${difference.toStringAsFixed(2)} compared to last week',
                                style: TextStyle(
                                  color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                                  fontWeight: FontWeight.bold
                                ),
                              )
                            ],
                          ),
                        ],

                        const SizedBox(height: 32),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'This Week\'s Details',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Detail List
                        Expanded(
                          child: currentWeekJobs.isEmpty 
                              ? const Center(child: Text('No completed cleanings this week.', style: TextStyle(color: Colors.grey, fontSize: 16)))
                              : ListView.builder(
                                  itemCount: currentWeekJobs.length,
                                  itemBuilder: (context, index) {
                                    final job = currentWeekJobs[index];
                                    final property = properties.where((p) => p.name == job.propertyId).firstOrNull;
                                    final earning = property?.cleaningFee ?? 0.0;

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.green.shade50,
                                          child: Icon(Icons.check_circle, color: Colors.green.shade600),
                                        ),
                                        title: Text(job.propertyId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        subtitle: Text(DateFormat.yMMMEd().format(DateTime.parse(job.date))),
                                        trailing: Text(
                                          '\$${earning.toStringAsFixed(2)}',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700, fontSize: 18),
                                        ),
                                      ),
                                    );
                                  },
                                )
                        )
                      ],
                    );
                  }
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          )
        ]
      )
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isPrimary;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPrimary ? color.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPrimary ? color.withOpacity(0.3) : Colors.grey.shade300, width: 2),
        boxShadow: [
          if (!isPrimary) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 16, fontWeight: FontWeight.bold)),
              Icon(icon, color: color, size: 28),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: color, letterSpacing: -1),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
