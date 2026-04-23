import '../models/classification_result.dart';
import '../models/history_entry.dart';
import 'api_client.dart';

enum HistoryDeleteMode { single, selected, all }

class HistoryService {
  HistoryService._();

  static final HistoryService instance = HistoryService._();

  Future<List<DetectionHistoryItem>> loadHistory() async {
    try {
      final response = await ApiClient.instance.get('/mobile/classifications');
      final payload = response as Map<String, dynamic>;
      final rawItems = (payload['data'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList();

      return rawItems
          .map(DetectionHistoryItem.fromApiJson)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        return [];
      }
      rethrow;
    }
  }

  Future<void> addHistory(DetectionHistoryItem item) async {
    await ApiClient.instance.post(
      '/mobile/classifications',
      body: {
        'image_path': item.imagePath,
        'category': switch (item.result.category) {
          WasteCategory.organik => 'organik',
          WasteCategory.anorganik => 'anorganik',
          WasteCategory.tidakDiketahui => 'tidak_diketahui',
        },
        'confidence': item.result.confidence,
        'organic_score': item.result.scores['organik'] ?? 0,
        'anorganic_score': item.result.scores['anorganik'] ?? 0,
        'unknown_score': item.result.scores['tidak_diketahui'] ?? 0,
        'engine': item.result.engine,
        'latency_ms': item.result.latencyMs,
        'detected_at': item.createdAt.toIso8601String(),
      },
    );
  }

  Future<void> removeHistoryByIds(Set<String> ids) async {
    if (ids.isEmpty) {
      return;
    }

    await ApiClient.instance.delete(
      '/mobile/classifications',
      body: {'ids': ids.toList()},
    );
  }

  Future<void> clearHistory() async {
    await ApiClient.instance.delete('/mobile/classifications');
  }
}
