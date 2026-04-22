import 'package:flutter/material.dart';

import '../models/gamification_models.dart';
import '../services/gamification_service.dart';

class EcoChallengesPage extends StatefulWidget {
  final int refreshToken;

  const EcoChallengesPage({
    super.key,
    required this.refreshToken,
  });

  @override
  State<EcoChallengesPage> createState() => _EcoChallengesPageState();
}

class _EcoChallengesPageState extends State<EcoChallengesPage> {
  bool _isLoading = true;
  AppGamificationSummary? _summary;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  @override
  void didUpdateWidget(covariant EcoChallengesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadSummary();
    }
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
    });
    final summary = await GamificationService.instance.buildSummary();
    if (!mounted) {
      return;
    }
    setState(() {
      _summary = summary;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _summary == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final summary = _summary!;
    final completed = summary.challenges.where((item) => item.isCompleted).length;
    final totalRewardPoints = summary.challenges
        .where((item) => item.isCompleted)
        .fold<int>(0, (total, item) => total + item.rewardPoints);

    return Scaffold(
      appBar: AppBar(title: const Text('Tantangan Aktif')),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF22C55E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F766E).withOpacity(0.14),
                    blurRadius: 24,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target mingguan pengguna',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: Colors.white.withOpacity(0.9)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$completed / ${summary.challenges.length} challenge selesai',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ChallengeChip(
                          icon: Icons.stars_outlined,
                          label: '+$totalRewardPoints poin reward',
                        ),
                        _ChallengeChip(
                          icon: Icons.today_outlined,
                          label: '${summary.uniqueScanDays} hari aktif',
                        ),
                        _ChallengeChip(
                          icon: Icons.qr_code_scanner_outlined,
                          label: '${summary.totalScans} total scan',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Daftar tantangan',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Semua progres dihitung otomatis dari aktivitas scan, laporan, dan konsistensi penggunaan.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            ...summary.challenges.map(
              (challenge) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ChallengeCard(challenge: challenge),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ChallengeChip({required this.icon, required this.label});

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

class _ChallengeCard extends StatelessWidget {
  final ChallengeProgress challenge;

  const _ChallengeCard({required this.challenge});

  IconData _iconForChallenge() {
    switch (challenge.id) {
      case 'scan-5':
        return Icons.qr_code_scanner_outlined;
      case 'organic-3':
        return Icons.eco_outlined;
      case 'anorganic-3':
        return Icons.recycling_outlined;
      case 'report-1':
        return Icons.report_gmailerrorred_outlined;
      default:
        return Icons.calendar_month_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = challenge.isCompleted;
    final accent = isCompleted
        ? const Color(0xFF16A34A)
        : Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(_iconForChallenge(), color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        challenge.description,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isCompleted ? 'Selesai' : '+${challenge.rewardPoints} poin',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: challenge.completionRatio,
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
              color: accent,
              backgroundColor: accent.withOpacity(0.12),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${challenge.progress}/${challenge.target} progres'),
                Text(
                  isCompleted ? 'Target tercapai' : 'Lanjutkan aktivitas',
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
    );
  }
}
