import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/classification_result.dart';
import '../models/history_entry.dart';
import '../services/classifier_service.dart';
import '../services/history_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../utils/image_preprocessor.dart';
import '../widgets/preprocessing_preview.dart';
import '../widgets/result_card.dart';

class DetectPage extends StatefulWidget {
  final VoidCallback onHistorySaved;
  final VoidCallback? onOpenGuide;

  const DetectPage({
    super.key,
    required this.onHistorySaved,
    this.onOpenGuide,
  });

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
      await NotificationService.instance.showClassificationCompleted(
        label: result.label,
        confidenceLabel: result.confidenceLabel,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _result = result;
        _isBusy = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToResult();
      });
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
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) {
      return;
    }

    final targetContext = _resultSectionKey.currentContext;
    if (targetContext == null) {
      return;
    }

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 520),
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
          title: 'Ambil gambar sampah',
          subtitle:
              'Foto langsung dari kamera atau pilih dari galeri perangkat Anda.',
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
          Container(
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
                          color: const Color(0xFF1F8A70).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFF1F8A70),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gambar berhasil dimuat',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF1B4D3E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tekan tombol di bawah untuk memulai klasifikasi. Gambar akan di-resize ke 192×192 piksel dan diproses oleh model MobileNetV2.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF507A6D),
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
                      onPressed: _isBusy
                          ? null
                          : () async {
                              HapticFeedback.mediumImpact();
                              await _classify();
                            },
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
                      label: Text(
                        _isBusy ? 'Mengklasifikasi...' : 'Klasifikasi sekarang',
                      ),
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
            title: 'Tahapan preprocessing',
            subtitle:
                'Visualisasi setiap langkah: resize, CLAHE (peningkatan kontras), normalisasi, dan deteksi tepi.',
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
            subtitle:
                'Label prediksi, skor confidence per kelas, dan rekomendasi penanganan sampah.',
          ),
          const SizedBox(height: 12),
          ResultCard(
            result: _result!,
            onOpenGuide: widget.onOpenGuide,
          ),
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
    final engineLabel = isUsingModel ? 'MobileNetV2 via TFLite' : 'Inferensi lokal';

    return Container(
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
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deteksi Organik & Anorganik',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Klasifikasi jenis sampah secara otomatis dan instan.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.memory_rounded,
                  label: engineLabel,
                  textColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.12),
                ),
                _InfoChip(
                  icon: Icons.aspect_ratio_rounded,
                  label: 'Input 192 × 192',
                  textColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.12),
                ),
                _InfoChip(
                  icon: Icons.photo_filter_rounded,
                  label: 'CLAHE + Canny Edge',
                  textColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.12),
                ),
              ],
            ),
            if (!isInitializing) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Hasil klasifikasi otomatis disimpan dan menambah poin Anda.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1B4D3E),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B8A80),
            fontWeight: FontWeight.w500,
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
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
