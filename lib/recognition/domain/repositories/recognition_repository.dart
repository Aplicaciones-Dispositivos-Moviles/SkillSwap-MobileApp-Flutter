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
}
