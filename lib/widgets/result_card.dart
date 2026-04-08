import 'package:flutter/material.dart';

import '../models/classification_result.dart';

class ResultCard extends StatelessWidget {
  final ClassificationResult result;

  const ResultCard({super.key, required this.result});

  Color _resultColor() {
    switch (result.category) {
      case WasteCategory.organik:
        return const Color(0xFF2E8B57);
      case WasteCategory.anorganik:
        return const Color(0xFF2F6FED);
      case WasteCategory.tidakDiketahui:
        return const Color(0xFFE69500);
    }
  }

  IconData _resultIcon() {
    switch (result.category) {
      case WasteCategory.organik:
        return Icons.eco_outlined;
      case WasteCategory.anorganik:
        return Icons.recycling_outlined;
      case WasteCategory.tidakDiketahui:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _resultColor();
    final theme = Theme.of(context);
    final scores = result.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: accent.withOpacity(0.12),
                    foregroundColor: accent,
                    child: Icon(_resultIcon()),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hasil klasifikasi',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.label,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          result.recommendation,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _MetaChip(
                  icon: Icons.speed_outlined,
                  label: '${result.latencyMs} ms',
                ),
                const SizedBox(width: 8),
                _MetaChip(
                  icon: Icons.memory_outlined,
                  label: result.engine,
                ),
                if (result.isDemo) ...[
                  const SizedBox(width: 8),
                  const _MetaChip(
                    icon: Icons.science_outlined,
                    label: 'Demo',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tingkat kepercayaan',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  result.confidenceLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: result.confidence,
                minHeight: 12,
                color: accent,
                backgroundColor: accent.withOpacity(0.12),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Skor per kelas',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...scores.map((entry) {
              final percentage = (entry.value * 100).toStringAsFixed(1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text('$percentage%'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: entry.value,
                        minHeight: 8,
                        color: accent.withOpacity(0.85),
                        backgroundColor: accent.withOpacity(0.10),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (result.isDemo) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6E7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFDEA0)),
                ),
                child: const Text(
                  'Catatan: hasil ini berasal dari mode demo heuristik. Tambahkan model TFLite agar inferensi memakai model CNN penelitian.',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}
