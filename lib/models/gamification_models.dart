class AppBadge {
  final String name;
  final String description;
  final int minPoints;
  final bool isUnlocked;

  const AppBadge({
    required this.name,
    required this.description,
    required this.minPoints,
    required this.isUnlocked,
  });
}

class ChallengeProgress {
  final String id;
  final String title;
  final String description;
  final int target;
  final int progress;
  final int rewardPoints;

  const ChallengeProgress({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.progress,
    required this.rewardPoints,
  });

  bool get isCompleted => progress >= target;

  double get completionRatio {
    if (target <= 0) {
      return 0;
    }
    final ratio = progress / target;
    if (ratio < 0) {
      return 0;
    }
    if (ratio > 1) {
      return 1;
    }
    return ratio;
  }
}

class LeaderboardEntry {
  final String name;
  final int points;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.name,
    required this.points,
    this.isCurrentUser = false,
  });
}

class AppGamificationSummary {
  final int points;
  final int totalScans;
  final int organicCount;
  final int anorganicCount;
  final int reportCount;
  final int uniqueScanDays;
  final int completedChallenges;
  final int currentRank;
  final List<AppBadge> badges;
  final List<ChallengeProgress> challenges;
  final List<LeaderboardEntry> leaderboard;

  const AppGamificationSummary({
    required this.points,
    required this.totalScans,
    required this.organicCount,
    required this.anorganicCount,
    required this.reportCount,
    required this.uniqueScanDays,
    required this.completedChallenges,
    required this.currentRank,
    required this.badges,
    required this.challenges,
    required this.leaderboard,
  });
}
