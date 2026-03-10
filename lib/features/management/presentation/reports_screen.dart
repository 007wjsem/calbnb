import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../calendar/data/cleaning_repository.dart';
import '../../calendar/domain/cleaning_assignment.dart';
import '../../admin/data/property_repository.dart';
import '../../admin/domain/property.dart';
import '../../../core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(allCleaningAssignmentsProvider);
    final propertiesAsync = ref.watch(allPropertiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
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
            Text(
              'Weekly Reports',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Generate itemized cleaning reports for turnover billing and records.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _ReportActionCard(
              title: 'Last Week Cleaning Report',
              subtitle: 'Excel document with property details, fees, and manager observations.',
              icon: Icons.table_view_rounded,
              color: AppColors.teal,
              onTap: () => _generateLastWeekReport(context, ref, assignmentsAsync, propertiesAsync),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateLastWeekReport(
    BuildContext context, 
    WidgetRef ref, 
    AsyncValue<List<CleaningAssignment>> assignmentsAsync,
    AsyncValue<List<Property>> propertiesAsync,
  ) async {
    final assignments = assignmentsAsync.valueOrNull;
    final properties = propertiesAsync.valueOrNull;

    if (assignments == null || properties == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data is still loading, please try again in a moment.')),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final now = DateTime.now();
      DateTime getMonday(DateTime date) {
        return date.subtract(Duration(days: date.weekday - 1));
      }
      final thisMonday = getMonday(now);
      final lastMonday = thisMonday.subtract(const Duration(days: 7));
      final DateFormat df = DateFormat('yyyy-MM-dd');

      bool isLastWeek(String dateStr) {
        final date = df.parse(dateStr);
        return (date.isAtSameMomentAs(lastMonday) || date.isAfter(lastMonday)) && 
               date.isBefore(thisMonday);
      }

      final lastWeekApproved = assignments.where((a) => 
        a.status == CleaningStatus.approved && isLastWeek(a.date)
      ).toList();

      if (lastWeekApproved.isEmpty) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No approved cleanings found for last week.')),
        );
        return;
      }

      // Create Excel
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Report'];
      excel.delete('Sheet1'); // Remove default sheet

      // Add Headers
      final List<String> headers = [
        'Date', 
        'Property Management', 
        'Property Owner', 
        'Observations', 
        'Property Name & Address', 
        'Cleaning Fee', 
        'Size'
      ];
      
      sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());

      // Add Data
      for (final a in lastWeekApproved) {
        final property = properties.where((p) => p.id == a.propertyId).firstOrNull ?? 
                         properties.where((p) => p.name == a.propertyId).firstOrNull;
        
        if (property == null) continue;

        // Owner logic: "if it has a property owner here should show private, otherwise, shows the owner name"
        // Interpreting as: if ownerName is not empty, label it "Private"
        final String ownerDisp = property.ownerName.isNotEmpty ? 'Private' : property.ownerName;

        // Combine manager observations with cleaner reported incidents
        String observationsCombined = a.observation;
        if (a.incidents.isNotEmpty) {
          final String incidentText = a.incidents.map((i) => '- ${i.category}: ${i.text}').join('\n');
          if (observationsCombined.isNotEmpty) {
            observationsCombined += '\n\nIncidents Reported:\n$incidentText';
          } else {
            observationsCombined = 'Incidents Reported:\n$incidentText';
          }
        }

        sheetObject.appendRow([
          TextCellValue(a.date),
          TextCellValue(property.propertyManagement),
          TextCellValue(ownerDisp),
          TextCellValue(observationsCombined),
          TextCellValue('${property.name}\n${property.address}'),
          DoubleCellValue(property.cleaningFee),
          TextCellValue(property.size),
        ]);
      }

      // Save file
      final String fileName = 'Cleaning_Report_${DateFormat('yyyyMMdd').format(lastMonday)}.xlsx';
      final List<int>? fileBytes = excel.save();
      
      if (fileBytes != null) {
        if (kIsWeb) {
          // Web: Use XFile.fromData to trigger download/share without path_provider
          final xFile = XFile.fromData(
            Uint8List.fromList(fileBytes),
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            name: fileName,
          );
          
          Navigator.pop(context); // Close loading
          await Share.shareXFiles([xFile], subject: 'Cleaning Report $fileName');
        } else {
          // Mobile/Desktop: Use path_provider and dart:io
          final directory = await getTemporaryDirectory();
          final String filePath = '${directory.path}/$fileName';
          
          File(filePath)
            ..createSync(recursive: true)
            ..writeAsBytesSync(fileBytes);

          Navigator.pop(context); // Close loading
          
          await Share.shareXFiles(
            [XFile(filePath)],
            subject: 'Cleaning Report $fileName',
          );
        }
      } else {
        throw Exception('Failed to generate Excel content.');
      }

    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    }
  }
}

class _ReportActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ReportActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
