import '../models/classification_result.dart';
import '../models/gamification_models.dart';
import 'history_service.dart';
import 'report_service.dart';

class GamificationService {
  GamificationService._();

  static final GamificationService instance = GamificationService._();

  Future<AppGamificationSummary> buildSummary() async {
    final history = await HistoryService.instance.loadHistory();
    final reports = await ReportService.instance.loadReports();

    final organicCount = history
        .where((item) => item.result.category == WasteCategory.organik)
        .length;
    final anorganicCount = history
        .where((item) => item.result.category == WasteCategory.anorganik)
        .length;
    final uniqueScanDays = history
        .map((item) =>
            '${item.createdAt.year}-${item.createdAt.month}-${item.createdAt.day}')
        .toSet()
        .length;

    final challenges = <ChallengeProgress>[
      ChallengeProgress(
        id: 'scan-5',
        title: 'Scan 5 sampah',
        description:
            'Selesaikan lima proses klasifikasi untuk membuka progres awal.',
        target: 5,
        progress: history.length,
        rewardPoints: 40,
      ),
      ChallengeProgress(
        id: 'organic-3',
        title: 'Pisahkan 3 sampah organik',
        description:
            'Kumpulkan minimal tiga hasil klasifikasi organik di riwayat.',
        target: 3,
        progress: organicCount,
        rewardPoints: 30,
      ),
      ChallengeProgress(
        id: 'anorganic-3',
        title: 'Pisahkan 3 sampah anorganik',
        description:
            'Kumpulkan minimal tiga hasil klasifikasi anorganik di riwayat.',
        target: 3,
        progress: anorganicCount,
        rewardPoints: 30,
      ),
      ChallengeProgress(
        id: 'report-1',
        title: 'Kirim 1 laporan lingkungan',
        description:
            'Laporkan satu titik sampah di area sekitar.',
        target: 1,
        progress: reports.length,
        rewardPoints: 50,
      ),
      ChallengeProgress(
        id: 'active-3-days',
        title: 'Aktif 3 hari berbeda',
        description:
            'Gunakan aplikasi di tiga hari yang berbeda untuk menjaga konsistensi.',
        target: 3,
        progress: uniqueScanDays,
        rewardPoints: 60,
      ),
    ];

    final challengePoints = challenges
        .where((challenge) => challenge.isCompleted)
        .fold<int>(0, (total, challenge) => total + challenge.rewardPoints);

    final basePoints = (history.length * 12) +
        (organicCount * 4) +
        (anorganicCount * 4) +
        (reports.length * 25);
    final points = basePoints + challengePoints;

    final badges = <AppBadge>[
      AppBadge(
        name: 'Eco Starter',
        description: 'Aktif mulai memilah sampah dengan konsisten.',
        minPoints: 50,
        isUnlocked: points >= 50,
      ),
      AppBadge(
        name: 'Waste Warrior',
        description: 'Rajin scan dan melaporkan kondisi lingkungan.',
        minPoints: 150,
        isUnlocked: points >= 150,
      ),
      AppBadge(
        name: 'Green Guardian',
        description: 'Menjaga ritme pemilahan dan aksi lingkungan.',
        minPoints: 280,
        isUnlocked: points >= 280,
      ),
      AppBadge(
        name: 'Circular Champion',
        description: 'Level tertinggi untuk pengguna paling aktif.',
        minPoints: 420,
        isUnlocked: points >= 420,
      ),
    ];

    final leaderboard = <LeaderboardEntry>[
      const LeaderboardEntry(name: 'Alya', points: 420),
      const LeaderboardEntry(name: 'Bima', points: 360),
      const LeaderboardEntry(name: 'Citra', points: 290),
      const LeaderboardEntry(name: 'Dion', points: 210),
      LeaderboardEntry(
        name: 'Pengguna aktif',
        points: points,
        isCurrentUser: true,
      ),
    ]..sort((a, b) => b.points.compareTo(a.points));

    final currentRank =
        leaderboard.indexWhere((entry) => entry.isCurrentUser) + 1;

    return AppGamificationSummary(
      points: points,
      totalScans: history.length,
      organicCount: organicCount,
      anorganicCount: anorganicCount,
      reportCount: reports.length,
      uniqueScanDays: uniqueScanDays,
      completedChallenges:
          challenges.where((challenge) => challenge.isCompleted).length,
      currentRank: currentRank <= 0 ? leaderboard.length : currentRank,
      badges: badges,
      challenges: challenges,
      leaderboard: leaderboard,
    );
  }
}
