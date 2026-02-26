import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/reservation_repository.dart';
import '../domain/reservation.dart';
import '../data/cleaning_repository.dart';
import '../domain/cleaning_assignment.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/user.dart';
import '../../admin/presentation/user_management_screen.dart';
import '../../../core/constants/roles.dart';

class CalendarDashboard extends ConsumerStatefulWidget {
  const CalendarDashboard({super.key});

  @override
  ConsumerState<CalendarDashboard> createState() => _CalendarDashboardState();
}

class _CalendarDashboardState extends ConsumerState<CalendarDashboard> {
  DateTime _selectedDate = DateTime.now();
  bool _isMonthlyView = false;

  @override
  Widget build(BuildContext context) {
    // Reset time to midnight for consistent fetching
    final dateQuery = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    // Note: In build() we now just read auth/role state, data is fetched inside _buildDailyView / _buildMonthlyView
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
                'Today\'s Activities (v7)',
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
              ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(value: false, label: Text('Daily')),
                  ButtonSegment<bool>(value: true, label: Text('Monthly')),
                ],
                selected: {_isMonthlyView},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _isMonthlyView = newSelection.first;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isMonthlyView 
                ? _buildMonthlyView(context, dateQuery, currentUser, canAssign)
                : _buildDailyView(context, dateQuery, currentUser, canAssign),
          )
        ],
      ),
    );
  }

  Widget _buildMonthlyView(BuildContext context, DateTime dateQuery, User? currentUser, bool canAssign) {
    // Generate a 30 day sweeping window starting from the currently selected date
    final endDate = dateQuery.add(const Duration(days: 30));
    final dateRangeAsync = ref.watch(dateRangeReservationsProvider(dateQuery, endDate));

    return dateRangeAsync.when(
      data: (dateMap) {
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 30,
          itemBuilder: (context, index) {
            final columnDate = dateQuery.add(Duration(days: index));
            final columnKey = DateTime(columnDate.year, columnDate.month, columnDate.day);
            final dailyReservations = dateMap[columnKey] ?? [];

            // Apply same RBAC filtering
            var displayList = dailyReservations.where((res) {
              final isCheckIn = res.type == ReservationEventType.checkIn;
              // Cleaning Assignments are omitted from the board view for spacing, but roles apply
              if (currentUser?.role == AppRole.cleaner) {
                if (isCheckIn) return false;
              } else if (currentUser?.role == AppRole.inspector) {
                if (isCheckIn) return false;
              }
              return true;
            }).toList();

            // Re-apply V6 Grouping locally for this specific column
            Map<String, List<Reservation>> propertyGroups = {};
            for (var res in displayList) {
              propertyGroups.putIfAbsent(res.propertyName, () => []).add(res);
            }

            List<List<Reservation>> finalGroups = [];
            for (var group in propertyGroups.values) {
              group.sort((a, b) {
                if (a.type == ReservationEventType.checkOut && b.type == ReservationEventType.checkIn) return -1;
                if (a.type == ReservationEventType.checkIn && b.type == ReservationEventType.checkOut) return 1;
                return 0;
              });
              finalGroups.add(group);
            }

            finalGroups.sort((groupA, groupB) {
              bool hasBothA = groupA.any((r) => r.type == ReservationEventType.checkOut) && groupA.any((r) => r.type == ReservationEventType.checkIn);
              bool hasBothB = groupB.any((r) => r.type == ReservationEventType.checkOut) && groupB.any((r) => r.type == ReservationEventType.checkIn);
              
              int rankA = hasBothA ? 0 : (groupA.first.type == ReservationEventType.checkOut ? 1 : 2);
              int rankB = hasBothB ? 0 : (groupB.first.type == ReservationEventType.checkOut ? 1 : 2);
              
              if (rankA != rankB) return rankA.compareTo(rankB);
              return groupA.first.propertyName.compareTo(groupB.first.propertyName);
            });

            return Container(
              width: 300,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Column Header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat.EEEE().format(columnDate),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13),
                        ),
                        Text(
                          DateFormat.MMMd().format(columnDate),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  // Column Body
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: finalGroups.length,
                      itemBuilder: (context, cardIndex) {
                        final group = finalGroups[cardIndex];
                        
                        Widget buildBoardRow(Reservation res) {
                          final isCheckIn = res.type == ReservationEventType.checkIn;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCheckIn ? Colors.green : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        res.propertyName.split(',').first, // Compact name
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        res.guestName,
                                        style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              buildBoardRow(group[0]),
                              if (group.length > 1) ...[
                                const Divider(height: 1, thickness: 1, color: Colors.black12),
                                buildBoardRow(group[1]),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildDailyView(BuildContext context, DateTime dateQuery, User? currentUser, bool canAssign) {
    final reservationsAsync = ref.watch(dailyReservationsProvider(dateQuery));
    final assignmentsAsync = ref.watch(dailyCleaningAssignmentsProvider(dateQuery));

    return reservationsAsync.when(
      data: (reservations) {
        if (reservations.isEmpty) {
          return const Center(child: Text('No activities for this date.'));
        }
        return assignmentsAsync.when(
          data: (assignments) {
            // Pre-filter the list based on user role to avoid SizedBox.shrink() gaps
            var displayList = reservations.where((res) {
              final isCheckIn = res.type == ReservationEventType.checkIn;
              final assignment = assignments.where((a) => a.reservationId == res.id).firstOrNull;
              
              if (currentUser?.role == AppRole.cleaner) {
                if (isCheckIn) return false; 
                if (assignment == null || assignment.cleanerId != currentUser?.id) return false;
              } else if (currentUser?.role == AppRole.inspector) {
                 if (isCheckIn) return false;
                 if (assignment == null || assignment.inspectorId != currentUser?.id) return false;
              }
              return true;
            }).toList();

            // Group all reservations natively by property name to completely bypass index-parsing bugs
            Map<String, List<Reservation>> propertyGroups = {};
            for (var res in displayList) {
              propertyGroups.putIfAbsent(res.propertyName, () => []).add(res);
            }

            List<List<Reservation>> finalGroups = [];
            for (var group in propertyGroups.values) {
              // Sort inside each property group: Check-out must ALWAYS be element 0, Check-in element 1
              group.sort((a, b) {
                if (a.type == ReservationEventType.checkOut && b.type == ReservationEventType.checkIn) return -1;
                if (a.type == ReservationEventType.checkIn && b.type == ReservationEventType.checkOut) return 1;
                return 0;
              });
              finalGroups.add(group);
            }

            // Sort the grouped properties
            finalGroups.sort((groupA, groupB) {
              bool hasBothA = groupA.any((r) => r.type == ReservationEventType.checkOut) && groupA.any((r) => r.type == ReservationEventType.checkIn);
              bool hasBothB = groupB.any((r) => r.type == ReservationEventType.checkOut) && groupB.any((r) => r.type == ReservationEventType.checkIn);
              
              int rankA = hasBothA ? 0 : (groupA.first.type == ReservationEventType.checkOut ? 1 : 2);
              int rankB = hasBothB ? 0 : (groupB.first.type == ReservationEventType.checkOut ? 1 : 2);
              
              if (rankA != rankB) return rankA.compareTo(rankB);
              
              return groupA.first.propertyName.compareTo(groupB.first.propertyName);
            });

            return ListView.builder(
              itemCount: finalGroups.length,
              itemBuilder: (context, index) {
                final group = finalGroups[index];
                
                // Helper function to build a single reservation row to be placed inside the Card
                Widget buildReservationRow(Reservation res) {
                  final isCheckIn = res.type == ReservationEventType.checkIn;
                  final assignment = assignments.where((a) => a.reservationId == res.id).firstOrNull;
                  return InkWell(
                    onTap: (!isCheckIn && canAssign) ? () => _showCleaningAssignmentDialog(context, ref, res, dateQuery, assignment) : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
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
                  );
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      buildReservationRow(group[0]),
                      if (group.length > 1) ...[
                        const Divider(height: 1, thickness: 1, color: Colors.black12),
                        buildReservationRow(group[1]),
                      ],
                    ],
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
