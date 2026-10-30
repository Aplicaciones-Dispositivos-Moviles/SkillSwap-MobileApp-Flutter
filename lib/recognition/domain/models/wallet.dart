import '../../../shared/domain/utils/formatters.dart';

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
  });

  factory CreditTransaction.fromJson(Map<String, dynamic> json) => CreditTransaction(
        id: (json['id'] as num).toInt(),
        amount: (json['amount'] as num? ?? 0).toInt(),
        type: (json['type'] ?? '') as String,
        description: json['description'] as String?,
        relatedCaseId: (json['relatedCaseId'] as num?)?.toInt(),
        createdAt: parseDate(json['createdAt']),
        redemptionItem: json['redemptionItem'] as String?,
      );

  String get title {
    if (description != null && description!.isNotEmpty) return description!;
    if (relatedCaseId != null) return 'Caso SK-$relatedCaseId resuelto';
    return type;
  }
}
