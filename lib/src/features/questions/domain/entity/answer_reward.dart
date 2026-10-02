import 'package:equatable/equatable.dart';

/// Quarks paid by opening an answer, and the balance after the reveal.
class AnswerReward extends Equatable {
  final int quarksEarned;
  final int quarkBalance;

  const AnswerReward({
    required this.quarksEarned,
    required this.quarkBalance,
  });

  @override
  List<Object?> get props => [quarksEarned, quarkBalance];
}
