import '../models/classification_result.dart';
import '../models/gamification_models.dart';
import 'api_client.dart';
import 'history_service.dart';

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

class GamificationService {
  GamificationService._();

  static final GamificationService instance = GamificationService._();

  Future<AppGamificationSummary> buildSummary() async {
    final history = await HistoryService.instance.loadHistory();

    try {
      final response = await ApiClient.instance.get('/mobile/dashboard');
      final payload = response as Map<String, dynamic>;
      final rawChallenges =
          (payload['active_challenges'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList();

      final challenges = rawChallenges.isEmpty
          ? <ChallengeProgress>[
              ChallengeProgress(
                id: 'default-scan',
                title: 'Aktivitas Scan',
                description:
                    'Lakukan klasifikasi untuk mulai membangun progres aktivitas.',
                target: 1,
                progress: _toInt(payload['total_scans']),
                rewardPoints: 10,
              ),
            ]
          : rawChallenges
              .map(
                (item) => ChallengeProgress(
                  id: item['id'].toString(),
                  title: (item['title'] ?? 'Challenge').toString(),
                  description: (item['description'] ?? '').toString(),
                  target: _toInt(item['target']),
                  progress: _toInt(item['progress']),
                  rewardPoints: _toInt(item['reward_points']),
                ),
              )
              .toList();

      final uniqueScanDays = history
          .map(
            (item) =>
                '${item.createdAt.year}-${item.createdAt.month}-${item.createdAt.day}',
          )
          .toSet()
          .length;

      final points = _toInt(payload['points']);
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

      return AppGamificationSummary(
        points: points,
        totalScans: _toInt(payload['total_scans']),
        organicCount: _toInt(payload['organic_count']),
        anorganicCount: _toInt(payload['anorganic_count']),
        reportCount: _toInt(payload['report_count']),
        uniqueScanDays: uniqueScanDays,
        completedChallenges:
            payload.containsKey('completed_challenges')
                ? _toInt(payload['completed_challenges'])
                : challenges.where((item) => item.isCompleted).length,
        currentRank: 1,
        badges: badges,
        challenges: challenges,
        leaderboard: [
          LeaderboardEntry(
            name: 'Pengguna Aktif',
            points: points,
            isCurrentUser: true,
          ),
        ],
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        return const AppGamificationSummary(
          points: 0,
          totalScans: 0,
          organicCount: 0,
          anorganicCount: 0,
          reportCount: 0,
          uniqueScanDays: 0,
          completedChallenges: 0,
          currentRank: 1,
          badges: [],
          challenges: [
            ChallengeProgress(
              id: 'default-scan',
              title: 'Aktivitas Scan',
              description: 'Mulai klasifikasi untuk melihat progres.',
              target: 1,
              progress: 0,
              rewardPoints: 10,
            ),
          ],
          leaderboard: [
            LeaderboardEntry(name: 'Pengguna Aktif', points: 0, isCurrentUser: true),
          ],
        );
      }
      rethrow;
    }
  }
}
