import 'package:flutter/material.dart';

import '../models/classification_result.dart';

class ResultCard extends StatelessWidget {
  final ClassificationResult result;
  final VoidCallback? onOpenGuide;

  const ResultCard({
    super.key,
    required this.result,
    this.onOpenGuide,
  });

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

    return Container(
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
        padding: const EdgeInsets.all(20),
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
                          'Hasil Klasifikasi',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: const Color(0xFF507A6D),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.label,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: accent,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          result.recommendation,
                          style: const TextStyle(
                            color: Color(0xFF1B4D3E),
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(
                  icon: Icons.speed_outlined,
                  label: '${result.latencyMs} ms',
                ),
                _MetaChip(
                  icon: Icons.memory_outlined,
                  label: result.engine,
                ),
                _MetaChip(
                  icon: Icons.verified_outlined,
                  label: result.confidenceLabel,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tingkat Kepercayaan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B4D3E),
                  ),
                ),
                Text(
                  result.confidenceLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
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
                minHeight: 10,
                color: accent,
                backgroundColor: accent.withOpacity(0.12),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Skor per Kelas',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B4D3E),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1B4D3E),
                            ),
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B4D3E),
                          ),
                        ),
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
            const SizedBox(height: 8),
            const Text(
              'Tindak Lanjut',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B4D3E),
              ),
            ),
            const SizedBox(height: 12),
            ...result.disposalSteps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        step,
                        style: const TextStyle(
                          color: Color(0xFF507A6D),
                          fontSize: 13.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (onOpenGuide != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: onOpenGuide,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1F8A70).withOpacity(0.1),
                    foregroundColor: const Color(0xFF1F8A70),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text(
                    'Buka panduan pemilahan',
                    style: TextStyle(fontWeight: FontWeight.w700),
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

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.7),
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
