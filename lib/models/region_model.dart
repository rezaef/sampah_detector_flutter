class RegionModel {
  final String id;
  final String name;

  const RegionModel({
    required this.id,
    required this.name,
  });

  factory RegionModel.fromJson(Map<String, dynamic> json) {
    return RegionModel(
      id: json['id'].toString(),
      name: json['name'].toString(),
    );
  }
}
