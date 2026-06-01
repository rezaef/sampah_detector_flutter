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

class _EcoChallengesPageState extends State<EcoChallengesPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  AppGamificationSummary? _summary;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadSummary();
  }

  @override
  void didUpdateWidget(covariant EcoChallengesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadSummary();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
    _animationController.forward(from: 0.0);
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

    // Staggered animations for headers
    final headerFade = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    );
    final headerSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ));

    final titleFade = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.15, 0.65, curve: Curves.easeOutCubic),
    );
    final titleSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.15, 0.65, curve: Curves.easeOutCubic),
    ));

    return Scaffold(
      appBar: AppBar(title: const Text('Tantangan Aktif')),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            FadeTransition(
              opacity: headerFade,
              child: SlideTransition(
                position: headerSlide,
                child: Container(
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
                        Text(
                          'Target mingguan Anda',
                          style: TextStyle(color: Colors.white.withOpacity(0.82), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$completed / ${summary.challenges.length} Misi Selesai',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ChallengeChip(
                              icon: Icons.stars_rounded,
                              label: '+$totalRewardPoints Poin',
                            ),
                            _ChallengeChip(
                              icon: Icons.today_outlined,
                              label: '${summary.uniqueScanDays} Hari Aktif',
                            ),
                            _ChallengeChip(
                              icon: Icons.qr_code_scanner_outlined,
                              label: '${summary.totalScans} Scan',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: titleFade,
              child: SlideTransition(
                position: titleSlide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daftar Tantangan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B4D3E),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Semua progres dihitung otomatis dari aktivitas scan, laporan, dan konsistensi penggunaan.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B8A80),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...summary.challenges.asMap().entries.map(
              (entry) {
                final index = entry.key;
                final challenge = entry.value;
                
                final double start = (0.2 + (index * 0.08)).clamp(0.0, 0.5);
                final double end = (start + 0.5).clamp(0.0, 1.0);
                
                final itemFade = CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(start, end, curve: Curves.easeOutCubic),
                );
                
                final itemSlide = Tween<Offset>(
                  begin: const Offset(0.0, 0.08),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(start, end, curve: Curves.easeOutCubic),
                ));

                return FadeTransition(
                  opacity: itemFade,
                  child: SlideTransition(
                    position: itemSlide,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ChallengeCard(challenge: challenge),
                    ),
                  ),
                );
              },
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
        color: Colors.white.withOpacity(0.12),
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
              fontSize: 12,
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
    final accent = isCompleted ? const Color(0xFF16A34A) : const Color(0xFF1F8A70);
    final pointsColor = isCompleted ? const Color(0xFF16A34A) : const Color(0xFFFFA447);

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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_iconForChallenge(), color: accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        challenge.description,
                        style: const TextStyle(
                          color: Color(0xFF507A6D),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: pointsColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isCompleted ? 'Selesai' : '+${challenge.rewardPoints} poin',
                    style: TextStyle(
                      color: pointsColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: challenge.completionRatio),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(999),
                  color: accent,
                  backgroundColor: accent.withOpacity(0.08),
                );
              },
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${challenge.progress}/${challenge.target} progres',
                  style: const TextStyle(
                    color: Color(0xFF6B8A80),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
                Text(
                  isCompleted ? 'Target tercapai' : 'Lanjutkan aktivitas',
                  style: TextStyle(
                    color: isCompleted ? const Color(0xFF16A34A) : const Color(0xFF1F8A70),
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
