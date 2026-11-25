import '../../../shared/domain/utils/formatters.dart';

// ReviewDeadlinePolicyResource: el plazo que aplica a los casos que se abren ahora para los Estudiantes de un plan.
class ReviewDeadlinePolicy {
  final String plan; // Premium (mensual) | Free
  final int amount;
  final String unit; // Hours | BusinessDays
  final bool definedBySenior; // false mientras el plan conserva su plazo propio
  final DateTime? updatedAt;

  const ReviewDeadlinePolicy({
    required this.plan,
    required this.amount,
    required this.unit,
    required this.definedBySenior,
    required this.updatedAt,
  });

  // Límites que acepta el backend: hasta 48 horas (mensual) y hasta 5 días hábiles (gratuito).
  static const premiumMaxHours = 48;
  static const freeMaxBusinessDays = 5;

  static const premium = 'Premium';
  static const free = 'Free';

  factory ReviewDeadlinePolicy.fromJson(Map<String, dynamic> json) => ReviewDeadlinePolicy(
        plan: (json['plan'] ?? '') as String,
        amount: (json['amount'] as num? ?? 0).toInt(),
        unit: (json['unit'] ?? 'Hours') as String,
        definedBySenior: (json['definedBySenior'] ?? false) as bool,
        updatedAt: parseDate(json['updatedAt']),
      );

  String get planLabel => plan == premium ? 'Plan mensual' : 'Plan gratuito';

  // "24 horas" o "3 días hábiles"
  String get amountLabel {
    if (unit == 'BusinessDays') return amount == 1 ? '1 día hábil' : '$amount días hábiles';
    return amount == 1 ? '1 hora' : '$amount horas';
  }
}
