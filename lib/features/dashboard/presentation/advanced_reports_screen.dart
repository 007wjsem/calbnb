import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/auth_repository.dart';
import '../../company/data/company_repository.dart';
import '../../company/domain/subscription.dart';
import '../../company/presentation/subscription_guard.dart';
import '../../calendar/data/cleaning_repository.dart';
import '../../calendar/domain/cleaning_assignment.dart';
import '../../admin/data/property_repository.dart';
import '../../admin/data/user_repository.dart';
import '../../../core/theme/app_colors.dart';
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
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(allCleaningAssignmentsProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return assignmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object e, StackTrace _) => Center(child: Text(AppLocalizations.of(context)!.genericError(e.toString()))),
      data: (allAssignments) {
        return FutureBuilder<_AnalyticsData>(
          future: _computeAnalytics(ref, allAssignments, _selectedYear),
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
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.advancedAnalyticsTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  Text(AppLocalizations.of(context)!.diamondTierReportingLabel(_selectedYear), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
              // Year Picker
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _selectedYear--)),
                  Text('$_selectedYear', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _selectedYear < DateTime.now().year ? () => setState(() => _selectedYear++) : null,
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
                            final date = DateTime(2000, value.toInt() + 1);
                            final monthStr = DateFormat.MMM(Localizations.localeOf(context).languageCode).format(date);
                            return Text(
                              monthStr,
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
                      barGroups: List.generate(12, (i) => BarChartGroupData(
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
                minX: 0, maxX: 11,
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
                      final date = DateTime(2000, value.toInt() + 1);
                      final monthStr = DateFormat.MMM(Localizations.localeOf(context).languageCode).format(date);
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
                    spots: List.generate(12, (i) => FlSpot(i.toDouble(), data.monthlyRevenue[i])),
                    isCurved: true,
                    color: AppColors.green,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: AppColors.green.withOpacity(0.08)),
                  ),
                  // Payroll line
                  LineChartBarData(
                    spots: List.generate(12, (i) => FlSpot(i.toDouble(), data.monthlyPayroll[i])),
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
                child: Table(
                  columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1), 4: FlexColumnWidth(1)},
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
                            child: Row(children: [
                              CircleAvatar(radius: 14, backgroundColor: AppColors.primary.withOpacity(0.1), child: Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold))),
                              const SizedBox(width: 8),
                              Flexible(child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
                            ]),
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
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<_AnalyticsData> _computeAnalytics(WidgetRef ref, List<CleaningAssignment> allAssignments, int year) async {
    final properties = await ref.read(propertyRepositoryProvider).fetchAll();
    final users = await ref.read(userRepositoryProvider).fetchAll();

    // Build lookups
    final propFeeById = {for (var p in properties) p.id: p.cleaningFee};
    final propFeeByName = {for (var p in properties) p.name: p.cleaningFee};
    final userById = {for (var u in users) u.id: u};

    // Filter to this year + approved/completed jobs
    final yearJobs = allAssignments.where((j) {
      final date = DateTime.tryParse(j.date);
      return date != null && date.year == year && (j.status == CleaningStatus.approved || j.status == CleaningStatus.pendingInspection);
    }).toList();

    final monthlyCounts = List.filled(12, 0);
    final monthlyRevenue = List.filled(12, 0.0);
    final monthlyPayroll = List.filled(12, 0.0);
    final Map<String, _CleanerStat> cleanerMap = {};

    for (final job in yearJobs) {
      final date = DateTime.parse(job.date);
      final month = date.month - 1;
      final fee = propFeeById[job.propertyId] ?? propFeeByName[job.propertyId] ?? 0.0;
      final user = userById[job.cleanerId];
      final payRate = user?.payRate ?? 0.0;

      monthlyCounts[month]++;
      monthlyRevenue[month] += fee;
      monthlyPayroll[month] += payRate;

      cleanerMap.putIfAbsent(job.cleanerId, () => _CleanerStat(id: job.cleanerId, name: job.cleanerName));
      cleanerMap[job.cleanerId]!.jobCount++;
      cleanerMap[job.cleanerId]!.revenue += fee;
      cleanerMap[job.cleanerId]!.payrollCost += payRate;
    }

    final cleanerStats = cleanerMap.values.toList()..sort((a, b) => b.revenue.compareTo(a.revenue));

    return _AnalyticsData(
      totalCleanings: yearJobs.length,
      totalRevenue: monthlyRevenue.fold(0, (a, b) => a + b),
      totalPayroll: monthlyPayroll.fold(0, (a, b) => a + b),
      monthlyCounts: monthlyCounts,
      monthlyRevenue: monthlyRevenue,
      monthlyPayroll: monthlyPayroll,
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
  final List<_CleanerStat> cleanerStats;

  _AnalyticsData({
    required this.totalCleanings,
    required this.totalRevenue,
    required this.totalPayroll,
    required this.monthlyCounts,
    required this.monthlyRevenue,
    required this.monthlyPayroll,
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
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
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
