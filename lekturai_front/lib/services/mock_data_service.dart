import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:lekturai_front/widgets/custom_chart.dart';

class MockDataService {
  static Future<List<ChartDataPoint>> getPointsHistory({
    required TimePeriod period,
  }) async {
    try {
      final String jsonString = await rootBundle.loadString('assets/mock_stats.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      final String key = _getPeriodKey(period);
      final List<dynamic> pointsData = data['pointsHistory'][key] ?? [];
      
      return pointsData.map((item) {
        return ChartDataPoint(
          label: item['label'] as String,
          value: (item['points'] as num).toDouble(),
          date: DateTime.parse(item['date'] as String),
        );
      }).toList();
    } catch (e) {
      print('Błąd podczas ładowania danych: $e');
      return [];
    }
  }

  static Future<List<ChartDataPoint>> getActivityBreakdown() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/mock_stats.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      final List<dynamic> activityData = data['activityBreakdown'] ?? [];
      
      return activityData.map((item) {
        return ChartDataPoint(
          label: item['label'] as String,
          value: (item['value'] as num).toDouble(),
        );
      }).toList();
    } catch (e) {
      print('Błąd podczas ładowania danych aktywności: $e');
      return [];
    }
  }

  static String _getPeriodKey(TimePeriod period) {
    switch (period) {
      case TimePeriod.week:
        return 'last7Days';
      case TimePeriod.twoWeeks:
        return 'last14Days';
      case TimePeriod.month:
        return 'last30Days';
    }
  }

  static Future<double> getTotalPoints({required TimePeriod period}) async {
    final points = await getPointsHistory(period: period);
    return points.fold<double>(0.0, (sum, point) => sum + point.value);
  }

  static Future<double> getAveragePoints({required TimePeriod period}) async {
    final points = await getPointsHistory(period: period);
    if (points.isEmpty) return 0.0;
    final total = points.fold<double>(0.0, (sum, point) => sum + point.value);
    return total / points.length;
  }

  static Future<ChartDataPoint> getBestDay({required TimePeriod period}) async {
    final points = await getPointsHistory(period: period);
    if (points.isEmpty) {
      return ChartDataPoint(label: '-', value: 0);
    }
    
    return points.reduce((curr, next) => 
      curr.value > next.value ? curr : next
    );
  }
}
