import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../admin/presentation/property_management_screen.dart';
import '../../admin/presentation/user_management_screen.dart';
import '../../calendar/data/cleaning_repository.dart';
import '../../calendar/domain/cleaning_assignment.dart';
import '../../../core/constants/roles.dart';
import 'package:firebase_database/firebase_database.dart';

class PayrollScreen extends ConsumerStatefulWidget {
  const PayrollScreen({super.key});

  @override
  ConsumerState<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends ConsumerState<PayrollScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    // Determine the start and end of the week based on selectedDate
    // Let's assume a week is Monday - Sunday
    int diffToMonday = _selectedDate.weekday - DateTime.monday;
    final startOfWeek = _selectedDate.subtract(Duration(days: diffToMonday));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    final startStr = DateFormat('MMM d').format(startOfWeek);
    final endStr = DateFormat('MMM d, yyyy').format(endOfWeek);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                Text(
                  'Weekly Earnings',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                        });
                      },
                    ),
                    Text(
                      '$startStr - $endStr',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.add(const Duration(days: 7));
                        });
                      },
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _fetchPayrollData(startOfWeek, endOfWeek),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final data = snapshot.data ?? {};
                  final properties = data['properties'] as Map<String, double>; // Name -> Fee
                  final assignments = data['assignments'] as List<CleaningAssignment>;
                  final cleaners = data['cleaners'] as Map<String, String>; // Id -> Name

                  // Calculate earnings
                  // cleanerId -> double (sum of fees)
                  Map<String, double> earnings = {};
                  // cleanerId -> List of jobs
                  Map<String, List<CleaningAssignment>> jobs = {};

                  for (final assign in assignments) {
                    // if (assign.status != CleaningStatus.approved) continue; // Note: Only calc approved if required.
                    final fee = properties[assign.propertyId] ?? 0.0;
                    earnings[assign.cleanerId] = (earnings[assign.cleanerId] ?? 0) + fee;
                    
                    if (jobs[assign.cleanerId] == null) {
                      jobs[assign.cleanerId] = [];
                    }
                    jobs[assign.cleanerId]!.add(assign);
                  }

                  if (earnings.isEmpty) {
                    return const Center(child: Text('No approved cleaning jobs for this week.'));
                  }

                  final sortedCleaners = earnings.keys.toList()..sort((a, b) => (cleaners[a] ?? a).compareTo(cleaners[b] ?? b));

                  return ListView.builder(
                    itemCount: sortedCleaners.length,
                    itemBuilder: (context, index) {
                      final cId = sortedCleaners[index];
                      final cName = cleaners[cId] ?? 'Unknown Cleaner';
                      final total = earnings[cId] ?? 0.0;
                      final cJobs = jobs[cId] ?? [];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF16A34A).withOpacity(0.1),
                            child: const Icon(Icons.payments_outlined, color: Color(0xFF16A34A)),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(cName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF16A34A))),
                            ]
                          ),
                          subtitle: Text('${cJobs.length} jobs completed'),
                          children: cJobs.map((job) {
                            final fee = properties[job.propertyId] ?? 0.0;
                            return ListTile(
                              title: Text(job.propertyId),
                              subtitle: Text(job.date),
                              trailing: Text('\$${fee.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            );
                          }).toList(),
                        )
                      );
                    }
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchPayrollData(DateTime start, DateTime end) async {
    final repoProps = ref.read(propertyRepositoryProvider);
    final repoUsers = ref.read(userRepositoryProvider);
    
    // Fetch properties to get fees (mapping property Name to Fee)
    final props = await repoProps.fetchAll();
    final propFees = { for (var p in props) p.name : p.cleaningFee };
    
    // Fetch users to get cleaner names
    final users = await repoUsers.fetchAll();
    final userNames = { for (var u in users) u.id : u.username };

    // Fetch assignments across all days in the week
    List<CleaningAssignment> weekAssignments = [];
    final dbRef = FirebaseDatabase.instance.ref('cleaning_assignments');
    
    // Naive fetch for all 7 days
    for (int i = 0; i < 7; i++) {
       final day = start.add(Duration(days: i));
       final dayStr = DateFormat('yyyy-MM-dd').format(day);
       
       final snap = await dbRef.child(dayStr).get();
       if (snap.exists && snap.value != null) {
         final map = snap.value as Map<dynamic, dynamic>;
         map.forEach((k, v) {
            final assign = CleaningAssignment.fromMap(k.toString(), v as Map<dynamic, dynamic>);
            if (assign.status == CleaningStatus.approved) {
              weekAssignments.add(assign);
            }
         });
       }
    }
    
    return {
      'properties': propFees,
      'assignments': weekAssignments,
      'cleaners': userNames,
    };
  }
}
