import 'classification_result.dart';

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

class DetectionHistoryItem {
  final String? remoteId;
  final String imagePath;
  final ClassificationResult result;
  final DateTime createdAt;

  const DetectionHistoryItem({
    this.remoteId,
    required this.imagePath,
    required this.result,
    required this.createdAt,
  });

  String get id =>
      remoteId != null && remoteId!.isNotEmpty
          ? remoteId!
          : '$imagePath|${createdAt.toIso8601String()}';

  Map<String, dynamic> toJson() {
    return {
      'id': remoteId,
      'imagePath': imagePath,
      'result': result.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DetectionHistoryItem.fromJson(Map<String, dynamic> json) {
    final rawResult = json['result'];
    return DetectionHistoryItem(
      remoteId: json['id']?.toString(),
      imagePath: (json['imagePath'] ?? '').toString(),
      result: ClassificationResult.fromJson(
        rawResult is Map<String, dynamic>
            ? rawResult
            : Map<String, dynamic>.from(rawResult as Map),
      ),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  factory DetectionHistoryItem.fromApiJson(Map<String, dynamic> json) {
    final category = (json['category'] ?? 'tidak_diketahui').toString();
    return DetectionHistoryItem(
      remoteId: json['id']?.toString(),
      imagePath: (json['image_path'] ?? '').toString(),
      result: ClassificationResult(
        category: switch (category) {
          'organik' => WasteCategory.organik,
          'anorganik' => WasteCategory.anorganik,
          _ => WasteCategory.tidakDiketahui,
        },
        confidence: _toDouble(json['confidence']),
        scores: {
          'organik': _toDouble(json['organic_score']),
          'anorganik': _toDouble(json['anorganic_score']),
          'tidak_diketahui': _toDouble(json['unknown_score']),
        },
        isDemo: false,
        engine: (json['engine'] ?? 'custom-model').toString(),
        latencyMs: _toInt(json['latency_ms']),
      ),
      createdAt: DateTime.tryParse(
            (json['detected_at'] ?? json['created_at'] ?? '').toString(),
          ) ??
          DateTime.now(),
    );
  }
}
