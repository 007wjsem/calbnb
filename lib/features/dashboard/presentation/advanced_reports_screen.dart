import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../calendar/data/cleaning_repository.dart';
import '../../company/domain/subscription.dart';
import '../../company/presentation/subscription_guard.dart';
import '../../calendar/data/cleaning_repository.dart';
import '../../calendar/domain/cleaning_assignment.dart';
import '../../admin/data/property_repository.dart';
import '../../admin/domain/property.dart';
import '../../admin/data/user_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/server_time_provider.dart';
import '../../company/presentation/currency_provider.dart';
import 'package:calbnb/l10n/app_localizations.dart';

class AdvancedReportsScreen extends ConsumerWidget {
  const AdvancedReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.advancedReportsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SubscriptionGuard(
        requiredTier: SubscriptionTier.diamond,
        child: const _ReportsBody(),
      ),
    );
  }
}

class _ReportsBody extends ConsumerStatefulWidget {
  const _ReportsBody();

  @override
  ConsumerState<_ReportsBody> createState() => _ReportsBodyState();
}

class _ReportsBodyState extends ConsumerState<_ReportsBody> {
  int? _selectedYear;
  bool _isYearlyView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final serverTime = ref.read(currentServerTimeProvider);
      setState(() {
        _selectedYear = serverTime.year;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(allCleaningAssignmentsProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return assignmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object e, StackTrace _) => Center(child: Text(AppLocalizations.of(context)!.genericError(e.toString()))),
      data: (allAssignments) {
        if (_selectedYear == null) return const Center(child: CircularProgressIndicator());
        return FutureBuilder<_AnalyticsData>(
          future: _computeAnalytics(ref, allAssignments, _selectedYear!, _isYearlyView),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError || snap.data == null) {
              return Center(child: Text(AppLocalizations.of(context)!.genericError(snap.error.toString())));
            }
            final data = snap.data!;
            return _buildDashboard(context, data, currencySymbol);
          },
        );
      },
    );
  }

  Widget _buildDashboard(BuildContext context, _AnalyticsData data, String currencySymbol) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.advancedAnalyticsTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    Text(AppLocalizations.of(context)!.diamondTierReportingLabel(_selectedYear!), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: false, label: Text('6 Months')),
                      ButtonSegment(value: true, label: Text('12 Months')),
                    ],
                    selected: {_isYearlyView},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() => _isYearlyView = newSelection.first);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _selectedYear = (_selectedYear ?? 0) - 1)),
                      Text('${_selectedYear ?? ''}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: (_selectedYear ?? 0) < ref.read(currentServerTimeProvider).year ? () => setState(() => _selectedYear = (_selectedYear ?? 0) + 1) : null,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── KPI Cards ──────────────────────────────────────────────
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _KpiCard(label: AppLocalizations.of(context)!.totalCleaningsLabel, value: '${data.totalCleanings}', icon: Icons.cleaning_services, color: AppColors.primary),
              _KpiCard(label: AppLocalizations.of(context)!.totalRevenueLabel,   value: '$currencySymbol${data.totalRevenue.toStringAsFixed(0)}', icon: Icons.attach_money, color: AppColors.green),
              _KpiCard(label: AppLocalizations.of(context)!.totalPayrollLabel,   value: '$currencySymbol${data.totalPayroll.toStringAsFixed(0)}', icon: Icons.payments_outlined, color: AppColors.amber),
              _KpiCard(label: AppLocalizations.of(context)!.netMarginLabel,      value: '$currencySymbol${(data.totalRevenue - data.totalPayroll).toStringAsFixed(0)}', icon: Icons.trending_up, color: AppColors.teal),
            ],
          ),
          const SizedBox(height: 32),

          // ── Monthly Cleanings Bar Chart ─────────────────────────────
          _SectionHeader(title: AppLocalizations.of(context)!.monthlyCleaningsTitle, subtitle: AppLocalizations.of(context)!.monthlyCleaningsDesc),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: data.monthlyCounts.every((v) => v == 0)
                ? Center(child: Text(AppLocalizations.of(context)!.noCleaningDataForYear, style: const TextStyle(color: AppColors.textSecondary)))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (data.monthlyCounts.reduce((a, b) => a > b ? a : b) + 2).toDouble(),
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < 0 || value.toInt() >= data.monthLabels.length) return const SizedBox();
                            return Text(
                              data.monthLabels[value.toInt()],
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            );
                          },
                          reservedSize: 28,
                        )),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: 5)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border.withOpacity(0.5), strokeWidth: 1)),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(data.monthlyCounts.length, (i) => BarChartGroupData(
                        x: i,
                        barRods: [BarChartRodData(
                          toY: data.monthlyCounts[i].toDouble(),
                          color: AppColors.primary,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        )],
                      )),
                    ),
                  ),
          ),
          const SizedBox(height: 32),

          // ── Monthly Revenue Line Chart ──────────────────────────────
          _SectionHeader(title: AppLocalizations.of(context)!.revenueVsPayrollTitle, subtitle: AppLocalizations.of(context)!.revenueVsPayrollDesc),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0, maxX: (data.monthlyCounts.length - 1).toDouble(),
                minY: 0,
                maxY: ([...data.monthlyRevenue, ...data.monthlyPayroll].isEmpty ? 100
                    : [...data.monthlyRevenue, ...data.monthlyPayroll].reduce((a, b) => a > b ? a : b) * 1.2),
                lineTouchData: LineTouchData(enabled: true, touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                    '$currencySymbol${s.y.toStringAsFixed(0)}',
                    TextStyle(color: s.bar.color, fontWeight: FontWeight.bold),
                  )).toList(),
                )),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < 0 || value.toInt() >= data.monthLabels.length) return const SizedBox();
                      final monthStr = data.monthLabels[value.toInt()];
                      return Text(
                        monthStr.isNotEmpty ? monthStr[0] : '',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      );
                    },
                    reservedSize: 24,
                  )),
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) => Text(
                      '$currencySymbol${value.toInt()}',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  )),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border.withOpacity(0.4), strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Revenue line
                  LineChartBarData(
                    spots: List.generate(data.monthlyRevenue.length, (i) => FlSpot(i.toDouble(), data.monthlyRevenue[i])),
                    isCurved: true,
                    color: AppColors.green,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: AppColors.green.withOpacity(0.08)),
                  ),
                  // Payroll line
                  LineChartBarData(
                    spots: List.generate(data.monthlyPayroll.length, (i) => FlSpot(i.toDouble(), data.monthlyPayroll[i])),
                    isCurved: true,
                    color: AppColors.amber,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: AppColors.amber.withOpacity(0.08)),
                  ),
                ],
              ),
            ),
          ),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppColors.green, label: AppLocalizations.of(context)!.revenueLabel),
              const SizedBox(width: 24),
              _LegendDot(color: AppColors.amber, label: AppLocalizations.of(context)!.payrollLabel),
            ],
          ),
          const SizedBox(height: 32),

          // ── Cleaner Efficiency Table ────────────────────────────────
          _SectionHeader(title: AppLocalizations.of(context)!.cleanerPerformanceTitle, subtitle: AppLocalizations.of(context)!.cleanerPerformanceDesc),
          const SizedBox(height: 16),
          if (data.cleanerStats.isEmpty)
            Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(AppLocalizations.of(context)!.noCleanerDataForYear, style: const TextStyle(color: AppColors.textSecondary))))
          else
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.border)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Table(
                    defaultColumnWidth: const IntrinsicColumnWidth(),
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: AppColors.surface),
                      children: [
                        AppLocalizations.of(context)!.cleanerHeader,
                        AppLocalizations.of(context)!.jobsHeader,
                        AppLocalizations.of(context)!.revenueHeader,
                        AppLocalizations.of(context)!.payrollHeader,
                        AppLocalizations.of(context)!.marginHeader
                      ].map((h) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(h, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5)),
                      )).toList(),
                    ),
                    ...data.cleanerStats.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final s = entry.value;
                      final margin = s.revenue - s.payrollCost;
                      final isPositive = margin >= 0;
                      return TableRow(
                        decoration: BoxDecoration(color: idx.isEven ? Colors.white : AppColors.surface.withOpacity(0.5)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(radius: 14, backgroundColor: AppColors.primary.withOpacity(0.1), child: Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold))),
                                const SizedBox(width: 8),
                                Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                          ),
                          _TableCell(text: '${s.jobCount}'),
                          _TableCell(text: '$currencySymbol${s.revenue.toStringAsFixed(0)}', color: AppColors.green),
                          _TableCell(text: '$currencySymbol${s.payrollCost.toStringAsFixed(0)}', color: AppColors.amber),
                          _TableCell(
                            text: '${isPositive ? '+' : ''}$currencySymbol${margin.toStringAsFixed(0)}',
                            color: isPositive ? AppColors.green : AppColors.error,
                            bold: true,
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<_AnalyticsData> _computeAnalytics(WidgetRef ref, List<CleaningAssignment> allAssignments, int year, bool isYearlyView) async {
    final properties = await ref.read(propertyRepositoryProvider).fetchAll();
    final users = await ref.read(userRepositoryProvider).fetchAll();

    final userById = {for (var u in users) u.id: u};

    // Filter to this year + approved/completed jobs
    final yearJobs = allAssignments.where((j) {
      final date = DateTime.tryParse(j.date);
      return date != null && date.year == year && (j.status == CleaningStatus.approved || j.status == CleaningStatus.pendingInspection);
    }).toList();

    final now = ref.read(currentServerTimeProvider);
    final endMonth = year == now.year ? now.month : 12;

    final numMonths = isYearlyView ? 12 : 6;
    final monthlyCounts = List.filled(numMonths, 0);
    final monthlyRevenue = List.filled(numMonths, 0.0);
    final monthlyPayroll = List.filled(numMonths, 0.0);
    final List<String> monthLabels = [];

    if (isYearlyView) {
      for (int i = 0; i < 12; i++) {
        monthLabels.add(DateFormat.MMM().format(DateTime(year, i + 1, 1)));
      }
    } else {
      for (int i = 0; i < 6; i++) {
        monthLabels.add(DateFormat.MMM().format(DateTime(year, endMonth - 5 + i, 1)));
      }
    }

    final Map<String, _CleanerStat> cleanerMap = {};
    
    double totalYearlyRevenue = 0.0;
    double totalYearlyPayroll = 0.0;

    for (final job in yearJobs) {
      final date = DateTime.parse(job.date);
      
      // Compute property cleanup fee correctly, with fallback for robust matching
      final searchProp = job.propertyId.trim().toLowerCase();
      Property? jobProp = properties.where((p) => p.id == job.propertyId).firstOrNull;
      
      if (jobProp == null) {
        jobProp = properties.where((p) {
          final propName = p.name.trim().toLowerCase();
          final propIdStr = p.id.trim().toLowerCase();
          final syncId = p.syncId.trim().toLowerCase();
          return propName == searchProp || propIdStr == searchProp ||
                 propName.contains(searchProp) || searchProp.contains(propName) ||
                 (syncId.isNotEmpty && (syncId == searchProp || searchProp.contains(syncId)));
        }).firstOrNull;
      }
      
      double fee = job.propertyCleaningFee;
      if (fee <= 0) {
        fee = jobProp?.cleaningFee ?? 0.0;
      }
          
      totalYearlyRevenue += fee;

      // Map to chart array indices
      int chartIdx;
      if (isYearlyView) {
        chartIdx = date.month - 1;
      } else {
        int monthsDiff = (year - date.year) * 12 + (endMonth - date.month);
        if (monthsDiff >= 0 && monthsDiff < 6) {
           chartIdx = 5 - monthsDiff;
        } else {
           chartIdx = -1;
        }
      }

      if (chartIdx >= 0 && chartIdx < numMonths) {
         monthlyCounts[chartIdx]++;
         monthlyRevenue[chartIdx] += fee;
      }

      // Aggregate payroll and individual cleaner stats
      for (final cl in job.cleaners) {
        double cleanerPay = cl.fee;
        // Fallback for assignments without explicit fees (e.g. legacy or auto-calculated)
        if (cleanerPay <= 0 && fee > 0) {
          cleanerPay = (fee * 0.70) / job.cleaners.length;
        }

        totalYearlyPayroll += cleanerPay;
        if (chartIdx >= 0 && chartIdx < numMonths) {
          monthlyPayroll[chartIdx] += cleanerPay;
        }

        cleanerMap.putIfAbsent(cl.id, () => _CleanerStat(id: cl.id, name: cl.name));
        cleanerMap[cl.id]!.jobCount++;
        cleanerMap[cl.id]!.revenue += fee; // Revenue attributed to each cleaner who worked on the property
        cleanerMap[cl.id]!.payrollCost += cleanerPay;
      }
    }

    final cleanerStats = cleanerMap.values.toList()..sort((a, b) => b.revenue.compareTo(a.revenue));

    return _AnalyticsData(
      totalCleanings: yearJobs.length,
      totalRevenue: totalYearlyRevenue,
      totalPayroll: totalYearlyPayroll,
      monthlyCounts: monthlyCounts,
      monthlyRevenue: monthlyRevenue,
      monthlyPayroll: monthlyPayroll,
      monthLabels: monthLabels,
      cleanerStats: cleanerStats,
    );
  }
}

// ── Data Models ────────────────────────────────────────────────────────────────

class _AnalyticsData {
  final int totalCleanings;
  final double totalRevenue;
  final double totalPayroll;
  final List<int> monthlyCounts;
  final List<double> monthlyRevenue;
  final List<double> monthlyPayroll;
  final List<String> monthLabels;
  final List<_CleanerStat> cleanerStats;

  _AnalyticsData({
    required this.totalCleanings,
    required this.totalRevenue,
    required this.totalPayroll,
    required this.monthlyCounts,
    required this.monthlyRevenue,
    required this.monthlyPayroll,
    required this.monthLabels,
    required this.cleanerStats,
  });
}

class _CleanerStat {
  final String id;
  final String name;
  int jobCount = 0;
  double revenue = 0;
  double payrollCost = 0;
  _CleanerStat({required this.id, required this.name});
}

// ── Widget Helpers ─────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final Color? color;
  final bool bold;

  const _TableCell({required this.text, this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
          color: color ?? AppColors.textPrimary,
        ),
      ),
    );
  }
}
