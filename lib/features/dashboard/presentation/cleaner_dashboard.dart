import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../calendar/data/cleaning_repository.dart';
import '../../calendar/domain/cleaning_assignment.dart';
import '../../auth/data/auth_repository.dart';
import '../../admin/presentation/property_management_screen.dart';
import '../../admin/data/property_repository.dart';
import '../../admin/domain/property.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:calbnb/l10n/app_localizations.dart';
import '../../company/domain/subscription.dart';
import '../../company/data/company_repository.dart';
import '../../../core/theme/app_colors.dart';

class CleanerDashboard extends ConsumerStatefulWidget {
  const CleanerDashboard({super.key});

  @override
  ConsumerState<CleanerDashboard> createState() => _CleanerDashboardState();
}
class _CleanerDashboardState extends ConsumerState<CleanerDashboard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update the UI every second to refresh the live timer
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatElapsedTime(String? startTimeStr) {
    if (startTimeStr == null) return "00:00:00";
    final startTime = DateTime.tryParse(startTimeStr);
    if (startTime == null) return "00:00:00";
    
    final elapsed = DateTime.now().difference(startTime);
    final hours = elapsed.inHours.toString().padLeft(2, '0');
    final minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  void _showChecklistDialog(CleaningAssignment assignment, Property? property, {required bool requiresPhotoEvidence}) {
    // If no checklists and no photos required, just finish it directly
    if ((property == null || property.checklists.isEmpty) && !requiresPhotoEvidence) {
      _updateStatus(assignment, CleaningStatus.pendingInspection, endTimer: true);
      return;
    }

    final Map<int, bool> checkedState = { for (var i = 0; i < (property?.checklists.length ?? 0); i++) i: false };
    final List<String> proofPhotos = [];
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final allChecked = checkedState.values.every((v) => v);
            final hasEnoughPhotos = !requiresPhotoEvidence || proofPhotos.isNotEmpty;
            final canComplete = allChecked && hasEnoughPhotos;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(requiresPhotoEvidence ? Icons.camera_alt : Icons.playlist_add_check, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(requiresPhotoEvidence ? AppLocalizations.of(context)!.checkoutVerificationTitle : AppLocalizations.of(context)!.requiredChecklistTitle),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (property != null && property.checklists.isNotEmpty) ...[
                        Text(AppLocalizations.of(context)!.verifyTasksDesc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 16),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: property.checklists.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = property.checklists[index];
                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(item, style: TextStyle(fontSize: 14, decoration: checkedState[index]! ? TextDecoration.lineThrough : null)),
                              value: checkedState[index],
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() {
                                  checkedState[index] = val ?? false;
                                });
                              },
                            );
                          },
                        ),
                        if (requiresPhotoEvidence) const SizedBox(height: 24),
                      ],

                      if (requiresPhotoEvidence) ...[
                        Text(AppLocalizations.of(context)!.photoEvidenceRequiredTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(AppLocalizations.of(context)!.capturePhotosDesc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 12),
                        
                        // Photo Uploader Row
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ...proofPhotos.asMap().entries.map((entry) {
                               final index = entry.key;
                               final b64 = entry.value;
                               return Stack(
                                 clipBehavior: Clip.none,
                                 children: [
                                   ClipRRect(
                                     borderRadius: BorderRadius.circular(8),
                                     child: Image.memory(base64Decode(b64), width: 80, height: 80, fit: BoxFit.cover),
                                   ),
                                   Positioned(
                                     right: -8,
                                     top: -8,
                                     child: GestureDetector(
                                       onTap: () => setState(() => proofPhotos.removeAt(index)),
                                       child: Container(
                                         padding: const EdgeInsets.all(4),
                                         decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                         child: const Icon(Icons.close, color: Colors.white, size: 14),
                                       ),
                                     ),
                                   ),
                                 ]
                               );
                            }),

                            if (proofPhotos.length < 3)
                              GestureDetector(
                                onTap: () async {
                                  final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 50, maxWidth: 800);
                                  if (image != null) {
                                    final bytes = await image.readAsBytes();
                                    final base64String = base64Encode(bytes);
                                    setState(() => proofPhotos.add(base64String));
                                  }
                                },
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3), style: BorderStyle.solid),
                                  ),
                                  child: const Center(child: Icon(Icons.add_a_photo, color: AppColors.primary)),
                                ),
                              )
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancelAction, style: const TextStyle(color: AppColors.textSecondary)),
                ),
                FilledButton.icon(
                  onPressed: canComplete ? () {
                    Navigator.pop(context);
                    final repo = ref.read(cleaningRepositoryProvider);
                    final updated = assignment.copyWith(
                      status: CleaningStatus.pendingInspection,
                      endTime: DateTime.now().toIso8601String(),
                      proofPhotos: proofPhotos,
                    );
                    repo.saveAssignment(updated);
                  } : null,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(AppLocalizations.of(context)!.completeJobAction),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(allCleaningAssignmentsProvider);
    final propertiesAsync = ref.watch(propertyRepositoryProvider); // Access properties to match properly
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
                AppLocalizations.of(context)!.myPendingAssignmentsTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: assignmentsAsync.when(
              data: (assignments) {
                final canSeeAll = currentUser?.role.displayName == 'Super Admin' || currentUser?.role.displayName == 'Administrator' || currentUser?.role.displayName == 'Manager';
                
                // Only show jobs that are not completed globally for cleaners
                final pendingAssignments = assignments.where((a) => a.status == CleaningStatus.assigned || a.status == CleaningStatus.inProgress || a.status == CleaningStatus.fixNeeded).toList();

                final myAssignments = canSeeAll 
                    ? pendingAssignments
                    : pendingAssignments.where((a) => a.cleanerId == currentUser?.id).toList();

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

                return Column(
                  children: [
                    if (inProgressJob != null) ...[
                      FutureBuilder<List<Property>>(
                        future: propertiesAsync.fetchAll(),
                        builder: (ctx, snap) {
                          final props = snap.data ?? [];
                          final property = props.where((p) => p.name == inProgressJob.propertyId).firstOrNull;
                          return _buildActiveJobCard(inProgressJob, property);
                        }
                      ),
                      const SizedBox(height: 16),
                      if (remainingJobs.isNotEmpty)
                         const Divider()
                    ],
                    if (remainingJobs.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          itemCount: remainingJobs.length,
                          itemBuilder: (context, index) {
                            final assignment = remainingJobs[index];
                            return FutureBuilder<List<Property>>(
                              future: propertiesAsync.fetchAll(),
                              builder: (ctx, snap) {
                                final props = snap.data ?? [];
                                final property = props.where((p) => p.name == assignment.propertyId).firstOrNull;
                                return _buildJobCard(assignment, property);
                              }
                            );
                          },
                        ),
                      )
                    else if (inProgressJob == null)
                       Expanded(child: Center(child: Text(AppLocalizations.of(context)!.noPendingAssignmentsDesc)))
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace stack) => Center(child: Text(AppLocalizations.of(context)!.genericError(error.toString()))),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActiveJobCard(CleaningAssignment assignment, Property? property) {
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
                            Text(AppLocalizations.of(context)!.activeJobBadge, style: TextStyle(color: Colors.blue.shade800, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        assignment.propertyId, // Property Name
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, color: Colors.orange.shade800, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        _formatElapsedTime(assignment.startTime),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange.shade900, fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (assignment.observation.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.speaker_notes, color: Colors.orange.shade800, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.managerNotesLabel, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
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
                          Text(AppLocalizations.of(context)!.cleaningInstructionsLabel, style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
                       ]
                     ),
                     const SizedBox(height: 6),
                     Text(property.cleaningInstructions, style: TextStyle(color: Colors.blue.shade900, height: 1.3)),
                     if (property.instructionPhotos.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: property.instructionPhotos.map((photoB64) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(base64Decode(photoB64), width: 100, height: 100, fit: BoxFit.cover),
                            );
                          }).toList(),
                        ),
                     ]
                   ]
                 ),
               ),
               const SizedBox(height: 16),
            ],

            const Divider(),
            const SizedBox(height: 12),

            // Actionable buttons
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    onPressed: () => _showReportIncidentDialog(assignment),
                    icon: const Icon(Icons.warning_amber),
                    label: Text(AppLocalizations.of(context)!.reportIncidentAction),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade800,
                      side: BorderSide(color: Colors.orange.shade800),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Consumer(
                    builder: (context, ref, _) {
                      final companyAsync = ref.watch(companyProvider(assignment.companyId));
                      final hasBronze = companyAsync.unwrapPrevious().valueOrNull?.tier.index != null && 
                                        companyAsync.unwrapPrevious().valueOrNull!.tier.index >= SubscriptionTier.bronze.index;

                      return ElevatedButton.icon(
                        onPressed: () => _showChecklistDialog(assignment, property, requiresPhotoEvidence: hasBronze),
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(AppLocalizations.of(context)!.finishJobAction),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      );
                    }
                  ),
                ),
              ],
            )
          ],
        ),
      )
    );
  }

  Widget _buildJobCard(CleaningAssignment assignment, Property? property) {
    Color statusColor;
    String statusText;
    switch(assignment.status) {
      case CleaningStatus.assigned:
        statusColor = Colors.grey; statusText = AppLocalizations.of(context)!.statusAssigned; break;
      case CleaningStatus.inProgress:
        statusColor = Colors.blue; statusText = AppLocalizations.of(context)!.statusInProgress; break;
      case CleaningStatus.pendingInspection:
        statusColor = Colors.orange; statusText = AppLocalizations.of(context)!.statusPendingInspection; break;
      case CleaningStatus.fixNeeded:
        statusColor = Colors.red; statusText = AppLocalizations.of(context)!.statusFixNeeded; break;
      case CleaningStatus.approved:
        statusColor = Colors.green; statusText = AppLocalizations.of(context)!.statusApprovedCompleted; break;
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
                          Text(AppLocalizations.of(context)!.checkoutDateLabel(DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(DateTime.parse(assignment.date))), style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                        ]
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.assignment_turned_in_outlined, size: 14, color: Colors.blueGrey),
                          const SizedBox(width: 4),
                          // add_jm isn't natively localized perfectly by default, but yMMMd is
                          Text(AppLocalizations.of(context)!.assignedDateLabel(DateFormat.yMMMd(Localizations.localeOf(context).languageCode).add_jm().format(DateTime.parse(assignment.assignedAt))), style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
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
            const SizedBox(height: 12),
            if (assignment.observation.isNotEmpty) ...[
              Text('${AppLocalizations.of(context)!.managerNotesLabel}:', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(assignment.observation, style: const TextStyle(color: Colors.blueGrey)),
              const SizedBox(height: 12),
            ],
            
            if (property != null && property.cleaningInstructions.isNotEmpty) ...[
              Container(
                 padding: const EdgeInsets.all(12),
                 margin: const EdgeInsets.only(bottom: 12),
                 decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade200)),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       children: [
                          Icon(Icons.cleaning_services, color: Colors.blue.shade900, size: 20),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.cleaningInstructionsLabel, style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
                       ]
                     ),
                     const SizedBox(height: 4),
                     Text(property.cleaningInstructions, style: TextStyle(color: Colors.blue.shade900)),
                     if (property.instructionPhotos.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: property.instructionPhotos.map((photoB64) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(base64Decode(photoB64), width: 100, height: 100, fit: BoxFit.cover),
                            );
                          }).toList(),
                        ),
                     ]
                   ]
                 ),
               ),
            ],

            if (assignment.status == CleaningStatus.fixNeeded && assignment.findings.isNotEmpty) ...[
               Container(
                 padding: const EdgeInsets.all(12),
                 margin: const EdgeInsets.only(bottom: 12),
                 decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(AppLocalizations.of(context)!.inspectorFindingsFixLabel, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 4),
                     Text(assignment.findings.last.text, style: TextStyle(color: Colors.red.shade900)),
                   ]
                 ),
               ),
            ],

            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                 if (assignment.status == CleaningStatus.assigned || assignment.status == CleaningStatus.fixNeeded) ...[
                   ElevatedButton.icon(
                      onPressed: () => _updateStatus(assignment, CleaningStatus.inProgress, startTimer: true),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(AppLocalizations.of(context)!.startJobAction),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                   ),
                 ],
                 if (assignment.status == CleaningStatus.inProgress) ...[
                   // Active jobs are now handled entirely by _buildActiveJobCard
                 ]
              ],
            )
          ],
        ),
      )
    );
  }

  Future<void> _updateStatus(CleaningAssignment assignment, CleaningStatus newStatus, {bool startTimer = false, bool endTimer = false}) async {
    final repo = ref.read(cleaningRepositoryProvider);
    
    // We create a fresh copy instead of modifying the old one implicitly
    final updated = assignment.copyWith(
      status: newStatus,
      startTime: startTimer ? DateTime.now().toIso8601String() : assignment.startTime,
      endTime: endTimer ? DateTime.now().toIso8601String() : assignment.endTime,
      assignedAt: assignment.assignedAt,
    );
    
    await repo.saveAssignment(updated);
  }

  void _showReportIncidentDialog(CleaningAssignment assignment) {
    final textController = TextEditingController();
    List<String> incidentPhotos = [];
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.reportIncidentAction),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: textController,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.descriptionLabel, alignLabelWithHint: true),
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
                      label: Text(AppLocalizations.of(context)!.addPhotoAction),
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
                  child: Text(AppLocalizations.of(context)!.cancelAction),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (textController.text.trim().isEmpty && incidentPhotos.isEmpty) return;
                    
                    final newIncident = IncidentReport(
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
                  child: Text(AppLocalizations.of(context)!.submitReportAction),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
