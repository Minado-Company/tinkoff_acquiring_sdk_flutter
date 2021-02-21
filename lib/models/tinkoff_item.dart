import 'tinkoff_tax.dart';

class TinkoffItem {
  // Сумма в копейка
  final int price;
  // Количество/вес
  final double quantity;
  // Наименование товара
  final String name;
  // Сумма * количество/вес
  final int amount;
  // Ставка НДС
  final TinkoffTax tax;

  TinkoffItem(this.price, this.quantity, this.name, this.amount,
      this.tax); // Tax? = null

  Map<String, dynamic> toMap() {
    return {
      'price': price,
      'quantity': quantity,
      'name': name,
      'amount': amount,
      'tax': tax?.toString(),
    };
  }
}
