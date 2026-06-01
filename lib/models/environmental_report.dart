class EnvironmentalReport {
  final String id;
  final String title;
  final String description;
  final String category;
  final String locationName;
  final String urgency;
  final String status;
  /// Local file path (before upload) OR null after synced with server.
  final String? imagePath;
  /// Full URL from server (e.g. http://10.0.2.2:8000/storage/reports/xxx.jpg)
  final String? imageUrl;
  final DateTime createdAt;

  const EnvironmentalReport({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.locationName,
    required this.urgency,
    required this.status,
    required this.createdAt,
    this.imagePath,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'locationName': locationName,
      'urgency': urgency,
      'status': status,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EnvironmentalReport.fromJson(Map<String, dynamic> json) {
    return EnvironmentalReport(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Laporan lingkungan',
      locationName: json['locationName']?.toString() ?? '',
      urgency: json['urgency']?.toString() ?? 'Sedang',
      status: json['status']?.toString() ?? 'Menunggu verifikasi',
      imagePath: json['imagePath']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  factory EnvironmentalReport.fromApiJson(Map<String, dynamic> json) {
    return EnvironmentalReport(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Laporan lingkungan',
      locationName: json['location_name']?.toString() ?? '',
      urgency: json['urgency']?.toString() ?? 'Sedang',
      status: json['status']?.toString() ?? 'Menunggu verifikasi',
      imagePath: json['image_path']?.toString(),
      imageUrl: json['image_url']?.toString(),
      createdAt: DateTime.tryParse(
            (json['reported_at'] ?? json['created_at'] ?? '').toString(),
          ) ??
          DateTime.now(),
    );
  }
}
