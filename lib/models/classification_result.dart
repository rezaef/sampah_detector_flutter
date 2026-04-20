enum WasteCategory { organik, anorganik, tidakDiketahui }

class ClassificationResult {
  final WasteCategory category;
  final double confidence;
  final Map<String, double> scores;
  final bool isDemo;
  final String engine;
  final int latencyMs;

  const ClassificationResult({
    required this.category,
    required this.confidence,
    required this.scores,
    required this.isDemo,
    required this.engine,
    required this.latencyMs,
  });

  String get label {
    switch (category) {
      case WasteCategory.organik:
        return 'Organik';
      case WasteCategory.anorganik:
        return 'Anorganik';
      case WasteCategory.tidakDiketahui:
        return 'Tidak diketahui';
    }
  }

  String get recommendation {
    switch (category) {
      case WasteCategory.organik:
        return 'Pisahkan ke wadah organik atau olah sebagai kompos.';
      case WasteCategory.anorganik:
        return 'Pisahkan ke wadah anorganik lalu siapkan untuk didaur ulang.';
      case WasteCategory.tidakDiketahui:
        return 'Ambil ulang gambar dengan pencahayaan yang lebih merata.';
    }
  }

  List<String> get disposalSteps {
    switch (category) {
      case WasteCategory.organik:
        return const [
          'Pisahkan dari plastik, logam, dan kaca sebelum dibuang.',
          'Kurangi kadar air berlebih agar wadah tidak cepat bau.',
          'Gunakan jalur kompos rumah tangga atau tempat sampah organik.',
        ];
      case WasteCategory.anorganik:
        return const [
          'Bilas sisa cairan atau minyak sebelum disimpan.',
          'Keringkan dan lipat kemasan untuk menghemat ruang.',
          'Setorkan ke bank sampah atau wadah daur ulang terdekat.',
        ];
      case WasteCategory.tidakDiketahui:
        return const [
          'Pastikan objek terlihat utuh di tengah frame kamera.',
          'Gunakan cahaya yang cukup dan latar belakang lebih bersih.',
          'Coba scan ulang dari sudut yang lebih jelas.',
        ];
    }
  }

  String get confidenceLabel => '${(confidence * 100).toStringAsFixed(1)}%';

  ClassificationResult copyWith({
    WasteCategory? category,
    double? confidence,
    Map<String, double>? scores,
    bool? isDemo,
    String? engine,
    int? latencyMs,
  }) {
    return ClassificationResult(
      category: category ?? this.category,
      confidence: confidence ?? this.confidence,
      scores: scores ?? this.scores,
      isDemo: isDemo ?? this.isDemo,
      engine: engine ?? this.engine,
      latencyMs: latencyMs ?? this.latencyMs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category.name,
      'confidence': confidence,
      'scores': scores,
      'isDemo': isDemo,
      'engine': engine,
      'latencyMs': latencyMs,
    };
  }

  factory ClassificationResult.fromJson(Map<String, dynamic> json) {
    final rawScores = json['scores'];
    final parsedScores = <String, double>{};

    if (rawScores is Map) {
      rawScores.forEach((key, value) {
        parsedScores[key.toString()] = (value as num).toDouble();
      });
    }

    final rawCategory = json['category']?.toString() ?? 'tidakDiketahui';
    final category = WasteCategory.values.firstWhere(
      (item) => item.name == rawCategory,
      orElse: () => WasteCategory.tidakDiketahui,
    );

    return ClassificationResult(
      category: category,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      scores: parsedScores,
      isDemo: json['isDemo'] as bool? ?? false,
      engine: json['engine']?.toString() ?? 'unknown',
      latencyMs: (json['latencyMs'] as num?)?.toInt() ?? 0,
    );
  }
}
