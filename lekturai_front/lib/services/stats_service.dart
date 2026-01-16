import 'package:firebase_auth/firebase_auth.dart';
import 'package:lekturai_front/api/stats.dart';
import 'package:lekturai_front/widgets/custom_chart.dart';

// Export UserStats for easy access
export 'package:lekturai_front/api/stats.dart' show UserStats;

class StatsService {
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
      
      // FIXED: Added await keyword
      final userPointsHistory = await _statsApi.getUserDailyStats(currentUser!.uid);
      
      // Convert UserDailyStats to ChartDataPoint
      final chartData = <ChartDataPoint>[];
      
      int counter = 0;
      for (final stat in userPointsHistory) {
        // Parse the date from doc_id if it contains date information
        // Otherwise, use a sequential approach
        final date = now.subtract(Duration(days: userPointsHistory.length - 1 - counter));
        final dayOfWeek = _getDayLabel(date.weekday);
        
        final label = period == TimePeriod.week
          ? dayOfWeek
          : '${date.day}.${date.month}';

        chartData.add(ChartDataPoint(
          label: label,
          value: stat.points.toDouble(),
          date: date,
        ));
        counter++;
      }

      // Filter to only include the latest days from the specified period
      final latestData = chartData.length <= period.days
          ? chartData
          : chartData.skip(chartData.length - period.days).toList();

      print(latestData);

      return latestData;
    } catch (e) {
      print('Błąd podczas pobierania historii punktów: $e');
      return [];
    }
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

  /// Get user statistics (streaks, total tasks, points, etc.)
  Future<UserStats?> getUserStats() async {
    if (currentUser == null) return null;

    try {
      final userStats = await _statsApi.getUserStats(currentUser!.uid);
      return userStats;
    } catch (e) {
      print('Błąd podczas pobierania statystyk użytkownika: $e');
      return null;
    }
  }

  /// Get school average points over a time period
  Future<List<ChartDataPoint>> getSchoolStats({
    required TimePeriod period,
    required String schoolName,
    required String city,
  }) async {
    try {
      final now = DateTime.now();
      
      final schoolAvgHistory = await _statsApi.getAvgSchoolDaily(
        schoolName: schoolName,
        city: city,
      );
      
      // Convert AvgDailyStats to ChartDataPoint
      final chartData = <ChartDataPoint>[];
      
      int counter = 0;
      for (final stat in schoolAvgHistory) {
        final date = now.subtract(Duration(days: schoolAvgHistory.length - 1 - counter));
        final dayOfWeek = _getDayLabel(date.weekday);
        
        final label = period == TimePeriod.week
          ? dayOfWeek
          : '${date.day}.${date.month}';

        chartData.add(ChartDataPoint(
          label: label,
          value: stat.avgPoints,
          date: date,
        ));
        counter++;
      }

      // Filter to only include the latest days from the specified period
      final latestData = chartData.length <= period.days
          ? chartData
          : chartData.skip(chartData.length - period.days).toList();

      return latestData;
    } catch (e) {
      print('Błąd podczas pobierania średniej szkolnej: $e');
      return [];
    }
  }

  /// Get class average points over a time period
  Future<List<ChartDataPoint>> getClassStats({
    required TimePeriod period,
    required String schoolName,
    required String city,
    required String className,
  }) async {
    try {
      final now = DateTime.now();
      
      final classAvgHistory = await _statsApi.getAvgClassDaily(
        schoolName: schoolName,
        city: city,
        className: className,
      );
      
      // Convert AvgDailyStats to ChartDataPoint
      final chartData = <ChartDataPoint>[];
      
      int counter = 0;
      for (final stat in classAvgHistory) {
        final date = now.subtract(Duration(days: classAvgHistory.length - 1 - counter));
        final dayOfWeek = _getDayLabel(date.weekday);
        
        final label = period == TimePeriod.week
          ? dayOfWeek
          : '${date.day}.${date.month}';

        chartData.add(ChartDataPoint(
          label: label,
          value: stat.avgPoints,
          date: date,
        ));
        counter++;
      }

      // Filter to only include the latest days from the specified period
      final latestData = chartData.length <= period.days
          ? chartData
          : chartData.skip(chartData.length - period.days).toList();

      return latestData;
    } catch (e) {
      print('Błąd podczas pobierania średniej klasowej: $e');
      return [];
    }
  }

}
