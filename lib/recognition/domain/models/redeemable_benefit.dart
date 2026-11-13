import 'wallet.dart';

// Catálogo fijo de la tienda (US32). El backend no tiene un endpoint de catálogo: los costos y textos van aquí
// y deben coincidir con los de POST /api/v1/credit-transactions/redeem.
enum RedeemableBenefit {
  badge(
    apiValue: 'Badge',
    title: 'Insignia',
    cost: 200,
    description: 'Insignia en tu perfil de Verificador. Se canjea una sola vez.',
    successMessage: 'Insignia canjeada. Ya es tuya.',
    oncePerUser: true,
  ),
  contributionCertificate(
    apiValue: 'ContributionCertificate',
    title: 'Certificado de contribución',
    cost: 300,
    description: 'Certificado exportable que acredita tu labor como Verificador.',
    successMessage: 'Canje registrado. La entrega del certificado aún no está disponible en esta versión.',
    confirmNote: 'La entrega del certificado aún no está disponible en esta versión.',
  ),
  advancedPathUnlock(
    apiValue: 'AdvancedPathUnlock',
    title: 'Ruta avanzada',
    cost: 500,
    description: 'Desbloquea una ruta avanzada que no cuenta para los límites de tu plan.',
    successMessage: 'Ruta avanzada desbloqueada. Ya la tienes disponible en tu cuenta.',
  ),
  sponsoredCertification(
    apiValue: 'SponsoredCertification',
    title: 'Certificación patrocinada',
    cost: 1500,
    description: 'Cubre el costo o el derecho a rendir el examen de una certificación externa. '
        'No garantiza aprobarla; Innovify te la entrega manualmente.',
    successMessage: 'Canje registrado. Innovify te entregará la certificación manualmente.',
  );

  final String apiValue; // valor que espera el backend en {"item": ...}
  final String title;
  final int cost;
  final String description;
  final String successMessage;
  final String? confirmNote; // aviso extra antes de confirmar el canje
  final bool oncePerUser;

  const RedeemableBenefit({
    required this.apiValue,
    required this.title,
    required this.cost,
    required this.description,
    required this.successMessage,
    this.confirmNote,
    this.oncePerUser = false,
  });
}

extension RedeemedBenefits on Iterable<CreditTransaction> {
  // Un movimiento de canje trae el beneficio en redemptionItem
  bool hasRedeemed(RedeemableBenefit benefit) => any((t) => t.redemptionItem == benefit.apiValue);
}
