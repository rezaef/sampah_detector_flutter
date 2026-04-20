import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/environmental_report.dart';
import '../services/report_service.dart';
import '../services/storage_service.dart';

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
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Buat laporan'),
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
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C2D12), Color(0xFFF97316)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Laporkan titik sampah agar penanganan dapat diprioritaskan.',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lengkapi foto, kategori, dan lokasi untuk membentuk arsip laporan lingkungan pada aplikasi.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withOpacity(0.94),
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
                          title: 'Total laporan',
                          value: _reports.length.toString(),
                          icon: Icons.assignment_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ReportStatCard(
                          title: 'Status aktif',
                          value: _reports.isEmpty ? '0' : _reports.length.toString(),
                          icon: Icons.notifications_active_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_reports.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.assignment_outlined,
                                size: 34,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada laporan lingkungan.',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tekan tombol Buat laporan untuk menambahkan lokasi penumpukan sampah lengkap dengan foto dan detailnya.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
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
    final file = report.imagePath == null ? null : File(report.imagePath!);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (file != null && file.existsSync())
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.file(file, fit: BoxFit.cover),
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(label: Text(report.status)),
                              Chip(label: Text(report.urgency)),
                              Chip(label: Text(report.category)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
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
                              Icon(Icons.delete_outline),
                              SizedBox(width: 8),
                              Text('Hapus'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  report.locationName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                Text(formattedDate),
                const SizedBox(height: 12),
                Text(report.description),
              ],
            ),
          ),
        ],
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

  final List<String> _locations = const [
    'Ketintang',
    'Gayungan',
    'Jemur Wonosari',
    'Wonokromo',
    'Dukuh Menanggal',
  ];
  final List<String> _categories = const [
    'Tumpukan liar',
    'Sampah menutup saluran',
    'Sampah campuran',
    'Area butuh pengangkutan',
  ];
  final List<String> _urgencies = const ['Rendah', 'Sedang', 'Tinggi'];

  String _selectedLocation = 'Ketintang';
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

    setState(() {
      _isSubmitting = true;
    });

    try {
      final image = await StorageService.instance.persistImage(_selectedImage!);
      final report = EnvironmentalReport(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        locationName: _selectedLocation,
        urgency: _selectedUrgency,
        status: 'Menunggu verifikasi',
        createdAt: DateTime.now(),
        imagePath: image.path,
      );

      await ReportService.instance.addReport(report);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Laporan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lampirkan foto kondisi lapangan',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        ),
                      )
                    else
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Icon(Icons.add_a_photo_outlined, size: 42),
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Judul laporan',
                        hintText: 'Contoh: Penumpukan sampah di sudut jalan',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Judul laporan wajib diisi.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _selectedLocation,
                      decoration: const InputDecoration(
                        labelText: 'Lokasi',
                      ),
                      items: _locations
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
                            _selectedLocation = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Kategori laporan',
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
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _selectedUrgency,
                      decoration: const InputDecoration(
                        labelText: 'Tingkat urgensi',
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
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 4,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Keterangan',
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
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _saveReport,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(
                _isSubmitting ? 'Menyimpan laporan...' : 'Simpan laporan',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
