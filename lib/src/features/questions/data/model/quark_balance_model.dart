class QuarkBalanceModel {
  final int quarkBalance;

  const QuarkBalanceModel({required this.quarkBalance});

  factory QuarkBalanceModel.fromJson(Map<String, dynamic> json) {
    return QuarkBalanceModel(quarkBalance: json['quark_balance'] as int);
  }
}
