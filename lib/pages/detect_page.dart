import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/classification_result.dart';
import '../models/history_entry.dart';
import '../services/classifier_service.dart';
import '../services/history_service.dart';
import '../services/storage_service.dart';
import '../utils/image_preprocessor.dart';
import '../widgets/preprocessing_preview.dart';
import '../widgets/result_card.dart';

class DetectPage extends StatefulWidget {
  final VoidCallback onHistorySaved;

  const DetectPage({super.key, required this.onHistorySaved});

  @override
  State<DetectPage> createState() => _DetectPageState();
}

class _DetectPageState extends State<DetectPage> {
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultSectionKey = GlobalKey();

  File? _selectedImage;
  PreprocessingBundle? _bundle;
  ClassificationResult? _result;
  bool _isBusy = false;
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await ClassifierService.instance.initialize();
    await _recoverLostData();
    if (!mounted) {
      return;
    }
    setState(() {
      _isInitializing = false;
    });
  }

  Future<void> _recoverLostData() async {
    final response = await _picker.retrieveLostData();
    if (response.isEmpty || response.files == null || response.files!.isEmpty) {
      return;
    }

    final recovered = await StorageService.instance.persistImage(
      File(response.files!.first.path),
    );
    final bundle = await ImagePreprocessor.prepare(recovered);

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedImage = recovered;
      _bundle = bundle;
      _result = null;
      _errorMessage = null;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isBusy = true;
        _errorMessage = null;
      });

      final file = await _picker.pickImage(
        source: source,
        imageQuality: 95,
        maxWidth: 1600,
      );

      if (file == null) {
        setState(() {
          _isBusy = false;
        });
        return;
      }

      final selectedFile = await StorageService.instance.persistImage(
        File(file.path),
      );
      final bundle = await ImagePreprocessor.prepare(selectedFile);

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedImage = selectedFile;
        _bundle = bundle;
        _result = null;
        _isBusy = false;
      });

      await _scrollToNewContent();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isBusy = false;
        _errorMessage = 'Gagal memuat gambar: $error';
      });
    }
  }

  Future<void> _classify() async {
    if (_bundle == null || _selectedImage == null) {
      return;
    }

    try {
      setState(() {
        _isBusy = true;
        _errorMessage = null;
      });

      final result = await ClassifierService.instance.classify(_bundle!);

      final historyItem = DetectionHistoryItem(
        imagePath: _selectedImage!.path,
        result: result,
        createdAt: DateTime.now(),
      );

      await HistoryService.instance.addHistory(historyItem);
      widget.onHistorySaved();

      if (!mounted) {
        return;
      }

      setState(() {
        _result = result;
        _isBusy = false;
      });

      await _scrollToResult();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isBusy = false;
        _errorMessage = 'Proses klasifikasi gagal: $error';
      });
    }
  }

  Future<void> _scrollToNewContent() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!_scrollController.hasClients) {
      return;
    }

    await _scrollController.animateTo(
      (_scrollController.position.pixels + 340).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _scrollToResult() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final context = _resultSectionKey.currentContext;
    if (context == null) {
      return;
    }

    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeInOutCubic,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usingModel = ClassifierService.instance.isUsingModel;

    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _HeroCard(isUsingModel: usingModel, isInitializing: _isInitializing),
        const SizedBox(height: 16),
        const _SectionTitle(
          title: 'Ambil gambar',
          subtitle: 'Pilih dari kamera atau galeri untuk mulai klasifikasi.',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isBusy ? null : () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Kamera'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isBusy ? null : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galeri'),
              ),
            ),
          ],
        ),
        if (_isInitializing) ...[
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator()),
        ],
        if (_selectedImage != null) ...[
          const SizedBox(height: 18),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      left: 14,
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.image_outlined,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 210),
                              child: Text(
                                _selectedImage!.path.split('/').last,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gambar siap diproses',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tekan tombol klasifikasi di bawah untuk melihat hasil dan riwayat terbaru.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isBusy ? null : _classify,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      icon: _isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isBusy ? 'Mengklasifikasi...' : 'Klasifikasi sekarang'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_bundle != null && _selectedImage != null) ...[
          const SizedBox(height: 16),
          const _SectionTitle(
            title: 'Preview preprocessing',
            subtitle: 'Lihat tahapan pengolahan sebelum model membaca gambar.',
          ),
          const SizedBox(height: 12),
          PreprocessingPreview(
            originalFile: _selectedImage!,
            clahePreview: _bundle!.clahePreview,
            processedPreview: _bundle!.processedPreview,
            edgePreview: _bundle!.edgePreview,
          ),
        ],
        if (_isBusy && _result == null) ...[
          const SizedBox(height: 20),
          const Center(child: CircularProgressIndicator()),
        ],
        if (_result != null) ...[
          const SizedBox(height: 18),
          _SectionTitle(
            key: _resultSectionKey,
            title: 'Hasil klasifikasi',
            subtitle: 'Halaman akan langsung berpindah ke sini setelah tombol klasifikasi ditekan.',
          ),
          const SizedBox(height: 12),
          ResultCard(result: _result!),
        ],
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFFFFF1F0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final bool isUsingModel;
  final bool isInitializing;

  const _HeroCard({required this.isUsingModel, required this.isInitializing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF1F8A70), Color(0xFF5BC0A5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F8A70).withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.recycling_rounded, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Klasifikasi sampah lebih cepat',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pilih gambar, jalankan inferensi lokal, lalu lihat hasil secara instan.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.92),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: isUsingModel ? Icons.memory : Icons.science_outlined,
                  label: isUsingModel ? 'Mode TFLite offline' : 'Mode demo heuristik',
                  textColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.14),
                ),
                _InfoChip(
                  icon: Icons.photo_size_select_large_outlined,
                  label: 'Input 224 x 224',
                  textColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.14),
                ),
                _InfoChip(
                  icon: Icons.filter_alt_outlined,
                  label: 'CLAHE + edge preview',
                  textColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.14),
                ),
              ],
            ),
            if (!isUsingModel && !isInitializing) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.20)),
                ),
                child: Text(
                  'Model TFLite belum ditemukan. Aplikasi tetap bisa dipakai dalam mode demo untuk menampilkan alur kerja dan UI.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
