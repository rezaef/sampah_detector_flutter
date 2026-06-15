import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/history_entry.dart';

class LocalQueueService {
  LocalQueueService._();

  static final LocalQueueService instance = LocalQueueService._();

  static const _key = 'local_history_queue';

  Future<List<DetectionHistoryItem>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final items = <DetectionHistoryItem>[];
    for (final s in raw) {
      try {
        items.add(
          DetectionHistoryItem.fromJson(
            jsonDecode(s) as Map<String, dynamic>,
          ),
        );
      } catch (_) {}
    }
    return items;
  }

  Future<void> add(DetectionHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode(item.toJson()));
    await prefs.setStringList(_key, raw);
  }

  Future<void> remove(String localId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final updated = raw.where((s) {
      try {
        final item = DetectionHistoryItem.fromJson(
          jsonDecode(s) as Map<String, dynamic>,
        );
        return item.id != localId;
      } catch (_) {
        return true;
      }
    }).toList();
    await prefs.setStringList(_key, updated);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
