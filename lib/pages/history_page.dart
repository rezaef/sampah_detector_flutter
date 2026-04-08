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
  final Set<String> _selectedIds = <String>{};

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

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
      _selectedIds.removeWhere(
        (id) => !_history.any((item) => item.id == id),
      );
      _isLoading = false;
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus riwayat terpilih?'),
          content: Text(
            '${_selectedIds.length} item riwayat akan dihapus permanen.',
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

    await HistoryService.instance.removeHistoryByIds(_selectedIds);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedIds.length} riwayat dihapus.'),
      ),
    );

    setState(() {
      _selectedIds.clear();
    });

    await _loadHistory();
  }

  void _toggleSelection(DetectionHistoryItem item, {bool forceEnable = false}) {
    setState(() {
      if (forceEnable || _selectedIds.contains(item.id)) {
        if (_selectedIds.contains(item.id) && !forceEnable) {
          _selectedIds.remove(item.id);
        } else {
          _selectedIds.add(item.id);
        }
      } else {
        _selectedIds.add(item.id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedIds.length == _history.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(_history.map((item) => item.id));
      }
    });
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
          children: [
            const SizedBox(height: 72),
            Container(
              width: 84,
              height: 84,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_toggle_off,
                size: 40,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            Text(
              'Belum ada riwayat deteksi.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hasil klasifikasi yang kamu simpan akan muncul di sini.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: _history.length + (_isSelectionMode ? 2 : 1),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _HistoryHeaderCard(isSelectionMode: _isSelectionMode);
          }

          if (_isSelectionMode && index == 1) {
            final allSelected = _selectedIds.length == _history.length;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedIds.length} item dipilih',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectAll,
                            icon: Icon(
                              allSelected
                                  ? Icons.remove_done_outlined
                                  : Icons.select_all_outlined,
                            ),
                            label: Text(
                              allSelected ? 'Batal pilih semua' : 'Pilih semua',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _deleteSelected,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Hapus'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          final item = _history[index - (_isSelectionMode ? 2 : 1)];
          final selected = _selectedIds.contains(item.id);

          return _HistoryCard(
            item: item,
            isSelected: selected,
            formattedDateTime: _formatDateTime(item.createdAt),
            onTap: () {
              if (_isSelectionMode) {
                _toggleSelection(item);
              }
            },
            onLongPress: () => _toggleSelection(item, forceEnable: true),
          );
        },
      ),
    );
  }
}

class _HistoryHeaderCard extends StatelessWidget {
  final bool isSelectionMode;

  const _HistoryHeaderCard({required this.isSelectionMode});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelectionMode ? Icons.checklist_rounded : Icons.history_rounded,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSelectionMode ? 'Mode pilih aktif' : 'Riwayat klasifikasi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSelectionMode
                        ? 'Tap item untuk memilih, lalu pilih semua atau hapus.'
                        : 'Tahan salah satu item untuk mulai memilih beberapa riwayat.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _HistoryCard extends StatelessWidget {
  final DetectionHistoryItem item;
  final bool isSelected;
  final String formattedDateTime;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _HistoryCard({
    required this.item,
    required this.isSelected,
    required this.formattedDateTime,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = Theme.of(context).colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: selectedColor.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isSelected
                ? selectedColor
                : Theme.of(context).colorScheme.outlineVariant.withOpacity(0.35),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        width: 92,
                        height: 92,
                        child: _HistoryImage(path: item.imagePath),
                      ),
                    ),
                    if (isSelected)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: selectedColor.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.check_circle, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.result.label,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle, color: selectedColor),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Kepercayaan: ${item.result.confidenceLabel}'),
                      const SizedBox(height: 4),
                      Text('Waktu: $formattedDateTime'),
                      const SizedBox(height: 10),
                      Text(
                        item.result.recommendation,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(label: Text(item.result.engine)),
                          if (item.result.isDemo) const Chip(label: Text('Demo')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.image_not_supported_outlined),
      );
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.broken_image_outlined),
        );
      },
    );
  }
}
