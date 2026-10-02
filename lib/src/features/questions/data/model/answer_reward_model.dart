import '../../domain/entity/answer_reward.dart';

class AnswerRewardModel {
  final int quarksEarned;
  final int quarkBalance;

  const AnswerRewardModel({
    required this.quarksEarned,
    required this.quarkBalance,
  });

  factory AnswerRewardModel.fromJson(Map<String, dynamic> json) {
    return AnswerRewardModel(
      quarksEarned: json['quarks_earned'] as int,
      quarkBalance: json['quark_balance'] as int,
    );
  }

  AnswerReward toEntity() => AnswerReward(
        quarksEarned: quarksEarned,
        quarkBalance: quarkBalance,
      );
}
