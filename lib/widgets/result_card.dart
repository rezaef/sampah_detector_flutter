import 'package:flutter/material.dart';

import '../models/classification_result.dart';

class ResultCard extends StatelessWidget {
  final ClassificationResult result;

  const ResultCard({super.key, required this.result});

  Color _resultColor() {
    switch (result.category) {
      case WasteCategory.organik:
        return Colors.green;
      case WasteCategory.anorganik:
        return Colors.blue;
      case WasteCategory.tidakDiketahui:
        return Colors.orange;
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
    final scores = result.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: accent.withOpacity(0.12),
                  foregroundColor: accent,
                  child: Icon(_resultIcon()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hasil klasifikasi',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.label,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                      ),
                    ],
                  ),
                ),
                Chip(label: Text(result.engine)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Kepercayaan: ${result.confidenceLabel}'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: result.confidence,
              minHeight: 10,
              borderRadius: BorderRadius.circular(12),
              color: accent,
              backgroundColor: accent.withOpacity(0.14),
            ),
            const SizedBox(height: 16),
            Text(
              result.recommendation,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            if (result.isDemo) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.30)),
                ),
                child: const Text(
                  'Catatan: hasil ini berasal dari mode demo heuristik. Tambahkan model TFLite agar inferensi memakai model CNN penelitian.',
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Skor per kelas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            ...scores.map((entry) {
              final percentage = (entry.value * 100).toStringAsFixed(1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.key)),
                    Text('$percentage%'),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Text(
              'Latency: ${result.latencyMs} ms',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
