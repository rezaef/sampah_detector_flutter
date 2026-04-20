import 'package:flutter/material.dart';

class BankSampahPage extends StatefulWidget {
  const BankSampahPage({super.key});

  @override
  State<BankSampahPage> createState() => _BankSampahPageState();
}

class _BankSampahPageState extends State<BankSampahPage> {
  final List<_BankSampahSpot> _spots = const [
    _BankSampahSpot(
      name: 'Bank Sampah Ketintang 17',
      shortLabel: 'Ketintang 17',
      address:
          'Jl. Ketintang Baru XVII No.43A, Ketintang, Kec. Gayungan, Surabaya 60231',
      serviceInfo: 'Setoran anorganik warga sekitar',
      materials: ['Plastik', 'Kertas', 'Logam'],
      proximity: 'Sekitar kampus',
      note:
          'Pilihan terdekat untuk menyetor sampah anorganik yang sudah dipilah dari area sekitar Telkom University Surabaya.',
      x: 178,
      y: 156,
    ),
    _BankSampahSpot(
      name: 'Bank Sampah Anomali Iklim',
      shortLabel: 'Jemur',
      address: 'RT 003 RW 003, Jemur, Kec. Gayungan, Surabaya',
      serviceInfo: 'Pengambilan rumah Jumat & Sabtu',
      materials: ['Plastik', 'Kertas', 'Logam'],
      proximity: 'Area Gayungan',
      note:
          'Program berbasis warga yang aktif mengurangi sampah anorganik dan melayani pengambilan terjadwal.',
      x: 312,
      y: 118,
    ),
    _BankSampahSpot(
      name: 'Bank Sampah Induk Surabaya',
      shortLabel: 'BSIS',
      address:
          'Jl. Raya Menur No.31-A, Manyar Sabrangan, Kec. Mulyorejo, Surabaya 60116',
      serviceInfo: 'Rujukan bank sampah tingkat kota',
      materials: ['Plastik', 'Kertas', 'Logam', 'Jelantah'],
      proximity: 'Rujukan kota',
      note:
          'Cocok sebagai rujukan lanjutan ketika membutuhkan mitra bank sampah skala kota atau layanan lebih lengkap.',
      x: 490,
      y: 86,
    ),
  ];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final selected = _spots[_selectedIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('Peta Lokasi Bank Sampah')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF134E4A), Color(0xFF2DD4BF)],
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
                    'Peta bank sampah sekitar Ketintang untuk memudahkan setoran dari area kampus.',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Titik acuan menggunakan Telkom University Surabaya di Jl. Ketintang No.156.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.94),
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 2.2,
                child: Container(
                  width: 620,
                  height: 360,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD1FAE5), Color(0xFFECFDF5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      ...List.generate(8, (index) {
                        return Positioned(
                          left: 40.0 + (index * 70),
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 1,
                            color: Colors.white.withOpacity(0.55),
                          ),
                        );
                      }),
                      ...List.generate(5, (index) {
                        return Positioned(
                          top: 40.0 + (index * 62),
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 1,
                            color: Colors.white.withOpacity(0.55),
                          ),
                        );
                      }),
                      Positioned(
                        left: 32,
                        right: 26,
                        top: 156,
                        child: Transform.rotate(
                          angle: -0.08,
                          child: Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFFBFDBFE).withOpacity(0.72),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 24,
                        top: 22,
                        child: _AreaLabel(text: 'Ketintang'),
                      ),
                      const Positioned(
                        left: 260,
                        top: 22,
                        child: _AreaLabel(text: 'Gayungan'),
                      ),
                      const Positioned(
                        right: 30,
                        top: 22,
                        child: _AreaLabel(text: 'Mulyorejo'),
                      ),
                      Positioned(
                        left: 220,
                        top: 230,
                        child: Column(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D4ED8),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1D4ED8)
                                        .withOpacity(0.24),
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.school_outlined,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Tel-U SBY',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ..._spots.asMap().entries.map((entry) {
                        final index = entry.key;
                        final spot = entry.value;
                        final selected = index == _selectedIndex;
                        return Positioned(
                          left: spot.x,
                          top: spot.y,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                            child: Column(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: selected ? 48 : 40,
                                  height: selected ? 48 : 40,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFF0F766E)
                                        : const Color(0xFF115E59),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF115E59)
                                            .withOpacity(0.22),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  constraints:
                                      const BoxConstraints(maxWidth: 128),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    spot.shortLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selected.address,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.place_outlined, size: 16),
                        label: Text(selected.proximity),
                      ),
                      Chip(
                        avatar: const Icon(Icons.info_outline, size: 16),
                        label: Text(selected.serviceInfo),
                      ),
                      ...selected.materials
                          .map((material) => Chip(label: Text(material))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(selected.note),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Daftar lokasi',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ..._spots.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BankSpotCard(
                spot: entry.value,
                isSelected: entry.key == _selectedIndex,
                onTap: () {
                  setState(() {
                    _selectedIndex = entry.key;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaLabel extends StatelessWidget {
  final String text;

  const _AreaLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BankSpotCard extends StatelessWidget {
  final _BankSampahSpot spot;
  final bool isSelected;
  final VoidCallback onTap;

  const _BankSpotCard({
    required this.spot,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.42)
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                spot.name,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                spot.address,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(spot.proximity)),
                  Chip(label: Text(spot.serviceInfo)),
                  ...spot.materials.map((item) => Chip(label: Text(item))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BankSampahSpot {
  final String name;
  final String shortLabel;
  final String address;
  final String serviceInfo;
  final List<String> materials;
  final String proximity;
  final String note;
  final double x;
  final double y;

  const _BankSampahSpot({
    required this.name,
    required this.shortLabel,
    required this.address,
    required this.serviceInfo,
    required this.materials,
    required this.proximity,
    required this.note,
    required this.x,
    required this.y,
  });
}
