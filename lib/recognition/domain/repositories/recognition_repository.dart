import '../models/shareable_credential.dart';
import '../models/wallet.dart';

abstract class RecognitionRepository {
  // Billetera de SkillCredits; null si todavía no tiene (404).
  Future<Wallet?> getWallet(int userId);

  Future<List<CreditTransaction>> getTransactions(int userId);

  // Enlaces ya generados, uno por habilidad.
  Future<List<ShareableCredential>> getShareableCredentials();

  // Genera (o devuelve) el enlace de una habilidad verificada. 409 si la habilidad no está verificada.
  Future<ShareableCredential> createShareableCredential(String skillTag);

  // US32 · Canjea un beneficio de la tienda (Badge, ContributionCertificate, AdvancedPathUnlock o SponsoredCertification).
  // El servidor no verifica la biometría: la app la pide antes de llamar. 400, 404 o 409 con el motivo.
  Future<CreditTransaction> redeem(String item);
}
