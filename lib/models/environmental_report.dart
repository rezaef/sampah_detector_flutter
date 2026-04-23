class EnvironmentalReport {
  final String id;
  final String title;
  final String description;
  final String category;
  final String locationName;
  final String urgency;
  final String status;
  final String? imagePath;
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
      createdAt: DateTime.tryParse(
            (json['reported_at'] ?? json['created_at'] ?? '').toString(),
          ) ??
          DateTime.now(),
    );
  }
}
