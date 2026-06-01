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
                  const Text(
                    'Edukasi Singkat & Aksi Ramah Lingkungan.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pilih kategori konten lalu buka artikel untuk membaca ringkasan yang bisa langsung diterapkan.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                final selected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: selected,
                    label: Text(category),
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
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
    final theme = Theme.of(context);

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
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                children: [
                  Center(
                    child: Container(
                      width: 52,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B4D3E),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F8A70).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          article.category,
                          style: const TextStyle(
                            color: Color(0xFF1F8A70),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          article.readingTime,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    article.summary,
                    style: const TextStyle(
                      color: Color(0xFF1B4D3E),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  ...article.content.map(
                    (paragraph) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F8A70).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.check, size: 14, color: Color(0xFF1F8A70)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              paragraph,
                              style: const TextStyle(
                                color: Color(0xFF507A6D),
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F8A70).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        article.category,
                        style: const TextStyle(
                          color: Color(0xFF1F8A70),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        article.readingTime,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  article.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B4D3E),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  article.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B8A80),
                    fontSize: 13,
                    height: 1.35,
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
