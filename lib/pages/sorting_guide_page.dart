import 'package:flutter/material.dart';

class SortingGuidePage extends StatelessWidget {
  const SortingGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panduan Pemilahan Sampah')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: const [
          _GuideHero(),
          SizedBox(height: 16),
          _GuideCategoryCard(
            title: 'Sampah Organik',
            subtitle: 'Sisa makanan, daun kering, kulit buah, dan bahan mudah terurai.',
            icon: Icons.eco_outlined,
            color: Color(0xFF2E8B57),
            examples: [
              'Sisa makanan dan sayur',
              'Kulit buah dan ampas kopi',
              'Daun, rumput, dan ranting kecil',
            ],
            steps: [
              'Pisahkan dari plastik, kaca, dan logam.',
              'Simpan pada wadah tertutup untuk menjaga kebersihan area.',
              'Arahkan ke komposter atau tong organik.',
            ],
          ),
          SizedBox(height: 12),
          _GuideCategoryCard(
            title: 'Sampah Anorganik',
            subtitle: 'Plastik, kertas, kaleng, kaca, dan material yang dapat didaur ulang.',
            icon: Icons.recycling_outlined,
            color: Color(0xFF2F6FED),
            examples: [
              'Botol plastik, gelas kemasan, dan kantong plastik',
              'Kertas, kardus, dan karton bersih',
              'Kaleng minuman, botol kaca, dan logam ringan',
            ],
            steps: [
              'Bilas dan keringkan sebelum disimpan.',
              'Lipat atau pipihkan kemasan agar hemat ruang.',
              'Setorkan ke bank sampah atau wadah daur ulang.',
            ],
          ),
          SizedBox(height: 12),
          _QuickGuideCard(),
          SizedBox(height: 12),
          _MistakeCard(),
        ],
      ),
    );
  }
}

class _GuideHero extends StatelessWidget {
  const _GuideHero();

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'Pemilahan yang tepat mempermudah daur ulang.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gunakan panduan ini sebagai rujukan cepat setelah proses klasifikasi selesai.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideCategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> examples;
  final List<String> steps;

  const _GuideCategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.examples,
    required this.steps,
  });

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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withOpacity(0.12),
                  foregroundColor: color,
                  child: Icon(icon, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF6B8A80),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Contoh',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B4D3E),
              ),
            ),
            const SizedBox(height: 8),
            ...examples.map(
              (example) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        example,
                        style: const TextStyle(color: Color(0xFF507A6D), fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Langkah Penanganan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B4D3E),
              ),
            ),
            const SizedBox(height: 8),
            ...steps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(Icons.check, size: 14, color: color),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        step,
                        style: const TextStyle(color: Color(0xFF507A6D), fontSize: 13.5, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickGuideCard extends StatelessWidget {
  const _QuickGuideCard();

  @override
  Widget build(BuildContext context) {
    final items = const [
      'Pisahkan jenis sampah sejak awal.',
      'Pastikan kemasan anorganik kering sebelum disimpan.',
      'Salurkan sampah bernilai ke bank sampah atau fasilitas daur ulang.',
    ];

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
            const Text(
              'Alur Cepat Pemilahan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B4D3E),
              ),
            ),
            const SizedBox(height: 12),
            ...items.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: const Color(0xFF1F8A70).withOpacity(0.12),
                      foregroundColor: const Color(0xFF1F8A70),
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(color: Color(0xFF507A6D), fontSize: 13.5, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MistakeCard extends StatelessWidget {
  const _MistakeCard();

  @override
  Widget build(BuildContext context) {
    const mistakes = [
      'Mencampur sisa makanan dengan plastik sekali pakai.',
      'Menyimpan botol atau kaleng dalam kondisi masih basah.',
      'Membuang sampah bernilai daur ulang ke tong residu.',
    ];

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
            const Text(
              'Kesalahan yang Perlu Dihindari',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B4D3E),
              ),
            ),
            const SizedBox(height: 12),
            ...mistakes.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFA447), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(color: Color(0xFF507A6D), fontSize: 13.5, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
