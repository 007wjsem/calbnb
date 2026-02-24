import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../calendar/data/cleaning_repository.dart';
import '../../calendar/domain/cleaning_assignment.dart';
import '../../auth/data/auth_repository.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class InspectorDashboard extends ConsumerStatefulWidget {
  const InspectorDashboard({super.key});

  @override
  ConsumerState<InspectorDashboard> createState() => _InspectorDashboardState();
}

class _InspectorDashboardState extends ConsumerState<InspectorDashboard> {

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(allCleaningAssignmentsProvider);
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
                'Pending Inspections',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: assignmentsAsync.when(
              data: (assignments) {
                final canSeeAll = currentUser?.role.displayName == 'Super Admin' || currentUser?.role.displayName == 'Administrator' || currentUser?.role.displayName == 'Manager';
                
                // Show assignments that inspectors care about (active, pending review, fix needed)
                final pendingInspections = assignments.where((a) => a.status != CleaningStatus.assigned && a.status != CleaningStatus.approved).toList();

                final myInspections = canSeeAll
                    ? pendingInspections
                    : pendingInspections.where((a) => a.inspectorId == currentUser?.id).toList();

                // Sort by status, then by date priority
                myInspections.sort((a, b) {
                  final statusCompare = a.status.index.compareTo(b.status.index);
                  if (statusCompare != 0) return statusCompare;
                  return a.date.compareTo(b.date);
                });

                if (myInspections.isEmpty) {
                  return const Center(child: Text('No pending inspections.'));
                }

                return ListView.builder(
                  itemCount: myInspections.length,
                  itemBuilder: (context, index) {
                    return _buildInspectionCard(myInspections[index]);
                  },
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

  Widget _buildInspectionCard(CleaningAssignment assignment) {
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
                        assignment.propertyId, // Currently the name
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.event_available_outlined, size: 14, color: Colors.blueGrey),
                          const SizedBox(width: 4),
                          Text('Checkout: ${DateFormat.yMMMd().format(DateTime.parse(assignment.date))}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                        ]
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.assignment_turned_in_outlined, size: 14, color: Colors.blueGrey),
                          const SizedBox(width: 4),
                          Text('Assigned: ${DateFormat.yMMMd().add_jm().format(DateTime.parse(assignment.assignedAt))}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
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
            const SizedBox(height: 8),
            Text('Cleaner: ${assignment.cleanerName}', style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600)),
            if (assignment.endTime.isNotEmpty)
              Text('Finished at: ${DateFormat.jm().format(DateTime.parse(assignment.endTime))}', style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
            
            if (assignment.incidents.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text('Reported Incidents:', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 4),
                     ...assignment.incidents.map((incident) {
                       return Padding(
                         padding: const EdgeInsets.only(bottom: 8.0),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(incident.text, style: TextStyle(color: Colors.orange.shade900)),
                             if (incident.photos.isNotEmpty) ...[
                               const SizedBox(height: 4),
                               Wrap(
                                 spacing: 8,
                                 runSpacing: 8,
                                 children: incident.photos.map((b64) => ClipRRect(
                                   borderRadius: BorderRadius.circular(4),
                                   child: Image.memory(base64Decode(b64), width: 60, height: 60, fit: BoxFit.cover),
                                 )).toList(),
                               )
                             ]
                           ],
                         ),
                       );
                     }),
                   ]
                 ),
              ),
            ],
            
            if (assignment.findings.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade200)),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text('Inspector Findings / Notes:', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 4),
                     ...assignment.findings.map((finding) {
                       return Padding(
                         padding: const EdgeInsets.only(bottom: 8.0),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(finding.text.isNotEmpty ? finding.text : "No text observation", style: TextStyle(color: Colors.blue.shade900)),
                             if (finding.photos.isNotEmpty) ...[
                               const SizedBox(height: 8),
                               Wrap(
                                 spacing: 8,
                                 runSpacing: 8,
                                 children: finding.photos.map((b64) => ClipRRect(
                                   borderRadius: BorderRadius.circular(4),
                                   child: Image.memory(base64Decode(b64), width: 80, height: 80, fit: BoxFit.cover),
                                 )).toList(),
                               )
                             ]
                           ],
                         ),
                       );
                     }),
                   ]
                 ),
              ),
            ],

            const Divider(),
            if (assignment.status == CleaningStatus.pendingInspection)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   OutlinedButton.icon(
                      onPressed: () => _showReviewDialog(assignment, false),
                      icon: const Icon(Icons.close),
                      label: const Text('Decline (Fix Needed)'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                   ),
                   const SizedBox(width: 12),
                   ElevatedButton.icon(
                      onPressed: () => _showReviewDialog(assignment, true),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                   ),
                ],
              )
          ],
        ),
      )
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
                    
                    final newFinding = InspectionFinding(
                      text: textController.text.trim(),
                      photos: findingPhotos,
                      timestamp: DateTime.now().toIso8601String(),
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

  Future<void> _updateStatus(CleaningAssignment assignment, CleaningStatus newStatus) async {
    final repo = ref.read(cleaningRepositoryProvider);
    final updated = assignment.copyWith(
      status: newStatus,
      assignedAt: assignment.assignedAt,
      endTime: assignment.endTime,
      incidents: assignment.incidents,
      findings: assignment.findings,
    );
    await repo.saveAssignment(updated);
  }
}
