import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lekturai_front/theme/colors.dart';
import 'package:lekturai_front/theme/spacing.dart';
import 'package:lekturai_front/theme/text_styles.dart';

/// Enum for chart types
enum ChartType {
  bar,
  line,
}

/// Enum for time periods
enum TimePeriod {
  week(7, 'Ostatnie 7 dni'),
  twoWeeks(14, 'Ostatnie 14 dni'),
  month(30, 'Ostatnie 30 dni');

  final int days;
  final String label;

  const TimePeriod(this.days, this.label);
}

/// Data point for charts
class ChartDataPoint {
  final String label; // e.g., "Pn", "01.12", or category name
  final double value;
  final DateTime? date; // Optional date for time-based charts
  final Color? color; // Optional custom color for this data point

  ChartDataPoint({
    required this.label,
    required this.value,
    this.date,
    this.color,
  });
}

/// Custom Chart Widget that can display bar, line, or pie charts
class CustomChart extends StatelessWidget {
  /// Chart title
  final String title;

  /// Chart data points
  final List<ChartDataPoint> data;

  /// Type of chart to display
  final ChartType chartType;

  /// Primary color for the chart (used for bars, lines, etc.)
  final Color primaryColor;

  /// Secondary color (used for gradients, highlights, etc.)
  final Color? secondaryColor;

  /// Background color of the chart area
  final Color? backgroundColor;

  /// Show grid lines
  final bool showGrid;

  /// Show values on data points
  final bool showValues;

  /// Enable animation
  final bool enableAnimation;

  /// Minimum Y value (null for auto)
  final double? minY;

  /// Maximum Y value (null for auto)
  final double? maxY;

  /// Y-axis label (e.g., "Punkty")
  final String? yAxisLabel;

  /// X-axis label (e.g., "Dni")
  final String? xAxisLabel;

  /// Height of the chart
  final double height;

  /// Enable chart interaction (tooltips, etc.)
  final bool enableInteraction;

  /// Custom tooltip builder
  final String Function(ChartDataPoint)? tooltipBuilder;

  /// Bar width (for bar charts)
  final double barWidth;

  /// Line curve (for line charts)
  final bool curvedLine;

  /// Show dots on line (for line charts)
  final bool showDots;

  /// Fill area under line (for line charts)
  final bool fillUnderLine;

  const CustomChart({
    super.key,
    required this.title,
    required this.data,
    this.chartType = ChartType.bar,
    this.primaryColor = AppColors.primary,
    this.secondaryColor,
    this.backgroundColor,
    this.showGrid = true,
    this.showValues = true,
    this.enableAnimation = true,
    this.minY,
    this.maxY,
    this.yAxisLabel,
    this.xAxisLabel,
    this.height = 300,
    this.enableInteraction = true,
    this.tooltipBuilder,
    this.barWidth = 16,
    this.curvedLine = true,
    this.showDots = true,
    this.fillUnderLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: 0,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              title,
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Chart
            SizedBox(
              height: height,
              child: _buildChart(),
            ),

            // Labels
            if (xAxisLabel != null || yAxisLabel != null) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (yAxisLabel != null)
                    Text(
                      yAxisLabel!,
                      style: AppTextStyles.bodySmall,
                    ),
                  if (xAxisLabel != null)
                    Text(
                      xAxisLabel!,
                      style: AppTextStyles.bodySmall,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'Brak danych do wyświetlenia',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.greyMedium,
          ),
        ),
      );
    }

    switch (chartType) {
      case ChartType.bar:
        return _buildBarChart();
      case ChartType.line:
        return _buildLineChart();
    }
  }

  Widget _buildBarChart() {
    // Safety check: ensure we have data
    if (data.isEmpty) {
      return Center(
        child: Text(
          'Brak danych do wyświetlenia',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.greyMedium,
          ),
        ),
      );
    }

    final maxValue = maxY ?? data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minValue = minY ?? 0;
    
    // Prevent division by zero - use minimum value of 10 if maxValue is 0 or too small
    final safeMaxValue = maxValue < 0.1 ? 10.0 : maxValue;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: safeMaxValue * 1.1, // Add 10% padding
        minY: minValue,
        barTouchData: BarTouchData(
          enabled: enableInteraction,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.transparent,
            tooltipPadding: EdgeInsets.zero,
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              // Safety check: ensure index is within bounds
              if (groupIndex < 0 || groupIndex >= data.length) return null;
              final dataPoint = data[groupIndex];
              final tooltipText = tooltipBuilder?.call(dataPoint) ??
                  dataPoint.value.toStringAsFixed(0);
              return BarTooltipItem(
                tooltipText,
                AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                // Safety check: ensure index is within bounds
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    data[index].label,
                    style: AppTextStyles.bodySmall,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: AppTextStyles.bodySmall,
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: showGrid,
          drawVerticalLine: false,
          horizontalInterval: safeMaxValue / 5,  // Changed from maxValue to safeMaxValue
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.border,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: AppColors.border, width: 1),
            left: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        barGroups: data.asMap().entries.map((entry) {
          final index = entry.key;
          final dataPoint = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: dataPoint.value,
                color: dataPoint.color ?? primaryColor,
                width: barWidth,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                gradient: secondaryColor != null
                    ? LinearGradient(
                        colors: [primaryColor, secondaryColor!],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      )
                    : null,
              ),
            ],
            showingTooltipIndicators: showValues ? [0] : [],
          );
        }).toList(),
      ),
      swapAnimationDuration: enableAnimation
          ? const Duration(milliseconds: 300)
          : Duration.zero,
    );
  }

  Widget _buildLineChart() {
    // Safety check: ensure we have data
    if (data.isEmpty) {
      return Center(
        child: Text(
          'Brak danych do wyświetlenia',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.greyMedium,
          ),
        ),
      );
    }

    final maxValue = maxY ?? data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minValue = minY ?? 0;
    
    // Prevent division by zero - use minimum value of 10 if maxValue is 0 or too small
    final safeMaxValue = maxValue < 0.1 ? 10.0 : maxValue;

    return LineChart(
      LineChartData(
        maxY: safeMaxValue * 1.1,  // Changed from maxValue to safeMaxValue
        minY: minValue,
        lineTouchData: LineTouchData(
          enabled: enableInteraction,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                // Safety check: ensure index is within bounds
                if (index < 0 || index >= data.length) {
                  return null;
                }
                final dataPoint = data[index];
                final tooltipText = tooltipBuilder?.call(dataPoint) ??
                    '${dataPoint.label}\n${dataPoint.value.toStringAsFixed(0)}';
                return LineTooltipItem(
                  tooltipText,
                  AppTextStyles.bodySmall.copyWith(color: AppColors.white),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: data.length > 10 ? (data.length / 7).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                // Safety check: ensure index is within bounds
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    data[index].label,
                    style: AppTextStyles.bodySmall,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: AppTextStyles.bodySmall,
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: showGrid,
          drawVerticalLine: false,
          horizontalInterval: safeMaxValue / 5,  // Changed from maxValue to safeMaxValue
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.border,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: AppColors.border, width: 1),
            left: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.value);
            }).toList(),
            isCurved: curvedLine,
            color: primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: showDots),
            belowBarData: BarAreaData(
              show: fillUnderLine,
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.3),
                  primaryColor.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
      duration: enableAnimation
          ? const Duration(milliseconds: 300)
          : Duration.zero,
    );
  }
}
