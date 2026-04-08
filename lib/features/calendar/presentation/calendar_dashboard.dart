import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../data/reservation_repository.dart';
import '../domain/reservation.dart';
import '../data/cleaning_repository.dart';
import '../domain/cleaning_assignment.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/user.dart';
import '../../admin/presentation/user_management_screen.dart';
import '../../admin/data/property_repository.dart';
import '../../../core/constants/roles.dart';
import '../../../core/data/server_time_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../company/presentation/currency_provider.dart';
import '../../company/data/company_repository.dart';
import '../../company/domain/subscription.dart';
import 'package:calbnb/l10n/app_localizations.dart';

enum CalendarViewType { daily, board, timeline }

class CalendarDashboard extends ConsumerStatefulWidget {
  const CalendarDashboard({super.key});

  @override
  ConsumerState<CalendarDashboard> createState() => _CalendarDashboardState();
}

class _CalendarDashboardState extends ConsumerState<CalendarDashboard> {
  DateTime? _selectedDate;
  CalendarViewType _viewType = CalendarViewType.daily;

  // Controllers for synchronized scrolling in Timeline view
  late ScrollController _timelineHorizontalHeaderController;
  late ScrollController _timelineHorizontalGridController;
  late ScrollController _timelineVerticalLabelController;
  late ScrollController _timelineVerticalGridController;

