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
import '../../../core/constants/roles.dart';
import 'package:http/http.dart' as http;

class InspectorDashboard extends ConsumerStatefulWidget {
  const InspectorDashboard({super.key});

  @override
  ConsumerState<InspectorDashboard> createState() => _InspectorDashboardState();
}

class _InspectorDashboardState extends ConsumerState<InspectorDashboard> {
  String? _expandedAssignmentId;

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
    final propertiesAsync = ref.watch(allPropertiesProvider);
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
                'Inspections',
                style: Theme.of(context).textTheme.headlineMedium,
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
                
                final myInspections = isAdministrative 
                    ? assignments 
                    : assignments.where((a) => 
                        a.inspectorId == currentUser?.id && 
                        a.status != CleaningStatus.assigned && 
                        a.status != CleaningStatus.approved
                      ).toList();

                // Sort by status, then by date priority
                myInspections.sort((a, b) {
                  final statusCompare = a.status.index.compareTo(b.status.index);
                  if (statusCompare != 0) return statusCompare;
                  return a.date.compareTo(b.date);
                });

                if (myInspections.isEmpty) {
                  return const Center(child: Text('No pending inspections.'));
                }

                return propertiesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error loading properties: $err')),
                  data: (properties) {
                    return ListView.builder(
                      itemCount: myInspections.length,
                      itemBuilder: (context, index) {
                        final assignment = myInspections[index];
                        final property = _findProperty(properties, assignment.propertyId);
                        final isExpanded = _expandedAssignmentId == assignment.id;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                               _expandedAssignmentId = isExpanded ? 'none' : assignment.id;
                            });
                          },
                          child: _buildInspectionCard(assignment, property, isExpanded),
                        );
                      },
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

  Widget _buildInspectionCard(CleaningAssignment assignment, Property? property, bool isExpanded) {
    Color statusColor;
    String statusText;
    switch(assignment.status) {
      case CleaningStatus.assigned:
      case CleaningStatus.inProgress:
        statusColor = Colors.blueGrey; statusText = 'Waiting for Cleaner...'; break;
      case CleaningStatus.pendingInspection:
        statusColor = Colors.orange; statusText = 'Ready for Inspection'; break;
      case CleaningStatus.fixNeeded:
        statusColor = Colors.red; statusText = 'Cleaner is fixing issues...'; break;
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
                          const Icon(Icons.person_outline, size: 14, color: Colors.blueGrey),
                          const SizedBox(width: 4),
                          Text('Cleaner: ${assignment.cleanerName.isNotEmpty ? assignment.cleanerName : "Unassigned"}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.event_available_outlined, size: 14, color: Colors.blueGrey),
                          const SizedBox(width: 4),
                          Text('Checkout: ${assignment.date.isNotEmpty ? DateFormat.yMMMd().format(DateTime.tryParse(assignment.date) ?? DateTime.now()) : "N/A"}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                        ]
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.assignment_turned_in_outlined, size: 14, color: Colors.blueGrey),
                          const SizedBox(width: 4),
                          Text('Assigned: ${assignment.assignedAt.isNotEmpty ? DateFormat.yMMMd().add_jm().format(DateTime.tryParse(assignment.assignedAt) ?? DateTime.now()) : "N/A"}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                        ]
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              
              Text('Cleaner: ${assignment.cleanerName}', style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600, fontSize: 13)),
              if (assignment.endTime.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Finished at: ${_formatTime(assignment.endTime)}', style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
                ),
              
              if (assignment.observation.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Manager Notes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(assignment.observation, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
              ],

              if (property != null) ...[
                const SizedBox(height: 16),
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
                   decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         children: [
                           Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 18),
                           const SizedBox(width: 8),
                           Text('Reported Incidents', style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 13)),
                         ],
                       ),
                       const SizedBox(height: 8),
                       ...assignment.incidents.map((incident) {
                         return Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(incident.text, style: TextStyle(color: Colors.orange.shade900, fontSize: 13)),
                             if (incident.photos.isNotEmpty) ...[
                               const SizedBox(height: 4),
                               Wrap(
                                 spacing: 4,
                                 runSpacing: 4,
                                 children: incident.photos.map((b64) => ClipRRect(
                                   borderRadius: BorderRadius.circular(4),
                                   child: Image.memory(base64Decode(b64), width: 50, height: 50, fit: BoxFit.cover),
                                 )).toList(),
                               ),
                             ],
                             const SizedBox(height: 8),
                           ],
                         );
                       }),
                     ],
                   ),
                ),
              ],

              if (assignment.findings.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade200)),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text('Inspector Findings / Notes:', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                       const SizedBox(height: 4),
                       ...assignment.findings.map((finding) => Padding(
                         padding: const EdgeInsets.only(bottom: 8.0),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(finding.text.isNotEmpty ? finding.text : "No text observation", style: TextStyle(color: Colors.blue.shade900, fontSize: 13)),
                             if (finding.photos.isNotEmpty) ...[
                               const SizedBox(height: 4),
                               Wrap(
                                 spacing: 4,
                                 runSpacing: 4,
                                 children: finding.photos.map((b64) => ClipRRect(
                                   borderRadius: BorderRadius.circular(4),
                                   child: Image.memory(base64Decode(b64), width: 50, height: 50, fit: BoxFit.cover),
                                 )).toList(),
                               ),
                             ],
                           ],
                         ),
                       )),
                     ],
                   ),
                ),
              ],
            ],

            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row( // Wrap the expand/collapse indicators in a Row
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
                if (assignment.status == CleaningStatus.pendingInspection)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                         OutlinedButton.icon(
                            onPressed: () => _showReviewDialog(assignment, false),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Decline'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              visualDensity: VisualDensity.compact,
                            ),
                         ),
                         const SizedBox(width: 8),
                         ElevatedButton.icon(
                            onPressed: () => _showReviewDialog(assignment, true),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green, 
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                            ),
                         ),
                      ],
                    ),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showReviewDialog(CleaningAssignment assignment, bool isApproval) {
    final textController = TextEditingController();
    List<String> findingPhotos = [];
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isApproval ? 'Add Approval Notes (Optional)' : 'Report Findings (Fix Needed)', style: TextStyle(color: isApproval ? Colors.green : Colors.red)),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: textController,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: isApproval ? 'Notes' : 'Description of issues', alignLabelWithHint: true),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 800);
                        if (image != null) {
                          final bytes = await image.readAsBytes();
                          final base64String = base64Encode(bytes);
                          setState(() {
                            findingPhotos.add(base64String);
                          });
                        }
                      },
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text('Add Photo'),
                    ),
                    if (findingPhotos.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: findingPhotos.asMap().entries.map((entry) {
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
                                      findingPhotos.removeAt(index);
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
                    if (!isApproval && textController.text.trim().isEmpty && findingPhotos.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide text or photo to decline')));
                      return;
                    }
                    
                    final worldTime = await _getWorldTime();
                    final newFinding = InspectionFinding(
                      text: textController.text.trim(),
                      photos: findingPhotos,
                      timestamp: worldTime,
                    );
                    
                    final repo = ref.read(cleaningRepositoryProvider);
                    final updated = assignment.copyWith(
                      status: isApproval ? CleaningStatus.approved : CleaningStatus.fixNeeded,
                      findings: [...assignment.findings, newFinding],
                      assignedAt: assignment.assignedAt,
                    );
                    await repo.saveAssignment(updated);
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: isApproval ? Colors.green : Colors.red, foregroundColor: Colors.white),
                  child: Text(isApproval ? 'Approve Job' : 'Send to Fix'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String> _getWorldTime() async {
    try {
      final response = await http.get(Uri.parse('http://worldtimeapi.org/api/timezone/Etc/UTC')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['datetime'].toString();
      }
    } catch (_) {}
    return DateTime.now().toIso8601String();
  }

  String _formatTime(String timeStr) {
    if (timeStr.isEmpty) return 'N/A';
    final dt = DateTime.tryParse(timeStr);
    if (dt == null) return 'N/A';
    return DateFormat.jm().format(dt.toLocal());
  }
}
