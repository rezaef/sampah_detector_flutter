import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class PreprocessingPreview extends StatelessWidget {
  final File originalFile;
  final Uint8List clahePreview;
  final Uint8List processedPreview;
  final Uint8List edgePreview;

  const PreprocessingPreview({
    super.key,
    required this.originalFile,
    required this.clahePreview,
    required this.processedPreview,
    required this.edgePreview,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tahapan preprocessing',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 0.88,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _PreviewTile(
                  title: 'Original',
                  child: Image.file(originalFile, fit: BoxFit.cover),
                ),
                _PreviewTile(
                  title: 'Setelah CLAHE',
                  child: Image.memory(clahePreview, fit: BoxFit.cover),
                ),
                _PreviewTile(
                  title: 'Preprocessing',
                  child: Image.memory(processedPreview, fit: BoxFit.cover),
                ),
                _PreviewTile(
                  title: 'Edge detection',
                  child: Image.memory(edgePreview, fit: BoxFit.cover),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  final String title;
  final Widget child;

  const _PreviewTile({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              color: Colors.grey.shade200,
              width: double.infinity,
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
