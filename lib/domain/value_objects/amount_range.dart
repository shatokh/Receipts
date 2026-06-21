class AmountRange {
  const AmountRange({
    required this.min,
    required this.max,
  }) : assert(min <= max, 'AmountRange min must be <= max');

  static const receiptFilterDefault = AmountRange(min: 0, max: 1000);

  final double min;
  final double max;

  bool contains(double amount) {
    return amount >= min && amount <= max;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AmountRange && min == other.min && max == other.max;
  }

  @override
  int get hashCode => Object.hash(min, max);

  @override
  String toString() => '$min..$max';
}
