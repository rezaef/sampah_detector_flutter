import '../models/reward_item.dart';
import 'api_client.dart';

class RewardService {
  RewardService._();

  static final RewardService instance = RewardService._();

  Future<List<RewardItem>> loadRewards() async {
    final response = await ApiClient.instance.get('/mobile/rewards');
    final payload = response as Map<String, dynamic>;
    final rawItems = (payload['data'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();

    return rawItems.map(RewardItem.fromApiJson).toList();
  }

  Future<void> redeemReward(String rewardId) async {
    await ApiClient.instance.post('/mobile/rewards/$rewardId/redeem');
  }
}
