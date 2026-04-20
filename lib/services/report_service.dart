import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/environmental_report.dart';

class ReportService {
  ReportService._();

  static final ReportService instance = ReportService._();
  static const _storageKey = 'environmental_reports';

  Future<List<EnvironmentalReport>> loadReports() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_storageKey) ?? <String>[];

    return rawList
        .map((item) {
          try {
            return EnvironmentalReport.fromJson(
              jsonDecode(item) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<EnvironmentalReport>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _saveReports(List<EnvironmentalReport> reports) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      reports.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> addReport(EnvironmentalReport report) async {
    final current = await loadReports();
    current.insert(0, report);
    await _saveReports(current);
  }

  Future<void> removeReportById(String id) async {
    final current = await loadReports();
    final updated = current.where((item) => item.id != id).toList();
    await _saveReports(updated);
  }

  Future<void> clearReports() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
