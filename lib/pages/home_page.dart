import 'package:flutter/material.dart';

import '../models/classification_result.dart';
import '../models/environmental_report.dart';
import '../models/gamification_models.dart';
import '../models/history_entry.dart';
import '../services/auth_service.dart';
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
  String _organicAverageConfidenceLabel = '-';
  String _anorganicAverageConfidenceLabel = '-';

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
      _organicAverageConfidenceLabel = _buildAverageConfidenceLabel(
        history,
        WasteCategory.organik,
      );
      _anorganicAverageConfidenceLabel = _buildAverageConfidenceLabel(
        history,
        WasteCategory.anorganik,
      );
      _isLoading = false;
    });
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String _buildAverageConfidenceLabel(
    List<DetectionHistoryItem> history,
    WasteCategory category,
  ) {
    final filtered = history
        .where((item) => item.result.category == category)
        .toList();

    if (filtered.isEmpty) {
      return 'Belum ada data';
    }

    final total = filtered.fold<double>(
      0,
      (sum, item) => sum + item.result.confidence,
    );
    final average = (total / filtered.length) * 100;
    return 'Rata-rata ${average.toStringAsFixed(1)}%';
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
          _DashboardHero(
            summary: summary,
            userName: AuthService.instance.currentUser?.displayName,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total Scan',
                  value: summary.totalScans.toString(),
                  icon: Icons.qr_code_scanner_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Poin',
                  value: summary.points.toString(),
                  icon: Icons.stars_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Organik',
                  value: summary.organicCount.toString(),
                  icon: Icons.eco_outlined,
                  subtitle: _organicAverageConfidenceLabel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Anorganik',
                  value: summary.anorganicCount.toString(),
                  icon: Icons.recycling_outlined,
                  subtitle: _anorganicAverageConfidenceLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionHeader(
            title: 'Menu utama',
            subtitle:
                'Fitur lengkap untuk deteksi, edukasi, dan pengelolaan sampah.',
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
                subtitle: 'Klasifikasi sampah organik/anorganik menggunakan model MobileNetV2.',
                icon: Icons.camera_alt_outlined,
                onTap: () => widget.onOpenFeature(AppFeature.detect),
              ),
              _FeatureCard(
                title: 'Panduan Pemilahan',
                subtitle: 'Cara memilah sampah dengan benar beserta contoh per kategori.',
                icon: Icons.rule_folder_outlined,
                onTap: () => widget.onOpenFeature(AppFeature.sortingGuide),
              ),
              _FeatureCard(
                title: 'Edukasi Lingkungan',
                subtitle: 'Artikel tentang daur ulang, dampak sampah, dan tips ramah lingkungan.',
                icon: Icons.menu_book_outlined,
                onTap: () => widget.onOpenFeature(AppFeature.education),
              ),
              _FeatureCard(
                title: 'Tantangan Eco',
                subtitle: 'Selesaikan misi mingguan untuk mendapatkan poin dan badge.',
                icon: Icons.flag_outlined,
                onTap: () => widget.onOpenFeature(AppFeature.challenges),
              ),
              _FeatureCard(
                title: 'Laporan Lingkungan',
                subtitle: 'Laporkan lokasi penumpukan sampah beserta dokumentasi foto.',
                icon: Icons.report_gmailerrorred_outlined,
                onTap: () => widget.onOpenFeature(AppFeature.report),
              ),
              _FeatureCard(
                title: 'Peta Lokasi Sampah',
                subtitle: 'Cari TPS, TPA, bank sampah, dan drop point terdekat.',
                icon: Icons.map_outlined,
                onTap: () => widget.onOpenFeature(AppFeature.bankSampah),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionHeader(
            title: 'Aktivitas terbaru',
            subtitle:
                'Hasil scan dan laporan lingkungan terkini dari akun Anda.',
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
              subtitle: 'Belum ada riwayat klasifikasi',
              description:
                  'Buka menu Scan Sampah untuk memulai klasifikasi gambar pertama Anda.',
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
              subtitle: 'Belum ada laporan',
              description:
                  'Gunakan fitur Laporan Lingkungan untuk mendokumentasikan titik penumpukan sampah di sekitar Anda.',
              icon: Icons.assignment_outlined,
              footer: 'Buka melalui menu utama',
            ),
          const SizedBox(height: 24),
          const _SectionHeader(
            title: 'Tantangan aktif',
            subtitle:
                'Progres tantangan dihitung otomatis berdasarkan jumlah scan dan laporan Anda.',
          ),
          const SizedBox(height: 12),
          Container(
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
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F8A70).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.flag_rounded,
                          color: Color(0xFF1F8A70),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeChallenge.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1B4D3E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activeChallenge.description,
                              style: const TextStyle(
                                color: Color(0xFF507A6D),
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: activeChallenge.completionRatio,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: const Color(0xFF1F8A70).withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF1F8A70)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${activeChallenge.progress}/${activeChallenge.target} progres',
                        style: const TextStyle(
                          color: Color(0xFF6B8A80),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '+${activeChallenge.rewardPoints} poin',
                        style: const TextStyle(
                          color: Color(0xFFFFA447),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
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
  final String? userName;

  const _DashboardHero({
    required this.summary,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.forest_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName == null || userName!.trim().isEmpty
                            ? 'Selamat datang'
                            : 'Hai, ${userName!.trim()}!',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mari wujudkan lingkungan bersih hari ini.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _HeroStat(
                    icon: Icons.stars_rounded,
                    value: '${summary.points}',
                    label: 'Poin',
                  ),
                  Container(
                    height: 32,
                    width: 1,
                    color: Colors.white.withOpacity(0.15),
                  ),
                  _HeroStat(
                    icon: Icons.verified_rounded,
                    value: '${summary.completedChallenges}',
                    label: 'Misi',
                  ),
                  Container(
                    height: 32,
                    width: 1,
                    color: Colors.white.withOpacity(0.15),
                  ),
                  _HeroStat(
                    icon: Icons.assignment_turned_in_rounded,
                    value: '${summary.reportCount}',
                    label: 'Laporan',
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

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeroStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFFFFA447)),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPoints = title.toLowerCase().contains('poin');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isPoints 
                    ? const Color(0xFFFFA447).withOpacity(0.12)
                    : const Color(0xFF1F8A70).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isPoints ? const Color(0xFFFFA447) : const Color(0xFF1F8A70),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6B8A80),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1B4D3E),
                      fontSize: 20,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF8BA69D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
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
    final theme = Theme.of(context);

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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F8A70).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF1F8A70),
                    size: 22,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1B4D3E),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6B8A80),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Buka Fitur',
                      style: TextStyle(
                        color: const Color(0xFF1F8A70),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: Color(0xFF1F8A70),
                    ),
                  ],
                ),
              ],
            ),
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1B4D3E),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B8A80),
            fontWeight: FontWeight.w500,
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
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1F8A70).withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF1F8A70),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF8BA69D),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1B4D3E),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF507A6D),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    footer,
                    style: const TextStyle(
                      color: Color(0xFF8BA69D),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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
