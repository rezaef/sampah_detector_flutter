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
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF1F8A70), Color(0xFF5BC0A5)],
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
              'Pemilahan yang tepat mempermudah daur ulang dan kompos.',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gunakan panduan ini sebagai rujukan cepat setelah proses klasifikasi selesai.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.94),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color.withOpacity(0.12),
                  foregroundColor: color,
                  child: Icon(icon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Contoh',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...examples.map(
              (example) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, size: 10, color: color),
                    const SizedBox(width: 10),
                    Expanded(child: Text(example)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Langkah penanganan',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...steps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(Icons.check, size: 14, color: color),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(step)),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alur cepat pemilahan',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ...items.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      child: Text('${entry.key + 1}'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(entry.value)),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kesalahan yang perlu dihindari',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ...mistakes.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFE69500)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item)),
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
