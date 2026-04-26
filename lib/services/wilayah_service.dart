import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/region_model.dart';

class WilayahService {
  static const String _baseUrl =
      'https://emsifa.github.io/api-wilayah-indonesia/api';

  Future<List<RegionModel>> getProvinces() async {
    final response = await http.get(Uri.parse('$_baseUrl/provinces.json'));
    return _parseList(response);
  }

  Future<List<RegionModel>> getRegencies(String provinceId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/regencies/$provinceId.json'),
    );
    return _parseList(response);
  }

  Future<List<RegionModel>> getDistricts(String regencyId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/districts/$regencyId.json'),
    );
    return _parseList(response);
  }

  Future<List<RegionModel>> getVillages(String districtId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/villages/$districtId.json'),
    );
    return _parseList(response);
  }

  List<RegionModel> _parseList(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil data wilayah. Kode: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Format data wilayah tidak sesuai.');
    }

    return decoded
        .map((item) => RegionModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
