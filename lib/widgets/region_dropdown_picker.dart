import 'package:flutter/material.dart';

import '../models/region_model.dart';
import '../services/wilayah_service.dart';

class RegionSelection {
  final RegionModel? province;
  final RegionModel? regency;
  final RegionModel? district;
  final RegionModel? village;

  const RegionSelection({
    this.province,
    this.regency,
    this.district,
    this.village,
  });

  String get areaText {
    final parts = <String>[
      if (village != null) village!.name,
      if (district != null) district!.name,
      if (regency != null) regency!.name,
      if (province != null) province!.name,
    ];
    return parts.join(', ');
  }

  bool get hasAnySelection => areaText.isNotEmpty;
}

class RegionDropdownPicker extends StatefulWidget {
  const RegionDropdownPicker({
    super.key,
    required this.onChanged,
    this.compact = false,
    this.initialHelperText,
  });

  final ValueChanged<RegionSelection> onChanged;
  final bool compact;
  final String? initialHelperText;

  @override
  State<RegionDropdownPicker> createState() => _RegionDropdownPickerState();
}

class _RegionDropdownPickerState extends State<RegionDropdownPicker> {
  final WilayahService _wilayahService = WilayahService();

  List<RegionModel> _provinces = [];
  List<RegionModel> _regencies = [];
  List<RegionModel> _districts = [];
  List<RegionModel> _villages = [];

  RegionModel? _selectedProvince;
  RegionModel? _selectedRegency;
  RegionModel? _selectedDistrict;
  RegionModel? _selectedVillage;

  bool _isLoadingProvince = true;
  bool _isLoadingRegency = false;
  bool _isLoadingDistrict = false;
  bool _isLoadingVillage = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    setState(() {
      _isLoadingProvince = true;
      _errorMessage = null;
    });

    try {
      final result = await _wilayahService.getProvinces();
      if (!mounted) return;
      setState(() {
        _provinces = result;
        _isLoadingProvince = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingProvince = false;
        _errorMessage = 'Gagal memuat provinsi. Periksa koneksi internet.';
      });
    }
  }

  void _notifyChanged() {
    widget.onChanged(
      RegionSelection(
        province: _selectedProvince,
        regency: _selectedRegency,
        district: _selectedDistrict,
        village: _selectedVillage,
      ),
    );
  }

  Future<void> _onProvinceChanged(RegionModel? value) async {
    setState(() {
      _selectedProvince = value;
      _selectedRegency = null;
      _selectedDistrict = null;
      _selectedVillage = null;
      _regencies = [];
      _districts = [];
      _villages = [];
      _isLoadingRegency = value != null;
      _errorMessage = null;
    });
    _notifyChanged();

    if (value == null) return;

    try {
      final result = await _wilayahService.getRegencies(value.id);
      if (!mounted) return;
      setState(() {
        _regencies = result;
        _isLoadingRegency = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingRegency = false;
        _errorMessage = 'Gagal memuat kabupaten/kota.';
      });
    }
  }

  Future<void> _onRegencyChanged(RegionModel? value) async {
    setState(() {
      _selectedRegency = value;
      _selectedDistrict = null;
      _selectedVillage = null;
      _districts = [];
      _villages = [];
      _isLoadingDistrict = value != null;
      _errorMessage = null;
    });
    _notifyChanged();

    if (value == null) return;

    try {
      final result = await _wilayahService.getDistricts(value.id);
      if (!mounted) return;
      setState(() {
        _districts = result;
        _isLoadingDistrict = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingDistrict = false;
        _errorMessage = 'Gagal memuat kecamatan.';
      });
    }
  }

  Future<void> _onDistrictChanged(RegionModel? value) async {
    setState(() {
      _selectedDistrict = value;
      _selectedVillage = null;
      _villages = [];
      _isLoadingVillage = value != null;
      _errorMessage = null;
    });
    _notifyChanged();

    if (value == null) return;

    try {
      final result = await _wilayahService.getVillages(value.id);
      if (!mounted) return;
      setState(() {
        _villages = result;
        _isLoadingVillage = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingVillage = false;
        _errorMessage = 'Gagal memuat kelurahan/desa.';
      });
    }
  }

  void _onVillageChanged(RegionModel? value) {
    setState(() {
      _selectedVillage = value;
    });
    _notifyChanged();
  }

  @override
  Widget build(BuildContext context) {
    final gap = widget.compact ? 8.0 : 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.initialHelperText != null) ...[
          Text(
            widget.initialHelperText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          SizedBox(height: gap),
        ],
        _buildDropdown(
          label: 'Provinsi',
          value: _selectedProvince,
          items: _provinces,
          isLoading: _isLoadingProvince,
          onChanged: _onProvinceChanged,
        ),
        SizedBox(height: gap),
        _buildDropdown(
          label: 'Kabupaten/Kota',
          value: _selectedRegency,
          items: _regencies,
          isLoading: _isLoadingRegency,
          onChanged: _selectedProvince == null ? null : _onRegencyChanged,
        ),
        SizedBox(height: gap),
        _buildDropdown(
          label: 'Kecamatan',
          value: _selectedDistrict,
          items: _districts,
          isLoading: _isLoadingDistrict,
          onChanged: _selectedRegency == null ? null : _onDistrictChanged,
        ),
        SizedBox(height: gap),
        _buildDropdown(
          label: 'Kelurahan/Desa',
          value: _selectedVillage,
          items: _villages,
          isLoading: _isLoadingVillage,
          onChanged: _selectedDistrict == null ? null : _onVillageChanged,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required RegionModel? value,
    required List<RegionModel> items,
    required bool isLoading,
    required ValueChanged<RegionModel?>? onChanged,
  }) {
    return DropdownButtonFormField<RegionModel>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: isLoading
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      hint: Text('Pilih $label'),
      items: items
          .map(
            (item) => DropdownMenuItem<RegionModel>(
              value: item,
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: isLoading ? null : onChanged,
    );
  }
}
