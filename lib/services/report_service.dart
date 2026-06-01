import 'dart:io';

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

  /// Sends a new report to the backend.
  ///
  /// [report] contains the report metadata.
  /// [imageFile] is the optional photo File to upload as multipart.
  Future<void> addReport(
    EnvironmentalReport report, {
    File? imageFile,
  }) async {
    final fields = <String, String>{
      'title': report.title,
      'description': report.description,
      'category': report.category,
      'location_name': report.locationName,
      'urgency': report.urgency,
      'reported_at': report.createdAt.toIso8601String(),
    };

    await ApiClient.instance.postMultipart(
      '/mobile/reports',
      fields: fields,
      file: imageFile,
      fileFieldName: 'image',
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
