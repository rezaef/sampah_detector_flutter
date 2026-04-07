import 'dart:io';

import 'package:flutter/material.dart';

import '../models/history_entry.dart';
import '../services/history_service.dart';

class HistoryPage extends StatefulWidget {
  final int refreshToken;

  const HistoryPage({super.key, required this.refreshToken});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _isLoading = true;
  List<DetectionHistoryItem> _history = <DetectionHistoryItem>[];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didUpdateWidget(covariant HistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    final history = await HistoryService.instance.loadHistory();

    if (!mounted) {
      return;
    }

    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    await HistoryService.instance.clearHistory();
    await _loadHistory();
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_history.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadHistory,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 72),
            Icon(Icons.history_toggle_off, size: 64),
            SizedBox(height: 16),
            Center(
              child: Text(
                'Belum ada riwayat deteksi.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: _history.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _clearHistory,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus riwayat'),
              ),
            );
          }

          final item = _history[index - 1];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 92,
                      height: 92,
                      child: _HistoryImage(path: item.imagePath),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.result.label,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text('Kepercayaan: ${item.result.confidenceLabel}'),
                        const SizedBox(height: 4),
                        Text('Waktu: ${_formatDateTime(item.createdAt)}'),
                        const SizedBox(height: 8),
                        Text(item.result.recommendation),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(label: Text(item.result.engine)),
                            if (item.result.isDemo)
                              const Chip(label: Text('Demo')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HistoryImage extends StatelessWidget {
  final String path;

  const _HistoryImage({required this.path});

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (!file.existsSync()) {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.image_not_supported_outlined),
      );
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image_outlined),
        );
      },
    );
  }
}
