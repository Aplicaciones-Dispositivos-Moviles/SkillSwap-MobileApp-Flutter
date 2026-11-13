import '../../../shared/domain/utils/formatters.dart';
import 'redeemable_benefit.dart';

// WalletResource: saldo de SkillCredits.
class Wallet {
  final int id;
  final int balance;

  const Wallet(this.id, this.balance);

  factory Wallet.fromJson(Map<String, dynamic> json) =>
      Wallet((json['id'] as num? ?? 0).toInt(), (json['balance'] as num? ?? 0).toInt());
}

// CreditTransactionResource: un movimiento de la billetera (monto con signo).
class CreditTransaction {
  final int id;
  final int amount;
  final String type;
  final String? description;
  final int? relatedCaseId;
  final int? relatedDemonstrationId; // demostración final que pagó el movimiento (si aplica)
  final DateTime? createdAt;
  final String? redemptionItem; // beneficio canjeado (solo en los canjes)

  const CreditTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.relatedCaseId,
    required this.createdAt,
    this.redemptionItem,
    this.relatedDemonstrationId,
  });

  factory CreditTransaction.fromJson(Map<String, dynamic> json) => CreditTransaction(
        id: (json['id'] as num).toInt(),
        amount: (json['amount'] as num? ?? 0).toInt(),
        type: (json['type'] ?? '') as String,
        description: json['description'] as String?,
        relatedCaseId: (json['relatedCaseId'] as num?)?.toInt(),
        createdAt: parseDate(json['createdAt']),
        redemptionItem: json['redemptionItem'] as String?,
        relatedDemonstrationId: (json['relatedDemonstrationId'] as num?)?.toInt(),
      );

  // El backend manda el monto siempre positivo: el tipo dice si suma (Earned) o resta (Redeemed).
  bool get isEarned => type != 'Redeemed';

  String get signedAmount => '${isEarned ? '+' : '−'}${amount.abs()}';

  // Título en español armado con los datos del movimiento: la descripción del backend viene en inglés.
  String get title {
    if (type == 'Redeemed') {
      final benefit = RedeemableBenefit.values.where((b) => b.apiValue == redemptionItem).firstOrNull;
      return benefit == null ? 'Canje de SkillCredits' : 'Canje: ${benefit.title}';
    }
    if (relatedCaseId != null) return 'Caso SK-$relatedCaseId resuelto';
    if (relatedDemonstrationId != null) return 'Demostración final revisada';
    return 'SkillCredits ganados';
  }
}
