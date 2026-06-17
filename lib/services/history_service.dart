import 'dart:async';

import '../models/classification_result.dart';
import '../models/history_entry.dart';
import 'api_client.dart';
import 'local_queue_service.dart';

class HistoryService {
  HistoryService._();

  static final HistoryService instance = HistoryService._();

  Future<void>? _syncFuture;

  Future<List<DetectionHistoryItem>> loadHistory() async {
    // Sync dulu supaya item yang baru saja ditambahkan ikut muncul di
    // hasil fetch remote di bawah (bukan baru muncul di refresh berikutnya).
    await syncPending();

    List<DetectionHistoryItem> remote = [];
    bool isOnline = false;

    try {
      final response = await ApiClient.instance.get('/mobile/classifications');
      final payload = response as Map<String, dynamic>;
      remote = (payload['data'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(DetectionHistoryItem.fromApiJson)
          .toList();
      isOnline = true;
    } on ApiException catch (error) {
      if (error.statusCode == 401) return [];
    } catch (_) {
      // Network error - gunakan data lokal
    }

    if (!isOnline) {
      final pending = await LocalQueueService.instance.getAll();
      return pending..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    // Baca sisa antrian setelah sync:
    // - item yang berhasil sync sudah dihapus dari antrian
    // - yang tersisa hanya item yang gagal sync (tidak ada di remote)
    // → tidak mungkin overlap dengan remote, aman digabungkan
    final remaining = await LocalQueueService.instance.getAll();

    return [...remaining, ...remote]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Simpan ke antrian lokal, lalu coba kirim ke backend.
  /// Kalau gagal (offline), data tetap di antrian untuk di-sync nanti.
  Future<void> addHistory(DetectionHistoryItem item) async {
    await LocalQueueService.instance.add(item);
    unawaited(syncPending());
  }

  /// Upload semua item yang pending ke backend.
  /// Dijaga dengan lock supaya panggilan yang tumpang tindih (misal dari
  /// addHistory() dan loadHistory() yang terpicu hampir bersamaan) tidak
  /// sama-sama membaca antrian dan mem-POST item yang sama dua kali.
  Future<void> syncPending() {
    return _syncFuture ??= _runSyncPending().whenComplete(() {
      _syncFuture = null;
    });
  }

  Future<void> _runSyncPending() async {
    final pending = await LocalQueueService.instance.getAll();
    for (final item in pending) {
      try {
        await ApiClient.instance.post(
          '/mobile/classifications',
          body: _toApiBody(item),
        );
        await LocalQueueService.instance.remove(item.id);
      } catch (_) {
        return; // Masih offline, hentikan
      }
    }
  }

  Future<void> removeHistoryByIds(Set<String> ids) async {
    if (ids.isEmpty) return;

    // Hapus dari antrian lokal
    for (final id in ids) {
      await LocalQueueService.instance.remove(id);
    }

    // Item lokal memiliki ID berformat 'path|datetime'; remote ID tidak mengandung '|'
    final remoteIds = ids.where((id) => !id.contains('|')).toSet();
    if (remoteIds.isEmpty) return;

    try {
      await ApiClient.instance.delete(
        '/mobile/classifications',
        body: {'ids': remoteIds.toList()},
      );
    } catch (_) {
      // Offline — remote delete gagal, local sudah dihapus
    }
  }

  Future<void> clearHistory() async {
    await LocalQueueService.instance.clear();
    try {
      await ApiClient.instance.delete('/mobile/classifications');
    } catch (_) {}
  }

  Map<String, dynamic> _toApiBody(DetectionHistoryItem item) => {
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
  };
}
