class CreditPackage {
  final int credits;
  final int price;
  final int discount;
  final String tag;

  const CreditPackage({
    required this.credits,
    required this.price,
    required this.discount,
    this.tag = '',
  });

  int get originalPrice =>
      discount > 0 ? (price / (1 - discount / 100)).round() : price;

  String get label =>
      '$credits Session${credits > 1 ? 's' : ''}';
}
