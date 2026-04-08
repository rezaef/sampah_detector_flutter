import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/history_entry.dart';

class HistoryService {
  HistoryService._();

  static final HistoryService instance = HistoryService._();
  static const _storageKey = 'waste_detection_history';

  Future<List<DetectionHistoryItem>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_storageKey) ?? <String>[];

    return rawList
        .map((item) {
          try {
            return DetectionHistoryItem.fromJson(
              jsonDecode(item) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<DetectionHistoryItem>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _saveHistory(List<DetectionHistoryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      items.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }

  Future<void> addHistory(DetectionHistoryItem item) async {
    final current = await loadHistory();
    current.insert(0, item);

    final trimmed = current.take(30).toList();
    await _saveHistory(trimmed);
  }

  Future<void> removeHistoryByIds(Set<String> ids) async {
    if (ids.isEmpty) {
      return;
    }

    final current = await loadHistory();
    final updated = current.where((entry) => !ids.contains(entry.id)).toList();
    await _saveHistory(updated);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
