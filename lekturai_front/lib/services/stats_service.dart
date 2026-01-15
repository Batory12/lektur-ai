import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lekturai_front/api/stats.dart';
import 'package:lekturai_front/widgets/custom_chart.dart';

class StatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StatsApi _statsApi = StatsApi();

  User? get currentUser => _auth.currentUser;

  /// Get points earned over a time period
  Future<List<ChartDataPoint>> getPointsHistory({
    required TimePeriod period,
  }) async {
    if (currentUser == null) return [];

    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: period.days));
      
      // FIXED: Added await keyword
      final userPointsHistory = await _statsApi.getUserDailyStats(currentUser!.uid);
      
      // Convert UserDailyStats to ChartDataPoint
      final chartData = <ChartDataPoint>[];
      
      int counter = 0;
      for (final stat in userPointsHistory) {
        // Parse the date from doc_id if it contains date information
        // Otherwise, use a sequential approach
        final String month = stat.docId.substring(5, 7);
        final String day = stat.docId.substring(8, 10);
        final date = DateTime.now().subtract(Duration(days: userPointsHistory.length - 1 - counter));
        final dayOfWeek = _getDayLabel(date.weekday);
        
        final label = period == TimePeriod.week
          ? dayOfWeek
          : '${date.day}.${date.month}';

        chartData.add(ChartDataPoint(
          label: label,
          value: 9.0,
          date: date,
        ));
        counter++;
      }

      // Filter to only include the latest days from the specified period
      final latestData = chartData.skip(chartData.length - period.days).toList();

      print(latestData);

      return latestData;
    } catch (e) {
      print('Błąd podczas pobierania historii punktów: $e');
      return [];
    }
  }

  /// Generate mock data for testing
  List<ChartDataPoint> _generateMockPointsData(TimePeriod period) {
    final now = DateTime.now();
    final data = <ChartDataPoint>[];

    for (int i = period.days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayOfWeek = _getDayLabel(date.weekday);
      final label = period == TimePeriod.week
          ? dayOfWeek
          : '${date.day}.${date.month}';

      // Generate random points (replace with actual data)
      final points = (i % 3 == 0) ? (20 + (i % 5) * 10).toDouble() : (10 + (i % 7) * 5).toDouble();

      data.add(ChartDataPoint(
        label: label,
        value: points,
        date: date,
      ));
    }

    return data;
  }

  String _getDayLabel(int weekday) {
    switch (weekday) {
      case 1:
        return 'Pn';
      case 2:
        return 'Wt';
      case 3:
        return 'Śr';
      case 4:
        return 'Cz';
      case 5:
        return 'Pt';
      case 6:
        return 'So';
      case 7:
        return 'Nd';
      default:
        return '';
    }
  }

  /// Get activity breakdown (for pie chart)
  Future<List<ChartDataPoint>> getActivityBreakdown() async {
    if (currentUser == null) return [];

    try {
      // TODO: Replace with actual Firestore query
      // Example:
      // final snapshot = await _firestore
      //     .collection('users')
      //     .doc(currentUser!.uid)
      //     .collection('activities')
      //     .get();

      // For now, return mock data
      return [
        ChartDataPoint(label: 'Lektury', value: 45),
        ChartDataPoint(label: 'Matura', value: 30),
        ChartDataPoint(label: 'Rozprawki', value: 25),
      ];
    } catch (e) {
      print('Błąd podczas pobierania podziału aktywności: $e');
      return [];
    }
  }

  /// Get cumulative points over time (for line chart with fill)
  Future<List<ChartDataPoint>> getCumulativePoints({
    required TimePeriod period,
  }) async {
    final pointsHistory = await getPointsHistory(period: period);
    
    final cumulativeData = <ChartDataPoint>[];
    double cumulative = 0;

    for (final point in pointsHistory) {
      cumulative += point.value;
      cumulativeData.add(ChartDataPoint(
        label: point.label,
        value: cumulative,
        date: point.date,
      ));
    }

    return cumulativeData;
  }

  /// Get comparison data (current vs previous period)
  Future<Map<String, List<ChartDataPoint>>> getComparisonData({
    required TimePeriod period,
  }) async {
    if (currentUser == null) return {};

    try {
      final now = DateTime.now();
      final currentStart = now.subtract(Duration(days: period.days));
      final previousStart = currentStart.subtract(Duration(days: period.days));

      // TODO: Implement actual Firestore queries for both periods
      // For now, return mock data
      final currentData = await getPointsHistory(period: period);
      final previousData = _generateMockPreviousPeriodData(period);

      return {
        'current': currentData,
        'previous': previousData,
      };
    } catch (e) {
      print('Błąd podczas pobierania danych porównawczych: $e');
      return {};
    }
  }

  List<ChartDataPoint> _generateMockPreviousPeriodData(TimePeriod period) {
    final now = DateTime.now();
    final data = <ChartDataPoint>[];

    for (int i = period.days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i + period.days));
      final dayOfWeek = _getDayLabel(date.weekday);
      final label = period == TimePeriod.week
          ? dayOfWeek
          : '${date.day}.${date.month}';

      // Generate slightly lower random points for previous period
      final points = (i % 3 == 0) ? (15 + (i % 5) * 8).toDouble() : (8 + (i % 7) * 4).toDouble();

      data.add(ChartDataPoint(
        label: label,
        value: points,
        date: date,
      ));
    }

    return data;
  }
}
