import 'classification_result.dart';

class DetectionHistoryItem {
  final String imagePath;
  final ClassificationResult result;
  final DateTime createdAt;

  const DetectionHistoryItem({
    required this.imagePath,
    required this.result,
    required this.createdAt,
  });

  String get id => '$imagePath|${createdAt.toIso8601String()}';

  Map<String, dynamic> toJson() {
    return {
      'imagePath': imagePath,
      'result': result.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DetectionHistoryItem.fromJson(Map<String, dynamic> json) {
    final rawResult = json['result'];
    return DetectionHistoryItem(
      imagePath: json['imagePath']?.toString() ?? '',
      result: ClassificationResult.fromJson(
        rawResult is Map<String, dynamic>
            ? rawResult
            : Map<String, dynamic>.from(rawResult as Map),
      ),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
