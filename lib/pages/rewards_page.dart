import 'package:flutter/material.dart';

import '../models/gamification_models.dart';
import '../models/reward_item.dart';
import '../services/api_client.dart';
import '../services/gamification_service.dart';
import '../services/reward_service.dart';

class RewardsPage extends StatefulWidget {
  final int refreshToken;
  final VoidCallback onOpenChallenges;

  const RewardsPage({
    super.key,
    required this.refreshToken,
    required this.onOpenChallenges,
  });

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  bool _isLoading = true;
  bool _isRedeeming = false;
  AppGamificationSummary? _summary;
  List<RewardItem> _rewards = <RewardItem>[];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant RewardsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait<dynamic>([
        GamificationService.instance.buildSummary(),
        RewardService.instance.loadRewards(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _summary = results[0] as AppGamificationSummary;
        _rewards = results[1] as List<RewardItem>;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      _showMessage(_resolveMessage(error, fallback: 'Data reward gagal dimuat.'));
    }
  }

  Future<void> _redeemReward(RewardItem reward) async {
    final summary = _summary;
    if (summary == null || _isRedeeming) {
      return;
    }
    if (summary.points < reward.pointsCost) {
      _showMessage('Poin belum mencukupi untuk menukar reward ini.');
      return;
    }
    if (reward.isOutOfStock) {
      _showMessage('Stok reward sedang habis.');
      return;
    }

    setState(() {
      _isRedeeming = true;
    });

    try {
      await RewardService.instance.redeemReward(reward.id);
      if (!mounted) {
        return;
      }
      _showMessage('Reward berhasil ditukar.');
      await _loadData();
    } catch (error) {
      _showMessage(_resolveMessage(error, fallback: 'Penukaran reward gagal.'));
    } finally {
      if (mounted) {
        setState(() {
          _isRedeeming = false;
        });
      }
    }
  }

  String _resolveMessage(Object error, {required String fallback}) {
    if (error is ApiException) {
      return error.message;
    }
    return fallback;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _animateItem({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _summary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final summary = _summary!;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _animateItem(
            index: 0,
            child: _RewardHero(summary: summary),
          ),
          const SizedBox(height: 16),
          _animateItem(
            index: 1,
            child: Row(
              children: [
                Expanded(
                  child: _RewardStatCard(
                    title: 'Scan',
                    value: summary.totalScans.toString(),
                    icon: Icons.qr_code_scanner_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RewardStatCard(
                    title: 'Laporan',
                    value: summary.reportCount.toString(),
                    icon: Icons.report_gmailerrorred_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RewardStatCard(
                    title: 'Challenge',
                    value: summary.completedChallenges.toString(),
                    icon: Icons.flag_outlined,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _animateItem(
            index: 2,
            child: const _RewardSectionHeader(
              title: 'Badge pengguna',
              subtitle: 'Progres badge mengikuti akumulasi poin dan konsistensi penggunaan fitur.',
            ),
          ),
          const SizedBox(height: 12),
          _animateItem(
            index: 3,
            child: SizedBox(
              height: 196,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final badge = summary.badges[index];
                  return _BadgeCard(badge: badge);
                },
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: summary.badges.length,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _animateItem(
            index: 4,
            child: Container(
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
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F8A70).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.flag_outlined,
                            color: Color(0xFF1F8A70),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tantangan Aktif',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1B4D3E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Buka halaman tantangan untuk melihat progres detail dan target berikutnya.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFF507A6D),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: widget.onOpenChallenges,
                        icon: const Icon(Icons.arrow_forward_outlined),
                        label: const Text('Lihat tantangan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _animateItem(
            index: 5,
            child: const _RewardSectionHeader(
              title: 'Reward aktif',
              subtitle: 'Reward berikutnya ditampilkan langsung dari sistem backend.',
            ),
          ),
          const SizedBox(height: 12),
          _animateItem(
            index: 6,
            child: _rewards.isEmpty
                ? Container(
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
                        children: [
                          const Icon(
                            Icons.card_giftcard_outlined,
                            size: 40,
                            color: Color(0xFF1F8A70),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada reward aktif.',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF1B4D3E)),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: _rewards.asMap().entries.map(
                      (entry) {
                        final i = entry.key;
                        final reward = entry.value;
                        return TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 400 + (i * 120)),
                          curve: Curves.easeOutCubic,
                          builder: (context, val, child) {
                            return Transform.translate(
                              offset: Offset(0, 16 * (1 - val)),
                              child: Opacity(
                                opacity: val,
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _RewardItemCard(
                              reward: reward,
                              currentPoints: summary.points,
                              isSubmitting: _isRedeeming,
                              onRedeem: () => _redeemReward(reward),
                            ),
                          ),
                        );
                      },
                    ).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RewardHero extends StatelessWidget {
  final AppGamificationSummary summary;

  const _RewardHero({required this.summary});

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
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFFFA447),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Poin Terkumpul',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${summary.points} Poin',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _RewardChip(
                  icon: Icons.workspace_premium_rounded,
                  label:
                      '${summary.badges.where((badge) => badge.isUnlocked).length} Badge Aktif',
                ),
                _RewardChip(
                  icon: Icons.today_rounded,
                  label: '${summary.uniqueScanDays} Hari Aktif',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RewardChip({required this.icon, required this.label});

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
          Icon(icon, size: 15, color: Colors.white),
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

class _RewardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _RewardStatCard({
    required this.title,
    required this.value,
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
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1F8A70), size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1B4D3E),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8BA69D),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _RewardSectionHeader({required this.title, required this.subtitle});

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

class _BadgeCard extends StatelessWidget {
  final AppBadge badge;

  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    final isUnlocked = badge.isUnlocked;
    final color = isUnlocked ? const Color(0xFFFFA447) : const Color(0xFFB7BDC7);

    return Container(
      width: 198,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked
              ? color.withOpacity(0.4)
              : const Color(0xFF1F8A70).withOpacity(0.06),
          width: isUnlocked ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F8A70).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.12),
            foregroundColor: color,
            child: Icon(
              isUnlocked ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            badge.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              badge.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF6B8A80),
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isUnlocked ? 'Aktif' : 'Butuh ${badge.minPoints} Poin',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardItemCard extends StatelessWidget {
  final RewardItem reward;
  final int currentPoints;
  final bool isSubmitting;
  final VoidCallback onRedeem;

  const _RewardItemCard({
    required this.reward,
    required this.currentPoints,
    required this.isSubmitting,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final isEligible = currentPoints >= reward.pointsCost;
    final remaining = (reward.pointsCost - currentPoints).clamp(0, reward.pointsCost);
    final isOutOfStock = reward.isOutOfStock;
    final progress = (currentPoints / reward.pointsCost).clamp(0.0, 1.0);

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
        padding: const EdgeInsets.all(16),
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
                    color: const Color(0xFF1F8A70).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.card_giftcard_rounded,
                    color: Color(0xFF1F8A70),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reward.description.isEmpty
                            ? 'Reward aktif dari sistem poin.'
                            : reward.description,
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
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA447).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${reward.pointsCost} Poin',
                    style: const TextStyle(
                      color: Color(0xFFFFA447),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F8A70).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    reward.stock == null ? 'Stok tidak dibatasi' : 'Stok ${reward.stock}',
                    style: const TextStyle(
                      color: Color(0xFF1F8A70),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, val, child) {
                return LinearProgressIndicator(
                  value: val,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: const Color(0xFF1F8A70).withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF1F8A70)),
                );
              },
            ),
            const SizedBox(height: 10),
            Text(
              isOutOfStock
                  ? 'Stok reward sedang habis'
                  : isEligible
                      ? 'Syarat poin terpenuhi'
                      : '$remaining poin lagi untuk menukar reward ini',
              style: const TextStyle(
                color: Color(0xFF6B8A80),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (!isEligible || isOutOfStock || isSubmitting)
                    ? null
                    : onRedeem,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1F8A70),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.redeem_rounded, size: 20),
                label: Text(
                  isOutOfStock ? 'Stok Habis' : 'Tukar Reward',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
