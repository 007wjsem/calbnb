import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../admin/data/property_repository.dart';
import '../../admin/domain/property.dart';
import '../../calendar/data/cleaning_repository.dart';
import '../../calendar/domain/cleaning_assignment.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:calbnb/l10n/app_localizations.dart';

/// Read-only dashboard for Property Owners
class OwnerDashboard extends ConsumerStatefulWidget {
  const OwnerDashboard({super.key});

  @override
  ConsumerState<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends ConsumerState<OwnerDashboard> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final isOwner = user?.role.displayName == 'Property Owner';

    if (user == null || !isOwner) {
      return const Scaffold(body: Center(child: Text('Access Denied or Not logged in')));
    }

    // Reactively watch properties — updates in real-time when Admin assigns a property.
    final propertiesAsync = ref.watch(propertiesStreamProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.ownerPortalTitle),
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: propertiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allProps) {
          final myProps = allProps.where((p) => p.ownerAccountId == user.id).toList();

          if (myProps.isEmpty) {
            return _buildEmptyState();
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.welcomeMessage(user.username), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: -0.5)),
                      const SizedBox(height: 8),
                      Text(l10n.assignedPropertiesCount(myProps.length), style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                      const SizedBox(height: 32),
                      _buildMonthSelector(),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final property = myProps[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _PropertyActivityCard(property: property, month: _selectedMonth),
                      );
                    },
                    childCount: myProps.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.house_siding_outlined, size: 80, color: AppColors.border),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)!.noPropertiesFound, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.noAssignedPropertiesDesc, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            setState(() {
              _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
            });
          },
        ),
        Expanded(
          child: Text(
            DateFormat.yMMMM(Localizations.localeOf(context).languageCode).format(_selectedMonth),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            setState(() {
              _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
            });
          },
        ),
      ],
    );
  }
}

class _PropertyActivityCard extends ConsumerWidget {
  final Property property;
  final DateTime month;

  const _PropertyActivityCard({required this.property, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(monthlyCleaningAssignmentsProvider(property.companyId));
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.primaryLight.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.home_work_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(property.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(property.address, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                // External map launcher
                IconButton(
                  tooltip: AppLocalizations.of(context)!.viewOnMapsTooltip,
                  icon: const Icon(Icons.map_outlined, color: AppColors.textSecondary),
                  onPressed: () async {
                    final q = Uri.encodeComponent('${property.address}, ${property.city}');
                    final url = Uri.parse('https://maps.google.com/?q=\$q');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                )
              ],
            ),
            const SizedBox(height: 24),
            Text(AppLocalizations.of(context)!.cleaningActivityTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            // Internal Job Fetching
            jobsAsync.when(
              data: (allJobs) {
                // Filter jobs for this property & month
                final myJobs = allJobs.where((j) {
                  final jobDate = DateTime.tryParse(j.date);
                  return j.propertyId == property.id &&
                         jobDate != null &&
                         jobDate.year == month.year &&
                         jobDate.month == month.month;
                }).toList();
                
                myJobs.sort((a, b) => b.date.compareTo(a.date));

                if (myJobs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(AppLocalizations.of(context)!.noCleaningsScheduledFor(DateFormat.MMMM(Localizations.localeOf(context).languageCode).format(month)), style: const TextStyle(color: AppColors.textSecondary)),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: myJobs.length,
                  separatorBuilder: (context, index) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final job = myJobs[index];
                    return _JobRow(job: job);
                  },
                );
              },
              loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
              error: (Object e, StackTrace _) => Text(AppLocalizations.of(context)!.errorLoadingActivity(e.toString()), style: const TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  final CleaningAssignment job;
  
  const _JobRow({required this.job});

  @override
  Widget build(BuildContext context) {
    final jobDate = DateTime.tryParse(job.date) ?? DateTime.now();

    Color statusColor;
    IconData statusIcon;
    final String statusStr = job.status.name.toUpperCase().replaceAll('_', ' ');
    
    switch (job.status) {
      case CleaningStatus.approved:
        statusColor = AppColors.teal;
        statusIcon = Icons.verified;
        break;
      case CleaningStatus.fixNeeded:
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        break;
      case CleaningStatus.pendingInspection:
      case CleaningStatus.inProgress:
        statusColor = AppColors.amber;
        statusIcon = Icons.pending;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.assignment_outlined;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(DateFormat.MMM(Localizations.localeOf(context).languageCode).format(jobDate).toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                Text(DateFormat.d(Localizations.localeOf(context).languageCode).format(jobDate), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusStr, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor, letterSpacing: 0.5)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (job.observation.isNotEmpty)
                    Text(AppLocalizations.of(context)!.notePrefix(job.observation), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                  
                  if (job.incidents.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.error),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context)!.incidentsReportedCount(job.incidents.length), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.error)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ...job.incidents.map((inc) => Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('• ${inc.text}', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                            )),
                          ],
                        ),
                      ),
                    ),

                  if (job.findings.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.inspectorFindingsLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          ...job.findings.map((f) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('• ${f.text}', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                          )),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (job.proofPhotos.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context)!.checkoutEvidenceTitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: job.proofPhotos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, idx) {
                final photoB64 = job.proofPhotos[idx];
                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context, 
                      builder: (ctx) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(base64Decode(photoB64), fit: BoxFit.contain),
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(photoB64),
                      width: 140,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