  @override
  void initState() {
    super.initState();
    _timelineHorizontalHeaderController = ScrollController();
    _timelineHorizontalGridController = ScrollController();
    _timelineVerticalLabelController = ScrollController();
    _timelineVerticalGridController = ScrollController();

    // Link horizontal controllers
    _timelineHorizontalHeaderController.addListener(() {
      if (_timelineHorizontalHeaderController.offset != _timelineHorizontalGridController.offset) {
        _timelineHorizontalGridController.jumpTo(_timelineHorizontalHeaderController.offset);
      }
    });
    _timelineHorizontalGridController.addListener(() {
      if (_timelineHorizontalGridController.offset != _timelineHorizontalHeaderController.offset) {
        _timelineHorizontalHeaderController.jumpTo(_timelineHorizontalGridController.offset);
      }
    });

    // Link vertical controllers
    _timelineVerticalLabelController.addListener(() {
      if (_timelineVerticalLabelController.offset != _timelineVerticalGridController.offset) {
        _timelineVerticalGridController.jumpTo(_timelineVerticalLabelController.offset);
      }
    });
    _timelineVerticalGridController.addListener(() {
      if (_timelineVerticalGridController.offset != _timelineVerticalLabelController.offset) {
        _timelineVerticalLabelController.jumpTo(_timelineVerticalGridController.offset);
      }
    });

    // Initialize date from server time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final serverTime = ref.read(currentServerTimeProvider);
      setState(() {
        _selectedDate = serverTime;
      });
    });
  }

  @override
  void dispose() {
    _timelineHorizontalHeaderController.dispose();
    _timelineHorizontalGridController.dispose();
    _timelineVerticalLabelController.dispose();
    _timelineVerticalGridController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedDate == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    final serverTime = ref.watch(currentServerTimeProvider);
    final dateQuery = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
    final currentUser = ref.watch(authControllerProvider);
    final canAssign = currentUser?.role.displayName == 'Super Admin' ||
        currentUser?.role.displayName == 'Administrator' ||
        currentUser?.role.displayName == 'Manager';
    final isMobile = MediaQuery.of(context).size.width < 600;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: isMobile ? WrapAlignment.center : WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: isMobile ? 16 : 8,
            children: [
              SizedBox(
                width: isMobile ? double.infinity : null,
                child: Text(
                  l10n.todaysActivities,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: isMobile ? TextAlign.center : TextAlign.start,
                ),
              ),
              SizedBox(
                width: isMobile ? double.infinity : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate!.subtract(const Duration(days: 1));
                        });
                      },
                    ),
                    Text(
                      DateFormat.yMMMd().format(_selectedDate!),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: (currentUser?.role.displayName != 'Super Admin' &&
                              currentUser?.role.displayName != 'Administrator' &&
                              currentUser?.role.displayName != 'Manager' &&
                              _selectedDate!.isAfter(serverTime.subtract(const Duration(days: 1))))
                          ? null
                          : () {
                              setState(() {
                                _selectedDate = _selectedDate!.add(const Duration(days: 1));
                              });
                            },
                    ),
                  ],
                ),
              ),
              SegmentedButton<CalendarViewType>(
                segments: const [
                  ButtonSegment<CalendarViewType>(
                      value: CalendarViewType.daily,
                      label: FittedBox(fit: BoxFit.scaleDown, child: Text('Daily')),
                      icon: Icon(Icons.list)),
                  ButtonSegment<CalendarViewType>(
                      value: CalendarViewType.board,
                      label: FittedBox(fit: BoxFit.scaleDown, child: Text('Board')),
                      icon: Icon(Icons.dashboard)),
                  ButtonSegment<CalendarViewType>(
                      value: CalendarViewType.timeline,
                      label: FittedBox(fit: BoxFit.scaleDown, child: Text('Timeline')),
                      icon: Icon(Icons.timeline)),
                ],
                selected: {_viewType},
                onSelectionChanged: (Set<CalendarViewType> newSelection) {
                  setState(() {
                    _viewType = newSelection.first;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _viewType == CalendarViewType.timeline
                ? _buildTimelineView(context, dateQuery, currentUser, canAssign, serverTime)
                : _viewType == CalendarViewType.board
                    ? _buildBoardView(context, dateQuery, currentUser, canAssign)
                    : _buildDailyView(context, dateQuery, currentUser, canAssign),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DAILY VIEW
  // ─────────────────────────────────────────────────────────────
  Widget _buildDailyView(BuildContext context, DateTime dateQuery, User? currentUser, bool canAssign) {
    final l10n = AppLocalizations.of(context)!;
    final reservationsAsync = ref.watch(dailyReservationsProvider(dateQuery));
    final assignmentsAsync = ref.watch(dailyCleaningAssignmentsProvider(dateQuery));

    return reservationsAsync.when(
      data: (reservations) {
        if (reservations.isEmpty) {
          return Center(child: Text(l10n.noActivities));
        }
        return assignmentsAsync.when(
          data: (assignments) {
            // Pre-filter based on role to avoid SizedBox.shrink() gaps
            var displayList = reservations.where((res) {
              final isCheckIn = res.type == ReservationEventType.checkIn;
              final assignment = assignments.where((a) => a.reservationId == res.id).firstOrNull;
              if (currentUser?.role == AppRole.cleaner) {
                if (isCheckIn) return false;
                if (assignment == null || !assignment.cleaners.any((c) => c.id == currentUser?.id)) return false;
              } else if (currentUser?.role == AppRole.inspector) {
                if (isCheckIn) return false;
                if (assignment == null || assignment.inspectorId != currentUser?.id) return false;
              }
              return true;
            }).toList();

            // Group by property
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
              bool hasBothA = groupA.any((r) => r.type == ReservationEventType.checkOut) &&
                  groupA.any((r) => r.type == ReservationEventType.checkIn);
              bool hasBothB = groupB.any((r) => r.type == ReservationEventType.checkOut) &&
                  groupB.any((r) => r.type == ReservationEventType.checkIn);
              int rankA = hasBothA ? 0 : (groupA.first.type == ReservationEventType.checkOut ? 1 : 2);
              int rankB = hasBothB ? 0 : (groupB.first.type == ReservationEventType.checkOut ? 1 : 2);
              if (rankA != rankB) return rankA.compareTo(rankB);
              return groupA.first.propertyName.compareTo(groupB.first.propertyName);
            });

            if (finalGroups.isEmpty) {
              return Center(child: Text(l10n.noActivities));
            }

            return ListView.builder(
              itemCount: finalGroups.length,
              itemBuilder: (context, index) {
                final group = finalGroups[index];

                Widget buildReservationRow(Reservation res) {
                  final isCheckIn = res.type == ReservationEventType.checkIn;
                  final assignment = assignments.where((a) => a.reservationId == res.id).firstOrNull;
                  return InkWell(
                    onTap: (!isCheckIn && canAssign)
                        ? () => _showCleaningAssignmentDialog(context, ref, res, dateQuery, assignment)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                      child: Row(
                        children: [
                          // Leading Icon
                          CircleAvatar(
                            backgroundColor: isCheckIn ? Colors.green.shade100 : Colors.red.shade100,
                            radius: 20,
                            child: Icon(
                              isCheckIn ? Icons.login : Icons.logout,
                              color: isCheckIn ? Colors.green : Colors.red,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Middle Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  res.guestName == 'Reserved' ? l10n.reservedLabel : res.guestName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  res.propertyName,
                                  style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (!isCheckIn && assignment != null) ...[
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.cleaning_services, size: 14, color: Colors.blueGrey),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              l10n.cleanerLabel(assignment.cleaners.map((c) => c.name).join(', ')),
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (assignment.inspectorName != null) ...[
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.verified_user, size: 14, color: Colors.blueGrey),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                l10n.inspectorLabel(assignment.inspectorName!),
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.info_outline, size: 14, color: Colors.blueGrey),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          '${l10n.statusLabel}: ${assignment.status.localizedName(l10n)}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Trailing Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isCheckIn ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isCheckIn ? l10n.checkInBadge : l10n.checkOutBadge,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
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
                      for (int i = 0; i < group.length; i++) ...[
                        buildReservationRow(group[i]),
                        if (i < group.length - 1)
                          const Divider(height: 1, thickness: 1, color: Colors.black12),
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

  // ─────────────────────────────────────────────────────────────
  // BOARD VIEW (Kanban columns by day)
  // ─────────────────────────────────────────────────────────────
  Widget _buildBoardView(BuildContext context, DateTime dateQuery, User? currentUser, bool canAssign) {
    final l10n = AppLocalizations.of(context)!;
    final endDate = dateQuery.add(const Duration(days: 30));
    final dateRangeAsync = ref.watch(dateRangeReservationsProvider(dateQuery, endDate));
    final assignmentsAsync = ref.watch(dateRangeCleaningAssignmentsProvider((dateQuery, endDate)));

    return dateRangeAsync.when(
      data: (dateMap) {
        return assignmentsAsync.when(
          data: (assignments) {
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 30,
              itemBuilder: (context, index) {
                final columnDate = dateQuery.add(Duration(days: index));
                final columnKey = DateTime(columnDate.year, columnDate.month, columnDate.day);
                final dailyReservations = dateMap[columnKey] ?? [];

                // RBAC filtering
                var displayList = dailyReservations.where((res) {
                  final isCheckIn = res.type == ReservationEventType.checkIn;
                  final assignment = assignments.where((a) => a.reservationId == res.id).firstOrNull;
                  if (currentUser?.role == AppRole.cleaner) {
                    if (isCheckIn) return false;
                    if (assignment == null || !assignment.cleaners.any((c) => c.id == currentUser?.id)) return false;
                  } else if (currentUser?.role == AppRole.inspector) {
                    if (isCheckIn) return false;
                    if (assignment == null || assignment.inspectorId != currentUser?.id) return false;
                  }
                  return true;
                }).toList();

                // Group by property
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
                  bool hasBothA = groupA.any((r) => r.type == ReservationEventType.checkOut) &&
                      groupA.any((r) => r.type == ReservationEventType.checkIn);
                  bool hasBothB = groupB.any((r) => r.type == ReservationEventType.checkOut) &&
                      groupB.any((r) => r.type == ReservationEventType.checkIn);
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
                              final assignment = assignments.where((a) => a.reservationId == res.id).firstOrNull;
                              return InkWell(
                                onTap: (!isCheckIn && canAssign)
                                    ? () => _showCleaningAssignmentDialog(context, ref, res, columnDate, assignment)
                                    : null,
                                child: Padding(
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
                                              res.propertyName.split(',').first,
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
                                            if (!isCheckIn && assignment != null) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.cleaning_services, size: 12, color: Colors.blueGrey),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      '${assignment.cleaners.map((c) => c.name).join(', ')} (${assignment.status.localizedName(l10n)})',
                                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
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
                                  for (int i = 0; i < group.length; i++) ...[
                                    buildBoardRow(group[i]),
                                    if (i < group.length - 1)
                                      const Divider(height: 1, thickness: 1, color: Colors.black12),
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
          error: (err, stack) => Center(child: Text('Error loading assignments: $err')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TIMELINE VIEW (Gantt-style)
  // ─────────────────────────────────────────────────────────────
  Widget _buildTimelineView(BuildContext context, DateTime dateQuery, User? currentUser, bool canAssign, DateTime serverTime) {
    const double kCellWidth = 100.0;
    const double kRowHeight = 80.0;
    const int kDaysCount = 31;
    final endDate = dateQuery.add(const Duration(days: kDaysCount));

    final screenWidth = MediaQuery.of(context).size.width;
    final propertyColumnWidth = (screenWidth / 3).clamp(80.0, 150.0);

    final timelineAsync = ref.watch(monthlyTimelineProvider(dateQuery, endDate));
    final assignmentsAsync = ref.watch(dateRangeCleaningAssignmentsProvider((dateQuery, endDate)));

    return timelineAsync.when(
      data: (propertyMap) {
        return assignmentsAsync.when(
          data: (assignments) {
            final List<String> propertyNames = propertyMap.keys.toList()..sort();

            return Column(
              children: [
                // Top Header Row for Dates
                Row(
                  children: [
                    SizedBox(
                      width: propertyColumnWidth,
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Properties', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _timelineHorizontalHeaderController,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(kDaysCount, (i) {
                            final date = dateQuery.add(Duration(days: i));
                            final isToday = DateFormat('yyyy-MM-dd').format(date) ==
                                DateFormat('yyyy-MM-dd').format(serverTime);
                            return Container(
                              width: kCellWidth,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isToday ? Colors.blue.shade50 : null,
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(DateFormat.E().format(date),
                                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  Text(DateFormat.d().format(date),
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),

                // Grid Body
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sticky left column: property names
                      SizedBox(
                        width: propertyColumnWidth,
                        child: SingleChildScrollView(
                          controller: _timelineVerticalLabelController,
                          child: Column(
                            children: propertyNames
                                .map((name) => Container(
                                      height: kRowHeight,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      alignment: Alignment.centerLeft,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(color: Colors.grey.shade200),
                                          right: BorderSide(color: Colors.grey.shade300, width: 2),
                                        ),
                                      ),
                                      child: Text(
                                        name.split(',').first,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),

                      // Main grid (scrolls horizontally AND vertically)
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _timelineHorizontalGridController,
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            controller: _timelineVerticalGridController,
                            child: Stack(
                              children: [
                                // Background grid
                                Column(
                                  children: List.generate(
                                    propertyNames.length,
                                    (rowIndex) => Row(
                                      children: List.generate(
                                        kDaysCount,
                                        (colIndex) => Container(
                                          width: kCellWidth,
                                          height: kRowHeight,
                                          decoration: BoxDecoration(
                                            border: Border(
                                              right: BorderSide(color: Colors.grey.shade100),
                                              bottom: BorderSide(color: Colors.grey.shade200),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Foreground pills
                                ...propertyNames.asMap().entries.expand((entry) {
                                  final rowIndex = entry.key;
                                  final propName = entry.value;
                                  final reservations = propertyMap[propName] ?? [];

                                  return reservations.map((res) {
                                    final startOffset = res.startDate.difference(dateQuery).inDays;
                                    final duration = res.endDate.difference(res.startDate).inDays;

                                    double left = (startOffset * kCellWidth) + (kCellWidth / 2);
                                    double width = duration * kCellWidth;

                                    if (startOffset < 0) {
                                      width += (startOffset * kCellWidth);
                                      left = kCellWidth / 2 + (startOffset * kCellWidth);
                                      if (left < 0) {
                                        width += left;
                                        left = 0;
                                      }
                                    }

                                    if (width <= 0) return const SizedBox.shrink();

                                    final assignment = assignments.where((a) => a.reservationId == res.id).firstOrNull;

                                    return Positioned(
                                      left: left,
                                      top: (rowIndex * kRowHeight) + 20,
                                      child: InkWell(
                                        onTap: canAssign
                                            ? () {
                                                _showCleaningAssignmentDialog(
                                                  context,
                                                  ref,
                                                  Reservation(
                                                    id: res.id,
                                                    companyId: res.companyId,
                                                    guestName: res.guestName,
                                                    propertyName: res.propertyName,
                                                    date: res.endDate,
                                                    type: ReservationEventType.checkOut,
                                                  ),
                                                  res.endDate,
                                                  assignment,
                                                );
                                              }
                                            : null,
                                        child: Container(
                                          width: width,
                                          height: kRowHeight - 40,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF008489),
                                            borderRadius: BorderRadius.circular(100),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.1),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (assignment != null) ...[
                                                const Icon(Icons.cleaning_services, color: Colors.white, size: 12),
                                                const SizedBox(width: 4),
                                              ],
                                              Flexible(
                                                child: Text(
                                                  assignment != null
                                                      ? '${res.guestName} (${assignment.cleaners.map((c) => c.name).join(', ')})'
                                                      : res.guestName,
                                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  });
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error loading assignments: $err')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  void _showCleaningAssignmentDialog(BuildContext context, WidgetRef ref, Reservation reservation, DateTime date,
      CleaningAssignment? existingAssignment) async {
    final userRepository = ref.read(userRepositoryProvider);
    final cleaningRepository = ref.read(cleaningRepositoryProvider);

    final allUsers = await userRepository.fetchAll();
    final cleaners = allUsers.where((u) => u.role == AppRole.cleaner).toList();
    final inspectors = allUsers.where((u) => u.role == AppRole.inspector).toList();

    if (!context.mounted) return;

    if (cleaners.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No cleaners found to assign.')));
      return;
    }

    final companyAsync = ref.read(companyProvider(reservation.companyId)).value;
    final isGoldOrHigher = companyAsync != null && companyAsync.tier.index >= SubscriptionTier.gold.index;

    // Initialize list of assigned cleaners
    List<CleanerWithFee> assignedCleaners = existingAssignment?.cleaners ?? [];
    if (assignedCleaners.isEmpty && existingAssignment == null) {
      // Start with one empty slot if new
      assignedCleaners = [];
    }
    
    String? mainCleanerId = existingAssignment?.mainCleanerId;
    String? selectedInspectorId = existingAssignment?.inspectorId;
    final observationController = TextEditingController(text: existingAssignment?.observation ?? '');
    
    // Fetch property details to show instructions & calculate fee
    final propertyRepository = ref.read(propertyRepositoryProvider);
    final allProperties = await propertyRepository.fetchAll();
    
    var property;
    if (reservation.propertyId != null) {
      property = allProperties.where((p) => p.id == reservation.propertyId).firstOrNull;
    }
    if (property == null) {
      final searchName = reservation.propertyName.split(',').first.trim().toLowerCase();
      property = allProperties.where((p) {
        final propName = p.name.trim().toLowerCase();
        return propName == searchName || propName.contains(searchName) || searchName.contains(propName);
      }).firstOrNull;
    }

    final initialPropFee = existingAssignment != null && existingAssignment.propertyCleaningFee > 0
        ? existingAssignment.propertyCleaningFee.toInt().toString()
        : (property != null ? property.cleaningFee.toInt().toString() : '0');

    final propertyCleaningFeeController = TextEditingController(text: initialPropFee);

    // Initial setup for the first cleaner if adding new assignment and list is empty
    if (assignedCleaners.isEmpty && existingAssignment == null) {
       final defaultFee = property != null ? (property.cleaningFee * 0.7).floorToDouble() : 0.0;
       // We don't add one by default yet so the user has to select one from the dropdown first 
       // unless we want to preset the first dropdown.
    }

    final dateStr = defaultDateFormatter.format(date);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final l10n = AppLocalizations.of(context)!;
            
            // Helper to add a cleaner
            void addCleaner(String id) {
              if (assignedCleaners.any((c) => c.id == id)) return;
              final user = cleaners.firstWhere((u) => u.id == id);
              final defaultFee = property != null ? (property.cleaningFee * 0.7).floorToDouble() : 0.0;
              setState(() {
                assignedCleaners.add(CleanerWithFee(id: id, name: user.username, fee: defaultFee));
                if (mainCleanerId == null) mainCleanerId = id;
              });
            }

            return DefaultTabController(
              length: existingAssignment != null ? 2 : 1,
              child: Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  width: 550,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          Text(
                            l10n.assignmentDetailsTitle,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                            if (existingAssignment != null)
                              TabBar(
                                isScrollable: true,
                              indicatorSize: TabBarIndicatorSize.label,
                              labelColor: Colors.blue.shade900,
                              unselectedLabelColor: Colors.blueGrey,
                              tabs: [
                                Tab(text: l10n.settingsTabLabel),
                                Tab(text: l10n.feedbackTabLabel),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 16),
                      Flexible(
                        child: SingleChildScrollView(
                          child: SizedBox(
                            height: 480,
                            child: TabBarView(
                              children: [
                                // Tab 1: Assignment Settings & Instructions
                                SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const SizedBox(height: 8),
                                      
                                      // Cleaners Selection Section
                                      Text(l10n.selectCleanerLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 8),
                                      
                                      // Existing assigned cleaners list
                                      if (assignedCleaners.isNotEmpty)
                                        ...assignedCleaners.asMap().entries.map((entry) {
                                          final idx = entry.key;
                                          final assigned = entry.value;
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withValues(alpha: 0.05),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: mainCleanerId == assigned.id ? Colors.blue.shade300 : Colors.grey.shade300),
                                            ),
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(assigned.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                    ),
                                                    if (mainCleanerId == assigned.id)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(8)),
                                                        child: Text(l10n.mainCleanerLabel, style: TextStyle(fontSize: 10, color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
                                                      )
                                                    else
                                                      TextButton(
                                                        onPressed: () => setState(() => mainCleanerId = assigned.id),
                                                        child: Text(l10n.mainCleanerLabel, style: const TextStyle(fontSize: 12)),
                                                      ),
                                                    IconButton(
                                                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                                      onPressed: () => setState(() {
                                                        assignedCleaners.removeAt(idx);
                                                        if (mainCleanerId == assigned.id) {
                                                          mainCleanerId = assignedCleaners.isNotEmpty ? assignedCleaners.first.id : null;
                                                        }
                                                      }),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: TextField(
                                                        decoration: InputDecoration(
                                                          labelText: l10n.individualFeeLabel(assigned.name),
                                                          prefixIcon: const Icon(Icons.attach_money, size: 16),
                                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                        ),
                                                        keyboardType: TextInputType.number,
                                                        onChanged: (val) {
                                                          final fee = double.tryParse(val) ?? 0.0;
                                                          assignedCleaners[idx] = CleanerWithFee(id: assigned.id, name: assigned.name, fee: fee);
                                                        },
                                                        controller: TextEditingController(text: assigned.fee.toInt().toString())
                                                          ..selection = TextSelection.fromPosition(TextPosition(offset: assigned.fee.toInt().toString().length)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      
                                      if (assignedCleaners.isEmpty || isGoldOrHigher)
                                        DropdownButtonFormField<String>(
                                          decoration: InputDecoration(
                                            labelText: l10n.addCleanerAction,
                                            prefixIcon: const Icon(Icons.person_add_outlined),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            filled: true,
                                            fillColor: Colors.grey.withValues(alpha: 0.05),
                                          ),
                                          items: cleaners
                                              .map((emp) => DropdownMenuItem(value: emp.id, child: Text(emp.username)))
                                              .toList(),
                                          onChanged: (val) {
                                            if (val != null) addCleaner(val);
                                          },
                                        ),
                                      
                                      if (mainCleanerId != null && existingAssignment != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Builder(builder: (context) {
                                              final l10n = AppLocalizations.of(context)!;
                                              final countryCode = ref.watch(phoneCountryCodeProvider);
                                              final allProps = ref.watch(propertiesStreamProvider).valueOrNull ?? [];
                                              final prop = allProps.firstWhere(
                                                (p) => p.id == reservation.propertyId || p.name == reservation.propertyName,
                                                orElse: () => allProps.isEmpty ? allProps.first : allProps.first,
                                              );
                                              final address = allProps.any((p) => p.id == reservation.propertyId || p.name == reservation.propertyName)
                                                  ? '${prop.address}, ${prop.city}'
                                                  : '';
                                              return FilledButton.icon(
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: const Color(0xFF25D366),
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                ),
                                                icon: const Icon(Icons.chat_rounded, size: 18),
                                                label: Text(l10n.messageCleanerOnWhatsApp, style: const TextStyle(fontWeight: FontWeight.w600)),
                                                onPressed: () async {
                                                  final cleaner = cleaners.firstWhere((c) => c.id == mainCleanerId);
                                                  final rawPhone = cleaner.phone ?? '';
                                                  if (rawPhone.isNotEmpty) {
                                                    // Sanitize: strip non-digits
                                                    final digitsOnly = rawPhone.replaceAll(RegExp(r'[^\d]'), '');
                                                    // Use cleaner's specific country code if available, otherwise fallback to company default
                                                    final userCC = cleaner.phoneCountryCode?.replaceAll('+', '') ?? '';
                                                    final effectiveCC = userCC.isNotEmpty ? userCC : countryCode.replaceAll('+', '');
                                                    final fullPhone = '$effectiveCC$digitsOnly';
                                                    
                                                    // Remove duplicate address if propertyName already includes it
                                                    final propertyName = reservation.propertyName;
                                                    String finalAddress = address;
                                                    if (address.isNotEmpty && propertyName.toLowerCase().contains(address.toLowerCase().split(',').first.trim())) {
                                                       // If it's a legacy title containing the address, just use city part if available
                                                       final parts = address.split(',');
                                                       if (parts.length > 2) {
                                                         finalAddress = parts.sublist(2).join(',').trim();
                                                       } else if (parts.length > 1) {
                                                          finalAddress = parts.sublist(1).join(',').trim();
                                                       } else {
                                                          finalAddress = '';
                                                       }
                                                    }

                                                    final message = l10n.whatsAppCleaningMessage(
                                                      cleaner.username,
                                                      defaultDateFormatter.format(reservation.date),
                                                      propertyName,
                                                      finalAddress,
                                                    );
                                                    final whatsappUrl = Uri.parse(
                                                        'https://wa.me/$fullPhone?text=${Uri.encodeComponent(message)}');
                                                    if (await canLaunchUrl(whatsappUrl)) {
                                                      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
                                                    } else {
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text(l10n.couldNotOpenWhatsApp)));
                                                      }
                                                    }
                                                  } else {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text(l10n.noPhoneOnFileError)));
                                                    }
                                                  }
                                                },
                                              );
                                            }),
                                          ),
                                        ),
                                      const SizedBox(height: 16),
                                      DropdownButtonFormField<String>(
                                        value: selectedInspectorId,
                                        decoration: InputDecoration(
                                          labelText: l10n.selectInspectorLabel,
                                          prefixIcon: const Icon(Icons.fact_check_rounded),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                          filled: true,
                                          fillColor: Colors.grey.withValues(alpha: 0.05),
                                        ),
                                        items: inspectors
                                            .map((insp) => DropdownMenuItem(value: insp.id, child: Text(insp.username)))
                                            .toList(),
                                        onChanged: (val) => setState(() => selectedInspectorId = val),
                                      ),
                                      const SizedBox(height: 16),
                                      TextField(
                                        controller: observationController,
                                        maxLines: 2,
                                        decoration: InputDecoration(
                                          labelText: l10n.managerObservationsLabel,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                          prefixIcon: const Icon(Icons.edit_note_rounded),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      TextField(
                                        controller: propertyCleaningFeeController,
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) {
                                          if (!isGoldOrHigher) {
                                             final doubleValue = double.tryParse(val) ?? 0.0;
                                             if (assignedCleaners.isNotEmpty) {
                                               setState(() {
                                                 assignedCleaners[0] = CleanerWithFee(
                                                   id: assignedCleaners[0].id,
                                                   name: assignedCleaners[0].name,
                                                   fee: (doubleValue * 0.7).floorToDouble(),
                                                 );
                                               });
                                             }
                                          }
                                        },
                                        decoration: InputDecoration(
                                          labelText: l10n.propertyCleaningFeeLabel,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                          prefixIcon: const Icon(Icons.business_center_rounded),
                                        ),
                                      ),
                                      if (property != null && property.cleaningInstructions.isNotEmpty) ...[
                                        const SizedBox(height: 24),
                                        const Divider(),
                                        const SizedBox(height: 8),
                                        Text(l10n.propertyInstructionsLabel,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(property.cleaningInstructions,
                                              style: TextStyle(color: Colors.blue.shade900)),
                                        ),
                                        if (property.instructionPhotos.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: property.instructionPhotos.map((photoB64) {
                                              return ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.memory(base64Decode(photoB64),
                                                    width: 100, height: 100, fit: BoxFit.cover),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ],
                                    ],
                                  ),
                                ),
                                // Tab 2: Feedback (Incidents & Findings)
                                if (existingAssignment != null)
                                  SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        if (existingAssignment.incidents.isNotEmpty) ...[
                                          Text(l10n.cleanerIncidentsLabel,
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                          const SizedBox(height: 8),
                                          ...existingAssignment.incidents.map((incident) => Container(
                                                margin: const EdgeInsets.only(bottom: 12),
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.shade50,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.orange.shade200),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(incident.text,
                                                        style: TextStyle(color: Colors.orange.shade900)),
                                                    if (incident.photos.isNotEmpty) ...[
                                                      const SizedBox(height: 8),
                                                      Wrap(
                                                        spacing: 8,
                                                        children: incident.photos
                                                            .map((b64) => ClipRRect(
                                                                  borderRadius: BorderRadius.circular(8),
                                                                  child: Image.memory(base64Decode(b64),
                                                                      width: 80, height: 80, fit: BoxFit.cover),
                                                                ))
                                                            .toList(),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              )),
                                        ],
                                        if (existingAssignment.findings.isNotEmpty) ...[
                                          const SizedBox(height: 16),
                                          Text(l10n.inspectorFindingsLabel,
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                          const SizedBox(height: 8),
                                          ...existingAssignment.findings.map((finding) => Container(
                                                margin: const EdgeInsets.only(bottom: 12),
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.blue.shade200),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(finding.text,
                                                        style: TextStyle(color: Colors.blue.shade900)),
                                                    if (finding.photos.isNotEmpty) ...[
                                                      const SizedBox(height: 8),
                                                      Wrap(
                                                        spacing: 8,
                                                        children: finding.photos
                                                            .map((b64) => ClipRRect(
                                                                  borderRadius: BorderRadius.circular(8),
                                                                  child: Image.memory(base64Decode(b64),
                                                                      width: 80, height: 80, fit: BoxFit.cover),
                                                                ))
                                                            .toList(),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              )),
                                        ],
                                        if (existingAssignment.incidents.isEmpty && existingAssignment.findings.isEmpty)
                                          Center(
                                              child: Padding(
                                                  padding: const EdgeInsets.all(32),
                                          child: Text(l10n.noFeedbackLabel))),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 12,
                        children: [
                          if (existingAssignment != null && (ref.read(authControllerProvider)?.role == AppRole.superAdmin || ref.read(authControllerProvider)?.role == AppRole.administrator))
                            TextButton.icon(
                              onPressed: () async {
                                await cleaningRepository.deleteAssignment(dateStr, reservation.id, reservation.companyId);
                                if (context.mounted) Navigator.pop(context);
                              },
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                              label: Text(l10n.cancelCleaningAction, style: const TextStyle(color: Colors.red)),
                            ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(l10n.cancelAction),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              if (assignedCleaners.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.pleaseSelectCleanerError)));
                                return;
                              }
                              if (mainCleanerId == null) {
                                mainCleanerId = assignedCleaners.first.id;
                              }

                              final inspectorName = selectedInspectorId != null
                                  ? inspectors.firstWhere((i) => i.id == selectedInspectorId).username
                                  : null;

                              final assignment = CleaningAssignment(
                                id: existingAssignment?.id ?? '',
                                companyId: reservation.companyId,
                                reservationId: reservation.id,
                                propertyId: reservation.propertyName,
                                cleaners: assignedCleaners,
                                mainCleanerId: mainCleanerId!,
                                inspectorId: selectedInspectorId,
                                inspectorName: inspectorName,
                                date: dateStr,
                                assignedAt: existingAssignment?.assignedAt ?? ref.read(currentServerTimeProvider).toIso8601String(),
                                observation: observationController.text.trim(),
                                status: existingAssignment?.status ?? CleaningStatus.assigned,
                                startTime: existingAssignment?.startTime ?? '',
                                endTime: existingAssignment?.endTime ?? '',
                                propertyCleaningFee: double.tryParse(propertyCleaningFeeController.text) ?? 0.0,
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
                            child: Text(
                              existingAssignment == null ? l10n.createAssignmentAction : l10n.saveChanges,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
