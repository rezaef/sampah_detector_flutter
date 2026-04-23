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
          _RewardHero(summary: summary),
          const SizedBox(height: 16),
          Row(
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
          const SizedBox(height: 24),
          const _RewardSectionHeader(
            title: 'Badge pengguna',
            subtitle:
                'Progres badge mengikuti akumulasi poin dan konsistensi penggunaan fitur.',
          ),
          const SizedBox(height: 12),
          SizedBox(
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
          const SizedBox(height: 24),
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
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.flag_outlined,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tantangan Aktif',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Buka halaman tantangan untuk melihat progres detail dan target berikutnya.',
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
          const SizedBox(height: 24),
          const _RewardSectionHeader(
            title: 'Reward aktif',
            subtitle:
                'Reward berikutnya ditampilkan langsung dari sistem backend.',
          ),
          const SizedBox(height: 12),
          if (_rewards.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Icon(
                      Icons.card_giftcard_outlined,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada reward aktif.',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._rewards.map(
              (reward) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RewardItemCard(
                  reward: reward,
                  currentPoints: summary.points,
                  isSubmitting: _isRedeeming,
                  onRedeem: () => _redeemReward(reward),
                ),
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
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF21409A), Color(0xFF4A78FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF21409A).withOpacity(0.16),
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
                    Icons.emoji_events,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Poin terkumpul',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white.withOpacity(0.86),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${summary.points} poin',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
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
                _RewardChip(
                  icon: Icons.workspace_premium_outlined,
                  label:
                      '${summary.badges.where((badge) => badge.isUnlocked).length} badge aktif',
                ),
                _RewardChip(
                  icon: Icons.today_outlined,
                  label: '${summary.uniqueScanDays} hari aktif',
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
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
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    final color = isUnlocked ? const Color(0xFFF5A623) : const Color(0xFFB7BDC7);

    return Container(
      width: 198,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isUnlocked
              ? color.withOpacity(0.45)
              : Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.14),
            foregroundColor: color,
            child: Icon(
              isUnlocked ? Icons.workspace_premium : Icons.lock_outline,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            badge.name,
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
              badge.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isUnlocked ? 'Aktif' : 'Butuh ${badge.minPoints} poin',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.card_giftcard_outlined,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reward.description.isEmpty
                            ? 'Reward aktif dari sistem poin.'
                            : reward.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('${reward.pointsCost} poin')),
                Chip(label: Text(reward.stock == null ? 'Stok tidak dibatasi' : 'Stok ${reward.stock}')),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (currentPoints / reward.pointsCost).clamp(0, 1),
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 10),
            Text(
              isOutOfStock
                  ? 'Stok reward sedang habis'
                  : isEligible
                      ? 'Syarat poin terpenuhi'
                      : '$remaining poin lagi untuk menukar reward ini',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (!isEligible || isOutOfStock || isSubmitting)
                    ? null
                    : onRedeem,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.redeem_outlined),
                label: Text(isOutOfStock ? 'Stok habis' : 'Tukar reward'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
