class WalletModel {
  final int id;
  final double balance;
  final String currency;
  final String college;
  final String linkCode;
  final String userFullName;

  WalletModel({
    required this.id,
    required this.balance,
    required this.currency,
    required this.college,
    required this.linkCode,
    required this.userFullName,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    final rawBalance = json['balance'];
    final parsedBalance = rawBalance is num
        ? rawBalance.toDouble()
        : double.tryParse(rawBalance?.toString() ?? '') ?? 0.0;

    return WalletModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      balance: parsedBalance,
      currency: (json['currency'] ?? '').toString(),
      college: (json['college'] ?? '').toString(),
      linkCode: (json['link_code'] ?? '').toString(),
      userFullName: (json['user_full_name'] ?? json['full_name'] ?? '').toString(),
    );
  }
}
