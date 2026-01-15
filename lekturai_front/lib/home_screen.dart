import 'package:flutter/material.dart';
import 'package:lekturai_front/api/stats.dart';
import 'package:lekturai_front/services/stats_service.dart';
import 'package:lekturai_front/tools/weekdays.dart';
import 'package:lekturai_front/widgets/common_scaffold.dart';
import 'package:lekturai_front/widgets/custom_chart.dart';
import 'package:lekturai_front/services/mock_data_service.dart';
import 'package:lekturai_front/theme/colors.dart';
import 'package:lekturai_front/theme/spacing.dart';
import 'package:lekturai_front/theme/text_styles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ChartDataPoint> _chartData = [];
  bool _isLoading = true;
  double _totalPoints = 0.0;
  int _currentStreak = 0;
  ChartDataPoint? _bestDay;
  TimePeriod _selectedPeriod = TimePeriod.week;
  ChartType _selectedChartType = ChartType.bar;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await StatsService().getPointsHistory(
        period: _selectedPeriod,
      );

      final userStats = await StatsService().getUserStats();
      
      print('=== USER STATS DEBUG ===');
      print('UserStats is null: ${userStats == null}');
      if (userStats != null) {
        print('Current Streak: ${userStats.currentStreak}');
        print('Longest Streak: ${userStats.longestStreak}');
        print('Points: ${userStats.points}');
        print('Total Tasks Done: ${userStats.totalTasksDone}');
        print('Last Task Date: ${userStats.lastTaskDate}');
        print('Doc ID: ${userStats.docId}');
      }
      print('======================');

      setState(() {
        _chartData = data;
        _bestDay = data.isNotEmpty
            ? data.reduce((a, b) => a.value >= b.value ? a : b)
            : null;
        _totalPoints = userStats?.points.toDouble() ?? 0.0;
        _currentStreak = userStats?.currentStreak ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas ładowania danych: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onPeriodChanged(TimePeriod? newPeriod) {
    if (newPeriod != null && newPeriod != _selectedPeriod) {
      setState(() {
        _selectedPeriod = newPeriod;
      });
      _loadData();
    }
  }

  List<TimePeriod> _getAvailablePeriods() {
    if (_selectedChartType == ChartType.bar) {
      // Bar charts support different periods based on screen width
      final screenWidth = MediaQuery.of(context).size.width;

      // Calculate available horizontal space for the chart
      // Account for screen padding (32px total) and card padding (32px total)
      final chartWidth = screenWidth - 64;

      // Each bar needs ~40px of space (16px bar + 24px spacing)
      final barSpaceNeeded = 40;

      // Calculate how many bars can fit
      final maxBars = (chartWidth / barSpaceNeeded).floor();

      if (maxBars >= 30) {
        // Wide screens (tablets/desktop) can show all periods
        return TimePeriod.values;
      } else if (maxBars >= 14) {
        // Medium screens can show up to 14 days
        return [TimePeriod.week, TimePeriod.twoWeeks];
      } else {
        // Small screens can only show 7 days
        return [TimePeriod.week];
      }
    }
    // Line charts support all periods regardless of screen width
    return TimePeriod.values;
  }

  void _onChartTypeChanged(ChartType newType) {
    if (newType == _selectedChartType) return;

    // Temporarily update chart type to calculate available periods
    final tempChartType = newType;
    final previousChartType = _selectedChartType;
    final previousPeriod = _selectedPeriod;
    _selectedChartType = tempChartType;

    // Get available periods for the new chart type
    final availablePeriods = _getAvailablePeriods();

    // Restore previous chart type before setState
    _selectedChartType = previousChartType;

    // Determine the new period (keep current if available, otherwise use longest available)
    final newPeriod = availablePeriods.contains(previousPeriod)
        ? previousPeriod
        : availablePeriods.last;

    // Now update with both chart type and period
    setState(() {
      _selectedChartType = tempChartType;
      _selectedPeriod = newPeriod;
    });

    // Reload data if period changed
    if (newPeriod != previousPeriod) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: 'Strona Główna',
      showDrawer: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppSpacing.screenPaddingAll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Text('Twoje statystyki', style: AppTextStyles.heading1),
                  const SizedBox(height: AppSpacing.sm),

                  // Period Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Chart Type Selector
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButton<ChartType>(
                              value: _selectedChartType,
                              underline: const SizedBox(),
                              isDense: true,
                              items: const [
                                DropdownMenuItem<ChartType>(
                                  value: ChartType.bar,
                                  child: Row(
                                    children: [
                                      Icon(Icons.bar_chart, size: 16),
                                      SizedBox(width: 8),
                                      Text('Słupkowy'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem<ChartType>(
                                  value: ChartType.line,
                                  child: Row(
                                    children: [
                                      Icon(Icons.show_chart, size: 16),
                                      SizedBox(width: 8),
                                      Text('Liniowy'),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (ChartType? newType) {
                                if (newType != null) {
                                  _onChartTypeChanged(newType);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          // Period Selector
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButton<TimePeriod>(
                              value: _selectedPeriod,
                              underline: const SizedBox(),
                              isDense: true,
                              items: _getAvailablePeriods().map((period) {
                                return DropdownMenuItem<TimePeriod>(
                                  value: period,
                                  child: Text(
                                    period.label,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                );
                              }).toList(),
                              onChanged: _onPeriodChanged,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Łącznie Punktów',
                          value: _totalPoints.toInt().toString(),
                          icon: Icons.star,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Ilość dni nauki z rzędu',
                          value: '$_currentStreak',
                          icon: Icons.trending_up,
                          color: AppColors.successLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildStatCard(
                    title: 'Najlepszy dzień',
                    value: '${getFullWeekdayName(_bestDay?.label ?? '')}: ${_bestDay?.value.toInt() ?? 0} pkt',
                    icon: Icons.emoji_events,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: AppSpacing.sectionSpacing),

                  // Bar Chart
                  CustomChart(
                    key: ValueKey(
                      '${_selectedChartType.name}_${_selectedPeriod.days}',
                    ),
                    title:
                        'Punkty zdobyte - ${_selectedPeriod.label.toLowerCase()}',
                    data: _chartData,
                    chartType: _selectedChartType,
                    height: 300,
                    primaryColor: AppColors.primary,
                    showGrid: true,
                    showValues: true,
                    enableAnimation: true,
                  ),

                  const SizedBox(height: AppSpacing.sectionSpacing),

                  // Quick Actions
                  Text('Szybkie akcje', style: AppTextStyles.heading2),
                  const SizedBox(height: AppSpacing.lg),
                  _buildQuickActionButton(
                    context,
                    title: 'Zadania z lektur',
                    icon: Icons.book,
                    color: AppColors.primary,
                    onTap: () => showReadingPicker(context),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildQuickActionButton(
                    context,
                    title: 'Zadania maturalne',
                    icon: Icons.school,
                    color: AppColors.successLight,
                    onTap: () => Navigator.pushNamed(context, '/zmatur'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildQuickActionButton(
                    context,
                    title: 'Asystent rozprawki',
                    icon: Icons.edit_document,
                    color: Colors.orange,
                    onTap: () => Navigator.pushNamed(context, '/rozprawka'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: AppSpacing.cardPaddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(title, style: AppTextStyles.bodySmall)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: AppTextStyles.heading2.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: AppSpacing.cardPaddingAll,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.greyMedium,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
