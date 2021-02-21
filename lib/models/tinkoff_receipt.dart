import 'package:tinkoff_acquiring_sdk/models/tinkoff_taxation.dart';

import 'tinkoff_item.dart';
import '../extensions.dart';

class TinkoffReceipt {
  final String shopCode;
  final String email;
  final TinkoffTaxation taxation;
  final String phone;
  final List<TinkoffItem> items;

  TinkoffReceipt(
      {this.shopCode, this.email, this.taxation, this.phone, this.items});

  Map<String, dynamic> toMap() {
    return {
      'shopCode': shopCode,
      'email': email,
      'taxation': taxation?.toEnumString(),
      'phone': phone,
      'items': items?.map((x) => x?.toMap())?.toList(),
    };
  }
}
