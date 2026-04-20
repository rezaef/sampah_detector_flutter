import 'package:flutter/material.dart';

class TpaPage extends StatefulWidget {
  const TpaPage({super.key});

  @override
  State<TpaPage> createState() => _TpaPageState();
}

class _TpaPageState extends State<TpaPage> {
  String _selectedFilter = 'Semua';

  final List<String> _filters = const [
    'Semua',
    'Anorganik',
    'Residu',
    'Jemput',
  ];

  final List<_FacilityItem> _locations = const [
    _FacilityItem(
      name: 'Bank Sampah Ketintang 17',
      address:
          'Jl. Ketintang Baru XVII No.43A, Ketintang, Kec. Gayungan, Surabaya 60231',
      serviceLabel: 'Setoran warga sekitar',
      acceptedTypes: ['Anorganik'],
      description:
          'Titik setoran terdekat dari area kampus untuk plastik, kertas, dan logam yang sudah dipilah.',
    ),
    _FacilityItem(
      name: 'BuDi Ketintang',
      address: 'Jalan Inajadulu No.17, Ketintang, Gayungan, Surabaya 60231',
      serviceLabel: 'Drop point & pick up',
      acceptedTypes: ['Anorganik', 'Jemput'],
      description:
          'Layanan drop point untuk sampah terpilah serta pick up untuk disalurkan ke daur ulang atau ke fasilitas akhir kota.',
    ),
    _FacilityItem(
      name: 'TPA Benowo',
      address: 'Kelurahan Sumberrejo, Kecamatan Pakal, Surabaya',
      serviceLabel: 'Rujukan akhir kota',
      acceptedTypes: ['Residu'],
      description:
          'Tempat pemrosesan akhir Surabaya. Cocok dijadikan referensi alur pembuangan residu setelah pemilahan di sumber atau bank sampah.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visibleLocations = _selectedFilter == 'Semua'
        ? _locations
        : _locations
            .where((item) => item.acceptedTypes.contains(_selectedFilter))
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Lokasi Pengelolaan Sampah')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF374151), Color(0xFF6B7280)],
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
                    'Rujukan pembuangan sekitar Ketintang dari setoran terpilah hingga fasilitas akhir kota.',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Acuan lokasi dimulai dari Telkom University Surabaya, Jl. Ketintang No.156.',
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
            children: _filters.map((filter) {
              return ChoiceChip(
                selected: _selectedFilter == filter,
                label: Text(filter),
                onSelected: (_) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          ...visibleLocations.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FacilityCard(item: item),
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityCard extends StatelessWidget {
  final _FacilityItem item;

  const _FacilityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              item.address,
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
                  label: Text(item.serviceLabel),
                ),
                ...item.acceptedTypes.map((type) => Chip(label: Text(type))),
              ],
            ),
            const SizedBox(height: 12),
            Text(item.description),
          ],
        ),
      ),
    );
  }
}

class _FacilityItem {
  final String name;
  final String address;
  final String serviceLabel;
  final List<String> acceptedTypes;
  final String description;

  const _FacilityItem({
    required this.name,
    required this.address,
    required this.serviceLabel,
    required this.acceptedTypes,
    required this.description,
  });
}
