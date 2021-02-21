class TinkoffShop {
  final String shopCode;
  final String name;
  final int amount;
  final String fee;

  TinkoffShop({
    this.shopCode,
    this.name,
    this.amount,
    this.fee,
  });

  Map<String, dynamic> toMap() {
    return {
      'shopCode': shopCode,
      'name': name,
      'amount': amount,
      'fee': fee,
    };
  }
}
