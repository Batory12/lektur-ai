import 'package:flutter/material.dart';
import 'package:lekturai_front/services/stats_service.dart';
import 'package:lekturai_front/theme/colors.dart';
import 'package:lekturai_front/theme/spacing.dart';
import 'package:lekturai_front/theme/text_styles.dart';
import 'package:lekturai_front/widgets/custom_chart.dart';

/// Example screen showing how to use the CustomChart widget
class StatsExampleScreen extends StatefulWidget {
  const StatsExampleScreen({super.key});

  @override
  State<StatsExampleScreen> createState() => _StatsExampleScreenState();
}

class _StatsExampleScreenState extends State<StatsExampleScreen> {
  final StatsService _statsService = StatsService();
  TimePeriod _selectedPeriod = TimePeriod.week;
  bool _isLoading = true;

  List<ChartDataPoint> _pointsData = [];
  List<ChartDataPoint> _cumulativeData = [];
  List<ChartDataPoint> _activityData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _statsService.getPointsHistory(period: _selectedPeriod),
      _statsService.getCumulativePoints(period: _selectedPeriod),
      _statsService.getActivityBreakdown(),
    ]);

    if (mounted) {
      setState(() {
        _pointsData = results[0];
        _cumulativeData = results[1];
        _activityData = results[2];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statystyki'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppSpacing.screenPaddingAll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period selector
                  _buildPeriodSelector(),
                  const SizedBox(height: AppSpacing.lg),

                  // Bar Chart - Points per day
                  CustomChart(
                    title: 'Zdobyte punkty',
                    data: _pointsData,
                    chartType: ChartType.bar,
                    primaryColor: AppColors.primary,
                    secondaryColor: AppColors.primaryLight,
                    showGrid: true,
                    showValues: true,
                    yAxisLabel: 'Punkty',
                    xAxisLabel: _selectedPeriod == TimePeriod.week ? 'Dni tygodnia' : 'Data',
                    tooltipBuilder: (point) =>
                        '${point.label}\n${point.value.toInt()} pkt',
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Line Chart - Cumulative points
                  CustomChart(
                    title: 'Skumulowane punkty',
                    data: _cumulativeData,
                    chartType: ChartType.line,
                    primaryColor: AppColors.success,
                    showGrid: true,
                    showValues: false,
                    curvedLine: true,
                    showDots: true,
                    fillUnderLine: true,
                    yAxisLabel: 'Łączne punkty',
                    xAxisLabel: _selectedPeriod == TimePeriod.week ? 'Dni tygodnia' : 'Data',
                    tooltipBuilder: (point) =>
                        'Do ${point.label}\n${point.value.toInt()} pkt',
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Pie Chart - Activity breakdown
                  CustomChart(
                    title: 'Podział aktywności',
                    data: _activityData,
                    chartType: ChartType.pie,
                    showValues: true,
                    height: 350,
                    tooltipBuilder: (point) =>
                        '${point.label}: ${point.value.toInt()} zadań',
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Example: Custom styled bar chart
                  CustomChart(
                    title: 'Aktywność dzienna (niestandardowe kolory)',
                    data: _generateColorfulData(),
                    chartType: ChartType.bar,
                    showGrid: false,
                    showValues: false,
                    barWidth: 20,
                    yAxisLabel: 'Liczba zadań',
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Example: Simple line chart
                  CustomChart(
                    title: 'Trend punktów (prosta linia)',
                    data: _pointsData,
                    chartType: ChartType.line,
                    primaryColor: AppColors.error,
                    curvedLine: false,
                    showDots: false,
                    showGrid: true,
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Okres czasu',
              style: AppTextStyles.heading4,
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<TimePeriod>(
              segments: TimePeriod.values.map((period) {
                return ButtonSegment<TimePeriod>(
                  value: period,
                  label: Text(period.label),
                );
              }).toList(),
              selected: {_selectedPeriod},
              onSelectionChanged: (Set<TimePeriod> newSelection) {
                setState(() {
                  _selectedPeriod = newSelection.first;
                });
                _loadData();
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primary;
                  }
                  return AppColors.white;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.white;
                  }
                  return AppColors.primary;
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Generate sample data with custom colors
  List<ChartDataPoint> _generateColorfulData() {
    return [
      ChartDataPoint(label: 'Pn', value: 5, color: Colors.red),
      ChartDataPoint(label: 'Wt', value: 8, color: Colors.orange),
      ChartDataPoint(label: 'Śr', value: 12, color: Colors.yellow.shade700),
      ChartDataPoint(label: 'Cz', value: 6, color: Colors.green),
      ChartDataPoint(label: 'Pt', value: 15, color: Colors.blue),
      ChartDataPoint(label: 'So', value: 3, color: Colors.indigo),
      ChartDataPoint(label: 'Nd', value: 2, color: Colors.purple),
    ];
  }
}
