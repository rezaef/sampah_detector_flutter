import 'package:flutter/material.dart';

class EducationPage extends StatefulWidget {
  const EducationPage({super.key});

  @override
  State<EducationPage> createState() => _EducationPageState();
}

class _EducationPageState extends State<EducationPage> {
  String _selectedCategory = 'Semua';

  static const List<String> _categories = [
    'Semua',
    '3R',
    'Kompos',
    'Kebiasaan',
  ];

  static const List<_ArticleItem> _articles = [
    _ArticleItem(
      category: '3R',
      title: 'Mulai dari prinsip Reduce, Reuse, Recycle',
      summary:
          'Kurangi sampah dari sumbernya dengan membeli secukupnya dan memakai ulang barang yang masih layak.',
      readingTime: '3 menit',
      content: [
        'Reduce berarti mengurangi sampah sejak proses konsumsi, misalnya membawa tumbler sendiri dan menolak kemasan berlebih.',
        'Reuse berarti menggunakan kembali barang yang masih layak pakai seperti wadah makan, kantong belanja, atau botol isi ulang.',
        'Recycle berarti memisahkan material bernilai seperti plastik, kertas, dan logam agar bisa diproses kembali.',
      ],
    ),
    _ArticleItem(
      category: 'Kompos',
      title: 'Langkah sederhana membuat kompos rumah tangga',
      summary:
          'Sampah organik dapat diolah menjadi kompos untuk tanaman dengan wadah tertutup dan pengaturan kelembapan yang tepat.',
      readingTime: '4 menit',
      content: [
        'Pisahkan sisa makanan, kulit buah, dan daun kering dari bahan non organik.',
        'Gunakan wadah tertutup dengan ventilasi dan tambahkan material kering agar kelembapan tetap stabil.',
        'Aduk secara berkala hingga tekstur lebih gembur dan aroma tanah mulai terasa.',
      ],
    ),
    _ArticleItem(
      category: 'Kebiasaan',
      title: 'Kebiasaan kecil yang berdampak besar untuk lingkungan',
      summary:
          'Konsistensi memilah, membawa wadah sendiri, dan melaporkan titik sampah membantu menjaga lingkungan sekitar.',
      readingTime: '2 menit',
      content: [
        'Sisihkan waktu singkat setiap hari untuk memastikan sampah rumah tangga sudah terpisah dengan benar.',
        'Biasakan membawa tas belanja, botol minum, dan alat makan sendiri untuk menekan sampah sekali pakai.',
        'Laporkan penumpukan sampah yang mengganggu agar penanganan lingkungan bisa lebih cepat dilakukan.',
      ],
    ),
    _ArticleItem(
      category: '3R',
      title: 'Manfaat bank sampah bagi lingkungan dan ekonomi',
      summary:
          'Bank sampah membantu material anorganik bernilai tetap bersirkulasi sekaligus menumbuhkan kebiasaan memilah.',
      readingTime: '3 menit',
      content: [
        'Bank sampah memudahkan proses pengumpulan material yang masih bernilai ekonomis.',
        'Pemilahan yang rapi membantu pengelola mempercepat proses sortir dan distribusi ke mitra daur ulang.',
        'Di tingkat pengguna, kebiasaan menyetor sampah memunculkan rasa memiliki terhadap kebersihan lingkungan.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visibleArticles = _selectedCategory == 'Semua'
        ? _articles
        : _articles.where((item) => item.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Edukasi Lingkungan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF14532D), Color(0xFF4ADE80)],
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
                    'Konten singkat, padat, dan relevan untuk kebiasaan ramah lingkungan.',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pilih kategori konten lalu buka artikel untuk membaca ringkasan yang bisa langsung diterapkan.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.94),
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) {
              final selected = category == _selectedCategory;
              return ChoiceChip(
                selected: selected,
                label: Text(category),
                onSelected: (_) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          ...visibleArticles.map(
            (article) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ArticleCard(
                article: article,
                onTap: () => _openArticle(article),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openArticle(_ArticleItem article) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.50,
          maxChildSize: 0.92,
          builder: (context, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Center(
                    child: Container(
                      width: 52,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    article.title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(label: Text(article.category)),
                      Chip(label: Text(article.readingTime)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(article.summary),
                  const SizedBox(height: 18),
                  ...article.content.map(
                    (paragraph) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 18),
                          const SizedBox(width: 10),
                          Expanded(child: Text(paragraph)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final _ArticleItem article;
  final VoidCallback onTap;

  const _ArticleCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(article.category)),
                  Chip(label: Text(article.readingTime)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                article.title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                article.summary,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleItem {
  final String category;
  final String title;
  final String summary;
  final String readingTime;
  final List<String> content;

  const _ArticleItem({
    required this.category,
    required this.title,
    required this.summary,
    required this.readingTime,
    required this.content,
  });
}
