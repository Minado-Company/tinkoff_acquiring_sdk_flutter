import 'tinkoff_item.dart';

class TinkoffReceipt {
  final String shopCode;
  final String email;
  final String taxation;
  final String phone;
  final List<TinkoffItem> items;

  TinkoffReceipt(
      {this.shopCode, this.email, this.taxation, this.phone, this.items});

  Map<String, dynamic> toMap() {
    return {
      'shopCode': shopCode,
      'email': email,
      'taxation': taxation?.toString(),
      'phone': phone,
      'items': items?.map((x) => x?.toMap())?.toList(),
    };
  }
}
