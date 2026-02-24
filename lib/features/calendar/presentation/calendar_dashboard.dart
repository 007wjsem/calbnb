import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/reservation_repository.dart';
import '../domain/reservation.dart';
import '../data/cleaning_repository.dart';
import '../domain/cleaning_assignment.dart';
import '../../auth/data/auth_repository.dart';
import '../../admin/presentation/user_management_screen.dart';
import '../../../core/constants/roles.dart';

class CalendarDashboard extends ConsumerStatefulWidget {
  const CalendarDashboard({super.key});

  @override
  ConsumerState<CalendarDashboard> createState() => _CalendarDashboardState();
}

class _CalendarDashboardState extends ConsumerState<CalendarDashboard> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    // Reset time to midnight for consistent fetching
    final dateQuery = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final reservationsAsync = ref.watch(dailyReservationsProvider(dateQuery));
    final assignmentsAsync = ref.watch(dailyCleaningAssignmentsProvider(dateQuery));
    final currentUser = ref.watch(authControllerProvider);
    final canAssign = currentUser?.role.displayName == 'Super Admin' || currentUser?.role.displayName == 'Administrator';

    return Padding(
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
                'Today\'s Activities',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                      });
                    },
                  ),
                  Text(
                    DateFormat.yMMMd().format(_selectedDate),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: (currentUser?.role.displayName != 'Super Admin' && currentUser?.role.displayName != 'Administrator' && currentUser?.role.displayName != 'Manager' && _selectedDate.isAfter(DateTime.now().subtract(const Duration(days: 1))))
                    ? null
                    : () {
                        setState(() {
                          _selectedDate = _selectedDate.add(const Duration(days: 1));
                        });
                      },
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: reservationsAsync.when(
              data: (reservations) {
                if (reservations.isEmpty) {
                  return const Center(child: Text('No activities for this date.'));
                }
                return assignmentsAsync.when(
                  data: (assignments) {
                    return ListView.builder(
                      itemCount: reservations.length,
                      itemBuilder: (context, index) {
                        final res = reservations[index];
                        final isCheckIn = res.type == ReservationEventType.checkIn;
                        final assignment = assignments.where((a) => a.reservationId == res.id).firstOrNull;
                        
                        // Filtering logic for Cleaner/Inspector on Calendar View
                        if (currentUser?.role == AppRole.cleaner) {
                          if (isCheckIn) return const SizedBox.shrink(); 
                          if (assignment == null || assignment.cleanerId != currentUser?.id) return const SizedBox.shrink();
                        } else if (currentUser?.role == AppRole.inspector) {
                           if (isCheckIn) return const SizedBox.shrink();
                           if (assignment == null || assignment.inspectorId != currentUser?.id) return const SizedBox.shrink();
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: (!isCheckIn && canAssign) ? () => _showCleaningAssignmentDialog(context, ref, res, dateQuery, assignment) : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isCheckIn ? Colors.green.shade100 : Colors.red.shade100,
                                  child: Icon(
                                    isCheckIn ? Icons.login : Icons.logout,
                                    color: isCheckIn ? Colors.green : Colors.red,
                                  ),
                                ),
                                title: Text(res.guestName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(res.propertyName),
                                    if (!isCheckIn && assignment != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.cleaning_services, size: 14, color: Colors.blueGrey),
                                          const SizedBox(width: 4),
                                          Text('Cleaner: ${assignment.cleanerName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                          if (assignment.inspectorName != null) ...[
                                            const SizedBox(width: 8),
                                            const Icon(Icons.verified_user, size: 14, color: Colors.blueGrey),
                                            const SizedBox(width: 4),
                                            Text('Inspector: ${assignment.inspectorName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                          ]
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.info_outline, size: 14, color: Colors.blueGrey),
                                          const SizedBox(width: 4),
                                          Text('Status: ${assignment.status.name}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isCheckIn ? Colors.green : Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isCheckIn ? 'CHECK-IN' : 'CHECK-OUT',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => const Center(child: Text('Failed to load assignments')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          )
        ],
      ),
    );
  }

  void _showCleaningAssignmentDialog(BuildContext context, WidgetRef ref, Reservation reservation, DateTime date, CleaningAssignment? existingAssignment) async {
    final userRepository = ref.read(userRepositoryProvider);
    final cleaningRepository = ref.read(cleaningRepositoryProvider);
    
    // Fetch users to find cleaners and inspectors
    final allUsers = await userRepository.fetchAll();
    final cleaners = allUsers.where((u) => u.role == AppRole.cleaner).toList();
    final inspectors = allUsers.where((u) => u.role == AppRole.inspector).toList();
    
    if (!context.mounted) return;
    
    if (cleaners.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No cleaners found to assign.')));
      return;
    }

    String? selectedCleanerId = existingAssignment?.cleanerId;
    String? selectedInspectorId = existingAssignment?.inspectorId;
    final observationController = TextEditingController(text: existingAssignment?.observation ?? '');
    final dateStr = defaultDateFormatter.format(date);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Assign Cleaning Task',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.house_outlined, color: Colors.blue.shade900, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              reservation.propertyName,
                              style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: selectedCleanerId,
                      decoration: InputDecoration(
                        labelText: 'Select Cleaner',
                        prefixIcon: const Icon(Icons.cleaning_services_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.withValues(alpha: 0.05),
                      ),
                      items: cleaners.map((emp) {
                        return DropdownMenuItem(value: emp.id, child: Text(emp.username));
                      }).toList(),
                      onChanged: (val) {
                        setState(() => selectedCleanerId = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedInspectorId,
                      decoration: InputDecoration(
                        labelText: 'Select Inspector (Optional)',
                        prefixIcon: const Icon(Icons.fact_check_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.withValues(alpha: 0.05),
                      ),
                      items: inspectors.map((insp) {
                        return DropdownMenuItem(value: insp.id, child: Text(insp.username));
                      }).toList(),
                      onChanged: (val) {
                        setState(() => selectedInspectorId = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: observationController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Observations / Notes',
                        alignLabelWithHint: true,
                        prefixIcon: const Icon(Icons.edit_note_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.withValues(alpha: 0.05),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (existingAssignment != null) ...[
                          TextButton.icon(
                            onPressed: () async {
                              await cleaningRepository.deleteAssignment(dateStr, reservation.id);
                              if (context.mounted) Navigator.pop(context);
                            },
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                            label: const Text('Remove', style: TextStyle(color: Colors.red)),
                          ),
                          const Spacer(),
                        ],
                        if (existingAssignment == null) const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            if (selectedCleanerId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a cleaner')));
                              return;
                            }
                            final cleanerName = cleaners.firstWhere((c) => c.id == selectedCleanerId).username;
                            final inspectorName = selectedInspectorId != null ? inspectors.firstWhere((i) => i.id == selectedInspectorId).username : null;

                            final assignment = CleaningAssignment(
                              id: existingAssignment?.id ?? '',
                              reservationId: reservation.id,
                              propertyId: reservation.propertyName,
                              cleanerId: selectedCleanerId!,
                              cleanerName: cleanerName,
                              inspectorId: selectedInspectorId,
                              inspectorName: inspectorName,
                              date: dateStr,
                              assignedAt: existingAssignment?.assignedAt ?? DateTime.now().toIso8601String(),
                              observation: observationController.text.trim(),
                              status: existingAssignment?.status ?? CleaningStatus.assigned,
                              startTime: existingAssignment?.startTime ?? '',
                              endTime: existingAssignment?.endTime ?? '',
                              incidents: existingAssignment?.incidents ?? [],
                              findings: existingAssignment?.findings ?? [],
                            );
                            await cleaningRepository.saveAssignment(assignment);
                            if (context.mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Save Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
