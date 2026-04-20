import 'package:flutter/material.dart';

import '../models/environmental_report.dart';
import '../models/gamification_models.dart';
import '../models/history_entry.dart';
import '../services/gamification_service.dart';
import '../services/history_service.dart';
import '../services/report_service.dart';

enum AppFeature {
  detect,
  history,
  sortingGuide,
  education,
  rewards,
  report,
  challenges,
  tpa,
  bankSampah,
}

class DashboardPage extends StatefulWidget {
  final int refreshToken;
  final void Function(AppFeature feature) onOpenFeature;

  const DashboardPage({
    super.key,
    required this.refreshToken,
    required this.onOpenFeature,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  AppGamificationSummary? _summary;
  DetectionHistoryItem? _latestHistory;
  EnvironmentalReport? _latestReport;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadDashboard();
    }
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
    });

    final summary = await GamificationService.instance.buildSummary();
    final history = await HistoryService.instance.loadHistory();
    final reports = await ReportService.instance.loadReports();

    if (!mounted) {
      return;
    }

    setState(() {
      _summary = summary;
      _latestHistory = history.isEmpty ? null : history.first;
      _latestReport = reports.isEmpty ? null : reports.first;
      _isLoading = false;
    });
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _summary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final summary = _summary!;
    final activeChallenge = summary.challenges.firstWhere(
      (challenge) => !challenge.isCompleted,
      orElse: () => summary.challenges.first,
    );

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _DashboardHero(summary: summary),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(
                title: 'Total Scan',
                value: summary.totalScans.toString(),
                icon: Icons.qr_code_scanner_outlined,
              ),
              _StatCard(
                title: 'Organik',
                value: summary.organicCount.toString(),
                icon: Icons.eco_outlined,
              ),
              _StatCard(
                title: 'Anorganik',
                value: summary.anorganicCount.toString(),
                icon: Icons.recycling_outlined,
              ),
              _StatCard(
                title: 'Poin',
                value: summary.points.toString(),
                icon: Icons.stars_outlined,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionHeader(
            title: 'Menu utama',
            subtitle:
                'Akses cepat ke fitur inti pengelolaan sampah.',
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 0.86,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _FeatureCard(
                title: 'Scan Sampah',
                subtitle: 'Kamera, galeri, preprocessing, dan klasifikasi.',
                icon: Icons.camera_alt_outlined,
                onTap: () => widget.onOpenFeature(AppFeature.detect),
              ),
              _FeatureCard(
                title: 'Riwayat Scan',
                subtitle: 'Riwayat lengkap dengan hapus satuan dan massal.',
                icon: Icons.history_outlined,
                onTap: () => widget.onOpenFeature(AppFeature.history),
              ),
              _FeatureCard(
                title: 'Panduan Pemilahan',
                subtitle: 'Alur pembuangan, contoh, dan langkah lanjutan.',
                icon: Icons.rule_folder_outlined,
                onTap: () => widget.onOpenFeature(AppFeature.sortingGuide),
              ),
              _FeatureCard(
                title: 'Edukasi Lingkungan',
                subtitle: 'Artikel singkat, tips, dan insight pengelolaan sampah.',
                icon: Icons.menu_book_outlined,
                onTap: () => widget.onOpenFeature(AppFeature.education),
              ),
              _FeatureCard(
                title: 'Reward & Point',
                subtitle: 'Poin, badge, dan leaderboard pengguna aktif.',
                icon: Icons.emoji_events_outlined,
                onTap: () => widget.onOpenFeature(AppFeature.rewards),
              ),
              _FeatureCard(
                title: 'Laporan Lingkungan',
                subtitle: 'Buat laporan lokasi sampah lengkap dengan foto.',
                icon: Icons.report_gmailerrorred_outlined,
                onTap: () => widget.onOpenFeature(AppFeature.report),
              ),
              _FeatureCard(
                title: 'Eco Challenges',
                subtitle: 'Tantangan mingguan untuk mendorong konsistensi.',
                icon: Icons.flag_outlined,
                onTap: () => widget.onOpenFeature(AppFeature.challenges),
              ),
              _FeatureCard(
                title: 'Lokasi Pengelolaan',
                subtitle: 'Ketintang, drop point, dan rujukan akhir kota.',
                icon: Icons.delete_outline,
                onTap: () => widget.onOpenFeature(AppFeature.tpa),
              ),
              _FeatureCard(
                title: 'Peta Bank Sampah',
                subtitle: 'Ketintang, Gayungan, dan rujukan bank sampah kota.',
                icon: Icons.map_outlined,
                onTap: () => widget.onOpenFeature(AppFeature.bankSampah),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionHeader(
            title: 'Aktivitas terbaru',
            subtitle:
                'Ringkasan hasil scan terakhir dan laporan lingkungan terbaru.',
          ),
          const SizedBox(height: 12),
          if (_latestHistory != null)
            _ActivityCard(
              title: 'Klasifikasi terakhir',
              subtitle: _latestHistory!.result.label,
              description:
                  'Kepercayaan ${_latestHistory!.result.confidenceLabel} - ${_latestHistory!.result.recommendation}',
              icon: Icons.auto_awesome_outlined,
              footer: _formatDate(_latestHistory!.createdAt),
            )
          else
            const _ActivityCard(
              title: 'Klasifikasi terakhir',
              subtitle: 'Belum ada riwayat scan',
              description:
                  'Mulai dengan memilih gambar dari kamera atau galeri pada menu deteksi.',
              icon: Icons.photo_camera_back_outlined,
              footer: 'Siap digunakan',
            ),
          const SizedBox(height: 12),
          if (_latestReport != null)
            _ActivityCard(
              title: 'Laporan lingkungan terbaru',
              subtitle: _latestReport!.title,
              description:
                  '${_latestReport!.locationName} - ${_latestReport!.status}',
              icon: Icons.location_on_outlined,
              footer: _formatDate(_latestReport!.createdAt),
            )
          else
            const _ActivityCard(
              title: 'Laporan lingkungan terbaru',
              subtitle: 'Belum ada laporan masuk',
              description:
                  'Fitur laporan siap dipakai untuk mencatat titik penumpukan sampah.',
              icon: Icons.assignment_outlined,
              footer: 'Akses cepat dari dashboard',
            ),
          const SizedBox(height: 24),
          const _SectionHeader(
            title: 'Challenge aktif',
            subtitle:
                'Progress tantangan langsung dihitung dari aktivitas scan dan laporan.',
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.flag_rounded,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeChallenge.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(activeChallenge.description),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: activeChallenge.completionRatio,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${activeChallenge.progress}/${activeChallenge.target} progres',
                      ),
                      Text(
                        '+${activeChallenge.rewardPoints} poin',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  final AppGamificationSummary summary;

  const _DashboardHero({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF1F8A70), Color(0xFF5BC0A5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F8A70).withOpacity(0.16),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.recycling_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sampah Detector',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Platform mobile untuk scan, edukasi, gamifikasi, laporan, dan informasi lokasi.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.94),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HeroChip(
                  icon: Icons.stars_outlined,
                  label: '${summary.points} poin',
                ),
                _HeroChip(
                  icon: Icons.workspace_premium_outlined,
                  label: '${summary.completedChallenges} challenge selesai',
                ),
                _HeroChip(
                  icon: Icons.monitor_heart_outlined,
                  label: '${summary.reportCount} laporan lingkungan',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 44) / 2;

    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimaryContainer,
                ),
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
                          .bodyMedium
                          ?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Buka fitur',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
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
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color:
                    Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final String footer;
  final IconData icon;

  const _ActivityCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.footer,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer,
              ),
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
                        .labelLarge
                        ?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(description),
                  const SizedBox(height: 8),
                  Text(
                    footer,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
