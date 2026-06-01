import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/environmental_report.dart';
import '../services/report_service.dart';
import '../widgets/region_dropdown_picker.dart';

class ReportPage extends StatefulWidget {
  final VoidCallback? onReportChanged;

  const ReportPage({
    super.key,
    this.onReportChanged,
  });

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  bool _isLoading = true;
  List<EnvironmentalReport> _reports = <EnvironmentalReport>[];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    final reports = await ReportService.instance.loadReports();
    if (!mounted) {
      return;
    }

    setState(() {
      _reports = reports;
      _isLoading = false;
    });
  }

  Future<void> _openCreateReport() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const _CreateReportPage(),
      ),
    );

    if (created == true) {
      widget.onReportChanged?.call();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil disimpan.')),
      );
      await _loadReports();
    }
  }

  Future<void> _deleteReport(EnvironmentalReport report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus laporan?'),
          content: const Text(
            'Laporan yang dihapus tidak akan tampil lagi pada daftar perangkat ini.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await ReportService.instance.removeReportById(report.id);
    widget.onReportChanged?.call();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Laporan dihapus.')),
    );
    await _loadReports();
  }

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Sampah Lingkungan')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateReport,
        backgroundColor: const Color(0xFF1F8A70),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Buat Laporan', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReports,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1F8A70), Color(0xFF35A285)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1F8A70).withOpacity(0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Laporkan Titik Sampah Liar.',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lengkapi foto, kategori, dan lokasi untuk membantu pembersihan lingkungan terkoordinasi.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ReportStatCard(
                          title: 'Total Laporan',
                          value: _reports.length.toString(),
                          icon: Icons.assignment_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ReportStatCard(
                          title: 'Status Aktif',
                          value: _reports.isEmpty ? '0' : _reports.length.toString(),
                          icon: Icons.notifications_active_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_reports.isEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1F8A70).withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFF1F8A70).withOpacity(0.06),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F8A70).withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.assignment_outlined,
                                size: 34,
                                color: Color(0xFF1F8A70),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum ada laporan lingkungan.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1B4D3E),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tekan tombol Buat laporan untuk menambahkan lokasi penumpukan sampah lengkap dengan foto dan detailnya.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF6B8A80),
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._reports.map(
                      (report) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ReportCard(
                          report: report,
                          formattedDate: _formatDateTime(report.createdAt),
                          onDelete: () => _deleteReport(report),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _ReportStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ReportStatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F8A70).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF1F8A70).withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF1F8A70).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF1F8A70),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF8BA69D),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1B4D3E),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final EnvironmentalReport report;
  final String formattedDate;
  final VoidCallback onDelete;

  const _ReportCard({
    required this.report,
    required this.formattedDate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasServerImage = report.imageUrl != null && report.imageUrl!.isNotEmpty;
    final hasLocalImage = report.imagePath != null &&
        report.imagePath!.isNotEmpty &&
        !report.imagePath!.startsWith('http') &&
        File(report.imagePath!).existsSync();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F8A70).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF1F8A70).withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasServerImage)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                report.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            )
          else if (hasLocalImage)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.file(File(report.imagePath!), fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1B4D3E),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _ReportBadge(label: report.status, isStatus: true),
                              _ReportBadge(label: report.urgency, isUrgency: true),
                              _ReportBadge(label: report.category),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      iconColor: const Color(0xFF6B8A80),
                      onSelected: (value) {
                        if (value == 'hapus') {
                          onDelete();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem<String>(
                          value: 'hapus',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 16, color: Color(0xFF1F8A70)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        report.locationName,
                        style: const TextStyle(
                          color: Color(0xFF507A6D),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF8BA69D)),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        color: Color(0xFF8BA69D),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  report.description,
                  style: const TextStyle(
                    color: Color(0xFF1B4D3E),
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportBadge extends StatelessWidget {
  final String label;
  final bool isStatus;
  final bool isUrgency;

  const _ReportBadge({
    required this.label,
    this.isStatus = false,
    this.isUrgency = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFF1F8A70).withOpacity(0.08);
    Color fg = const Color(0xFF1F8A70);

    if (isStatus) {
      bg = const Color(0xFFFFA447).withOpacity(0.1);
      fg = const Color(0xFFFFA447);
    } else if (isUrgency) {
      if (label.toLowerCase() == 'tinggi') {
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
      } else {
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _CreateReportPage extends StatefulWidget {
  const _CreateReportPage();

  @override
  State<_CreateReportPage> createState() => _CreateReportPageState();
}

class _CreateReportPageState extends State<_CreateReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = const [
    'Tumpukan liar',
    'Sampah menutup saluran',
    'Sampah campuran',
    'Area butuh pengangkutan',
    'Sampah organik menumpuk',
    'Sampah anorganik menumpuk',
    'Sampah B3/berbahaya',
    'Limbah elektronik',
    'Limbah cair/selokan tercemar',
    'Bau menyengat',
    'Pembakaran sampah',
    'Tempat sampah penuh/rusak',
    'Fasilitas pengelolaan rusak',
    'Hewan/vektor penyakit',
    'Ranting/daun menumpuk',
    'Lainnya',
  ];
  final List<String> _urgencies = const ['Rendah', 'Sedang', 'Tinggi'];

  String _selectedLocation = '';
  String _selectedCategory = 'Tumpukan liar';
  String _selectedUrgency = 'Sedang';
  File? _selectedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 92,
      maxWidth: 1600,
    );
    if (file == null) {
      return;
    }

    setState(() {
      _selectedImage = File(file.path);
    });
  }

  Future<void> _saveReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto laporan belum dipilih.')),
      );
      return;
    }
    if (_selectedLocation.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih lokasi laporan minimal sampai provinsi.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final report = EnvironmentalReport(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        locationName: _selectedLocation,
        urgency: _selectedUrgency,
        status: 'Menunggu verifikasi',
        createdAt: DateTime.now(),
      );

      await ReportService.instance.addReport(
        report,
        imageFile: _selectedImage,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan laporan: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Laporan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1F8A70).withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFF1F8A70).withOpacity(0.06),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lampirkan Foto Kondisi Lapangan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        ),
                      )
                    else
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF3F0),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(Icons.add_a_photo_outlined, size: 42, color: Color(0xFF6B8A80)),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Kamera'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Galeri'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1F8A70).withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFF1F8A70).withOpacity(0.06),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        labelText: 'Judul Laporan',
                        hintText: 'Contoh: Penumpukan sampah di sudut jalan',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Judul laporan wajib diisi.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Lokasi Laporan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    RegionDropdownPicker(
                      compact: true,
                      initialHelperText:
                          'Pilih bertahap dari provinsi, kabupaten/kota, kecamatan, lalu kelurahan/desa.',
                      onChanged: (selection) {
                        setState(() {
                          _selectedLocation = selection.areaText;
                        });
                      },
                    ),
                    if (_selectedLocation.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F8A70).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.place_outlined, size: 18, color: Color(0xFF1F8A70)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedLocation,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1B4D3E),
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedCategory,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1B4D3E)),
                      decoration: const InputDecoration(
                        labelText: 'Kategori Laporan',
                      ),
                      items: _categories
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedUrgency,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1B4D3E)),
                      decoration: const InputDecoration(
                        labelText: 'Tingkat Urgensi',
                      ),
                      items: _urgencies
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedUrgency = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 4,
                      maxLines: 6,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        labelText: 'Keterangan Laporan',
                        hintText:
                            'Jelaskan kondisi lokasi, jumlah sampah, atau hambatan di lapangan.',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Keterangan laporan wajib diisi.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _saveReport,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1F8A70),
                elevation: 2,
                shadowColor: const Color(0xFF1F8A70).withOpacity(0.2),
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(
                _isSubmitting ? 'Menyimpan laporan...' : 'Kirim Laporan',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
