import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/history_entry.dart';
import '../models/classification_result.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usingModel = ClassifierService.instance.isUsingModel;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sistem deteksi sampah organik dan anorganik',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aplikasi ini mengikuti alur capture gambar, preprocessing, inferensi lokal, dan penampilan hasil secara langsung.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: usingModel ? Icons.memory : Icons.science_outlined,
                      label: usingModel ? 'Mode TFLite offline' : 'Mode demo heuristik',
                    ),
                    const _InfoChip(
                      icon: Icons.photo_size_select_large_outlined,
                      label: 'Input 224 x 224',
                    ),
                    const _InfoChip(
                      icon: Icons.filter_alt_outlined,
                      label: 'CLAHE + edge preview',
                    ),
                  ],
                ),
                if (!usingModel && !_isInitializing) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.30)),
                    ),
                    child: const Text(
                      'Model TFLite belum ditemukan. Aplikasi tetap bisa dipakai dalam mode demo untuk menampilkan alur kerja dan UI.',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Gambar terpilih: ${_selectedImage!.path.split('/').last}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_bundle != null && _selectedImage != null) ...[
          const SizedBox(height: 16),
          PreprocessingPreview(
            originalFile: _selectedImage!,
            clahePreview: _bundle!.clahePreview,
            processedPreview: _bundle!.processedPreview,
            edgePreview: _bundle!.edgePreview,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isBusy ? null : _classify,
            icon: const Icon(Icons.auto_awesome),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Klasifikasikan'),
            ),
          ),
        ],
        if (_isBusy) ...[
          const SizedBox(height: 20),
          const Center(child: CircularProgressIndicator()),
        ],
        if (_result != null) ...[
          const SizedBox(height: 16),
          ResultCard(result: _result!),
        ],
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Card(
            color: Colors.red.withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
