import '../models/environmental_report.dart';
import 'api_client.dart';

class ReportService {
  ReportService._();

  static final ReportService instance = ReportService._();

  Future<List<EnvironmentalReport>> loadReports() async {
    try {
      final response = await ApiClient.instance.get('/mobile/reports');
      final payload = response as Map<String, dynamic>;
      final rawItems = (payload['data'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList();

      return rawItems
          .map(EnvironmentalReport.fromApiJson)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        return [];
      }
      rethrow;
    }
  }

  Future<void> addReport(EnvironmentalReport report) async {
    await ApiClient.instance.post(
      '/mobile/reports',
      body: {
        'title': report.title,
        'description': report.description,
        'category': report.category,
        'location_name': report.locationName,
        'urgency': report.urgency,
        'image_path': report.imagePath,
        'reported_at': report.createdAt.toIso8601String(),
      },
    );
  }

  Future<void> removeReportById(String id) async {
    await ApiClient.instance.delete('/mobile/reports/$id');
  }

  Future<void> clearReports() async {
    final items = await loadReports();
    for (final item in items) {
      await removeReportById(item.id);
    }
  }
}
