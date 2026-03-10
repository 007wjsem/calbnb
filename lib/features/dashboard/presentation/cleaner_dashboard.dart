import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../calendar/data/cleaning_repository.dart';
import '../../calendar/domain/cleaning_assignment.dart';
import '../../auth/data/auth_repository.dart';
import '../../admin/data/property_repository.dart';
import '../../admin/domain/property.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/roles.dart';

enum CleaningsFilter { today, all }

class CleanerDashboard extends ConsumerStatefulWidget {
  const CleanerDashboard({super.key});

  @override
  ConsumerState<CleanerDashboard> createState() => _CleanerDashboardState();
}
class _CleanerDashboardState extends ConsumerState<CleanerDashboard> {
  CleaningsFilter _currentFilter = CleaningsFilter.today;
  String? _expandedAssignmentId;

  Future<String> _getWorldTime() async {
    try {
      final response = await http.get(Uri.parse('https://worldtimeapi.org/api/timezone/Etc/UTC')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['datetime'] as String;
      }
    } catch (e) {
      debugPrint('Error fetching world time: $e');
    }
    // Fallback to local time if API fails
    return DateTime.now().toIso8601String();
  }

  String _formatStartTime(String? startTimeIso) {
    if (startTimeIso == null || startTimeIso.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(startTimeIso).toLocal();
      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (_) {
      return '--:--';
    }
  }

  Property? _findProperty(List<Property> properties, String propertyIdentifier) {
    if (properties.isEmpty) return null;
    
    // 1. Try matching by ID (Robust way)
    final byId = properties.where((p) => p.id == propertyIdentifier).firstOrNull;
    if (byId != null) return byId;

    // 2. Try matching by Exact Name (Legacy way)
    final byName = properties.where((p) => p.name == propertyIdentifier).firstOrNull;
    if (byName != null) return byName;

    // 3. Try matching by Concatenated Name, Address (The way that broke)
    final byConcat = properties.where((p) => '${p.name}, ${p.address}' == propertyIdentifier).firstOrNull;
    if (byConcat != null) return byConcat;

    // 4. Try fuzzy match (contains) as last resort
    final fuzzy = properties.where((p) => propertyIdentifier.contains(p.name)).firstOrNull;
    return fuzzy;
  }

  Widget _buildPhotoWidget(String photoData, {double width = 80, double height = 80}) {
    if (photoData.isEmpty) return const SizedBox.shrink();

    Widget errorPlaceholder = Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );

    try {
      if (photoData.startsWith('http')) {
        return Image.network(
          photoData,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => errorPlaceholder,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: width,
              height: height,
              color: Colors.grey.shade100,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },
        );
      } else {
        // Assume Base64
        String cleanBase64 = photoData;
        if (photoData.contains(',')) {
          cleanBase64 = photoData.split(',').last;
        }
        return Image.memory(
          base64Decode(cleanBase64),
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => errorPlaceholder,
        );
      }
    } catch (e) {
      debugPrint('Error rendering photo: $e');
      return errorPlaceholder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(allCleaningAssignmentsProvider);
    final propertiesAsync = ref.watch(allPropertiesProvider); // Access properties to match properly
    final currentUser = ref.watch(authControllerProvider);

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
                'Assignments',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SegmentedButton<CleaningsFilter>(
                segments: const [
                  ButtonSegment(
                    value: CleaningsFilter.today,
                    label: Text('Today'),
                    icon: Icon(Icons.today),
                  ),
                  ButtonSegment(
                    value: CleaningsFilter.all,
                    label: Text('ALL'),
                    icon: Icon(Icons.all_inclusive),
                  ),
                ],
                selected: {_currentFilter},
                onSelectionChanged: (Set<CleaningsFilter> newSelection) {
                  setState(() {
                    _currentFilter = newSelection.first;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: assignmentsAsync.when(
              data: (assignments) {
                final bool isAdministrative = currentUser?.role == AppRole.superAdmin || 
                                             currentUser?.role == AppRole.administrator || 
                                             currentUser?.role == AppRole.manager;
                
                final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
                
                final myAssignments = assignments.where((a) {
                  // Role-based visibility (Cleaners only see their own, Admins see all)
                  final bool isMine = isAdministrative || a.cleanerId == currentUser?.id;
                  if (!isMine) return false;

                  // Global Status filter: Hide 'approved' from everyone, 
                  // but also hide 'pendingInspection' from Cleaners (they are done with it).
                  if (a.status == CleaningStatus.approved) return false;
                  
                  if (!isAdministrative && a.status == CleaningStatus.pendingInspection) {
                    return false;
                  }

                  // Date filter
                  if (_currentFilter == CleaningsFilter.today) {
                    final isToday = a.date == todayStr;
                    // For admins, "Today" also includes anything currently active/overdue
                    if (isAdministrative) {
                      final bool isActive = a.status == CleaningStatus.inProgress || 
                                           a.status == CleaningStatus.fixNeeded || 
                                           a.status == CleaningStatus.pendingInspection;
                      final bool isOverdue = a.date.compareTo(todayStr) < 0;
                      return isToday || isActive || isOverdue;
                    }
                    return isToday;
                  }

                  return true;
                }).toList();

                // Sort by status, then sort by checkout date (closest checkouts first)
                myAssignments.sort((a, b) {
                  final statusCompare = a.status.index.compareTo(b.status.index);
                  if (statusCompare != 0) return statusCompare;
                  return a.date.compareTo(b.date);
                });

                // Extract the active job (there should logically only be one at a time)
                final inProgressJob = myAssignments.where((a) => a.status == CleaningStatus.inProgress).firstOrNull;
                
                // Remove the active job from the standard list view so it's not duplicated
                final remainingJobs = myAssignments.where((a) => a.status != CleaningStatus.inProgress).toList();

                return propertiesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error loading properties: $err')),
                  data: (properties) {
                    final inProgressProperty = inProgressJob != null ? _findProperty(properties, inProgressJob.propertyId) : null;
                    
                    return ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        if (inProgressJob != null) ...[
                          GestureDetector(
                            onTap: () {
                              final currentlyExpanded = _expandedAssignmentId == inProgressJob.id || _expandedAssignmentId == null;
                              setState(() {
                                _expandedAssignmentId = currentlyExpanded ? 'none' : inProgressJob.id;
                              });
                            },
                            child: _buildActiveJobCard(
                              inProgressJob, 
                              inProgressProperty, 
                              _expandedAssignmentId == inProgressJob.id || _expandedAssignmentId == null
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        
                        if (remainingJobs.isEmpty && inProgressJob == null)
                           const Center(child: Padding(
                             padding: EdgeInsets.only(top: 40.0),
                             child: Text('No active assignments.'),
                           )),
                        
                        ...remainingJobs.map((assignment) {
                          final property = _findProperty(properties, assignment.propertyId);
                          final isExpanded = _expandedAssignmentId == assignment.id;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _expandedAssignmentId = isExpanded ? 'none' : assignment.id;
                              });
                            },
                            child: _buildJobCard(assignment, property, isExpanded),
                          );
                        }),
                      ],
                    );
                  }
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

  Widget _buildActiveJobCard(CleaningAssignment assignment, Property? property, bool isExpanded) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade200, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cleaning_services, color: Colors.blue.shade800, size: 14),
                            const SizedBox(width: 4),
                            Text('ACTIVE JOB', style: TextStyle(color: Colors.blue.shade800, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        assignment.propertyId, // Property ID
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (assignment.cleanerName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 14, color: Colors.blueGrey),
                            const SizedBox(width: 4),
                            Text('Cleaner: ${assignment.cleanerName}', style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (assignment.startTime.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, color: Colors.orange.shade800, size: 20),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('STARTED AT', style: TextStyle(fontSize: 10, color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
                            Text(
                              _formatStartTime(assignment.startTime),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            if (isExpanded) ...[
              const SizedBox(height: 20),
            
            if (assignment.observation.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.speaker_notes, color: Colors.orange.shade800, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Manager Notes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                          const SizedBox(height: 4),
                          Text(assignment.observation, style: TextStyle(color: Colors.orange.shade900)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (property != null && property.cleaningInstructions.isNotEmpty) ...[
              Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade200)),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       children: [
                          Icon(Icons.list_alt, color: Colors.blue.shade900, size: 18),
                          const SizedBox(width: 8),
                          Text('Cleaning Instructions', style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
                       ]
                     ),
                     const SizedBox(height: 6),
                     Text(property.cleaningInstructions, style: TextStyle(color: Colors.blue.shade900, height: 1.3)),
                     if (property.instructionPhotos.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: property.instructionPhotos.map((photoData) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildPhotoWidget(photoData, width: 100, height: 100),
                            );
                          }).toList(),
                        ),
                     ]
                   ]
                 ),
               ),
               const SizedBox(height: 16),
            ],

            if (assignment.incidents.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.report_problem_outlined, color: Colors.red.shade800, size: 18),
                        const SizedBox(width: 8),
                        Text('Reported Incidents', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...assignment.incidents.map((incident) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(incident.text, style: TextStyle(color: Colors.red.shade900, fontSize: 13)),
                          if (incident.photos.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 60,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: incident.photos.length,
                                itemBuilder: (ctx, idx) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.memory(base64Decode(incident.photos[idx]), width: 60, height: 60, fit: BoxFit.cover),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

              const Divider(),
              const SizedBox(height: 12),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (!isExpanded) ...[
                       Icon(Icons.expand_more, size: 16, color: Colors.grey.shade400),
                       const SizedBox(width: 4),
                       Text('Tap to expand', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ] else ...[
                       Icon(Icons.expand_less, size: 16, color: Colors.grey.shade400),
                       const SizedBox(width: 4),
                       Text('Tap to collapse', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ],
                ),
                const Spacer(),
                if (isExpanded)
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(assignment, CleaningStatus.pendingInspection, endTimer: true),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Finish Job'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            
            if (isExpanded) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _showReportIncidentDialog(assignment),
                icon: const Icon(Icons.warning_amber),
                label: const Text('Report Incident'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade800,
                  side: BorderSide(color: Colors.orange.shade800),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ],
        ),
      )
    );
  }

  Widget _buildJobCard(CleaningAssignment assignment, Property? property, bool isExpanded) {
    Color statusColor;
    String statusText;
    switch(assignment.status) {
      case CleaningStatus.assigned:
        statusColor = Colors.grey; statusText = 'Assigned'; break;
      case CleaningStatus.inProgress:
        statusColor = Colors.blue; statusText = 'In Progress'; break;
      case CleaningStatus.pendingInspection:
        statusColor = Colors.orange; statusText = 'Pending Inspection'; break;
      case CleaningStatus.fixNeeded:
        statusColor = Colors.red; statusText = 'Fix Needed'; break;
      case CleaningStatus.approved:
        statusColor = Colors.green; statusText = 'Approved'; break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.propertyId,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.event_available, size: 14, color: Colors.blueGrey),
                          const SizedBox(width: 4),
                          Text('Checkout: ${assignment.date.isNotEmpty ? DateFormat.yMMMd().format(DateTime.tryParse(assignment.date) ?? DateTime.now()) : "N/A"}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            
            if (isExpanded) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              
              if (assignment.observation.isNotEmpty) ...[
                const Text('Manager Notes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(assignment.observation, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
                const SizedBox(height: 16),
              ],
              
              if (property != null) ...[
                Row(
                  children: [
                    Icon(Icons.list_alt, color: Colors.blue.shade900, size: 16),
                    const SizedBox(width: 8),
                    Text('Cleaning Instructions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                if (property.cleaningInstructions.isNotEmpty)
                   Text(property.cleaningInstructions, style: const TextStyle(fontSize: 13, height: 1.4)),
                if (property.instructionPhotos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: property.instructionPhotos.length,
                      itemBuilder: (ctx, idx) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildPhotoWidget(property.instructionPhotos[idx]),
                        ),
                      ),
                    ),
                  ),
                ],
              ],

              if (assignment.incidents.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         children: [
                           Icon(Icons.report_problem_outlined, color: Colors.red.shade800, size: 18),
                           const SizedBox(width: 8),
                           Text('Reported Incidents', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 13)),
                         ],
                       ),
                       const SizedBox(height: 8),
                       ...assignment.incidents.map((incident) => Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(incident.text, style: const TextStyle(fontSize: 13)),
                           if (incident.photos.isNotEmpty) ...[
                             const SizedBox(height: 8),
                             SizedBox(
                               height: 50,
                               child: ListView.builder(
                                 scrollDirection: Axis.horizontal,
                                 itemCount: incident.photos.length,
                                 itemBuilder: (ctx, idx) => Padding(
                                   padding: const EdgeInsets.only(right: 6),
                                   child: ClipRRect(
                                     borderRadius: BorderRadius.circular(4),
                                     child: Image.memory(base64Decode(incident.photos[idx]), width: 50, height: 50, fit: BoxFit.cover),
                                   ),
                                 ),
                               ),
                             ),
                           ],
                         ],
                       )),
                     ],
                   ),
                ),
                const SizedBox(height: 16),
              ],

              if (assignment.status == CleaningStatus.fixNeeded && assignment.findings.isNotEmpty) ...[
                Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text('⚠ Inspector Findings requiring fixing:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                       const SizedBox(height: 4),
                       Text(assignment.findings.last.text, style: TextStyle(color: Colors.red.shade900, fontSize: 13)),
                     ]
                   ),
                ),
                const SizedBox(height: 16),
              ],
            ],

            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (!isExpanded) ...[
                       Icon(Icons.expand_more, size: 16, color: Colors.grey.shade400),
                       const SizedBox(width: 4),
                       Text('Tap to expand', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ] else ...[
                       Icon(Icons.expand_less, size: 16, color: Colors.grey.shade400),
                       const SizedBox(width: 4),
                       Text('Tap to collapse', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ],
                ),
                if (assignment.status == CleaningStatus.assigned || assignment.status == CleaningStatus.fixNeeded)
                  ElevatedButton.icon(
                     onPressed: () => _updateStatus(assignment, CleaningStatus.inProgress, startTimer: true),
                     icon: const Icon(Icons.play_arrow, size: 18),
                     label: const Text('Start Job'),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.blue, 
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                       visualDensity: VisualDensity.compact,
                     ),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(CleaningAssignment assignment, CleaningStatus newStatus, {bool startTimer = false, bool endTimer = false}) async {
    final repo = ref.read(cleaningRepositoryProvider);
    
    String? startTime = assignment.startTime;
    String? endTime = assignment.endTime;

    if (startTimer) {
      startTime = await _getWorldTime();
    }
    if (endTimer) {
      endTime = await _getWorldTime();
    }

    final updated = assignment.copyWith(
      status: newStatus,
      startTime: startTime,
      endTime: endTime,
      assignedAt: assignment.assignedAt,
    );
    
    await repo.saveAssignment(updated);
  }

  void _showReportIncidentDialog(CleaningAssignment assignment) {
    final textController = TextEditingController();
    String? selectedCategory;
    final categories = [
      'Animals/Pets',
      'Property Damaged',
      'Objects Damaged or Missing',
      'Others',
    ];
    List<String> incidentPhotos = [];
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Report Incident'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories.map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      )).toList(),
                      onChanged: (val) => setState(() => selectedCategory = val),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: textController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Details / Description', alignLabelWithHint: true),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 800);
                        if (image != null) {
                          final bytes = await image.readAsBytes();
                          final base64String = base64Encode(bytes);
                          setState(() {
                            incidentPhotos.add(base64String);
                          });
                        }
                      },
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text('Add Photo'),
                    ),
                    if (incidentPhotos.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: incidentPhotos.asMap().entries.map((entry) {
                          final index = entry.key;
                          final photoB64 = entry.value;
                          return Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: MemoryImage(base64Decode(photoB64)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      incidentPhotos.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedCategory == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a category.')),
                      );
                      return;
                    }
                    if (textController.text.trim().isEmpty && incidentPhotos.isEmpty) return;
                    
                    final newIncident = IncidentReport(
                      category: selectedCategory!,
                      text: textController.text.trim(),
                      photos: incidentPhotos,
                      timestamp: DateTime.now().toIso8601String(),
                    );
                    
                    final repo = ref.read(cleaningRepositoryProvider);
                    final updated = assignment.copyWith(
                      incidents: [...assignment.incidents, newIncident],
                      assignedAt: assignment.assignedAt,
                    );
                    await repo.saveAssignment(updated);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Submit Report'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
