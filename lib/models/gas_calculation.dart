/// Ephemeral calculator only. No persistence or journal mutations.
class GasCalculation {
  static const rate = 28.0;
  static const tank = 110.0;
  final double opening, received, distance, onHand;
  final double consumptionRate, tankLitres;
  GasCalculation({
    required this.opening,
    required this.received,
    required this.distance,
    required this.onHand,
    this.consumptionRate = rate,
    this.tankLitres = tank,
  }) {
    if (![
          opening,
          received,
          distance,
          onHand,
          consumptionRate,
          tankLitres,
        ].every((v) => v.isFinite) ||
        consumptionRate <= 0 ||
        tankLitres < 0 ||
        received < 0 ||
        distance < 0 ||
        onHand < 0) {
      throw ArgumentError('Проверьте значения расчёта');
    }
  }
  double get available => opening + received;
  double get consumption => distance * consumptionRate / 100;
  double get expected => available - consumption;
  double get actual => onHand + tankLitres;
  // Compare at the same precision displayed to the user (0.01 litre).
  double get difference => ((actual - expected) * 100).round() / 100;
  static double? parse(String value) {
    if (!RegExp(r'^\d{1,9}([.,]\d{0,2})?$').hasMatch(value)) return null;
    final result = double.tryParse(value.replaceAll(',', '.'));
    return result != null && result.isFinite ? result : null;
  }
}
