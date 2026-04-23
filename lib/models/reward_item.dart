int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

bool _toBool(dynamic value, {bool fallback = true}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  final raw = value.toString().trim().toLowerCase();
  if (raw == '1' || raw == 'true' || raw == 'yes') return true;
  if (raw == '0' || raw == 'false' || raw == 'no') return false;
  return fallback;
}

class RewardItem {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final int? stock;
  final bool isActive;

  const RewardItem({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.stock,
    required this.isActive,
  });

  bool get isOutOfStock => stock != null && stock! <= 0;

  factory RewardItem.fromApiJson(Map<String, dynamic> json) {
    return RewardItem(
      id: json['id']?.toString() ?? '',
      title: (json['title'] ?? 'Reward').toString(),
      description: (json['description'] ?? '').toString(),
      pointsCost: _toInt(json['points_cost']),
      stock: json['stock'] == null ? null : _toInt(json['stock']),
      isActive: _toBool(json['is_active']),
    );
  }
}
