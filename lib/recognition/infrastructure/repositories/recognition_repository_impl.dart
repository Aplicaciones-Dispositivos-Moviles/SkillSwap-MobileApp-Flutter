import 'package:dio/dio.dart';

import '../../../shared/infrastructure/network/api_exception.dart';
import '../../domain/models/shareable_credential.dart';
import '../../domain/models/wallet.dart';
import '../../domain/repositories/recognition_repository.dart';

class RecognitionRepositoryImpl implements RecognitionRepository {
  final Dio dio;

  RecognitionRepositoryImpl({required this.dio});

  @override
  Future<Wallet?> getWallet(int userId) async {
    try {
      final response = await dio.get('/api/v1/wallets/$userId');
      return Wallet.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.from(e, 'No se pudo cargar tu billetera');
    }
  }

  @override
  Future<List<CreditTransaction>> getTransactions(int userId) async {
    try {
      final response = await dio.get('/api/v1/wallets/$userId/transactions');
      return [for (final t in (response.data as List)) CreditTransaction.fromJson(t as Map<String, dynamic>)];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const [];
      throw ApiException.from(e, 'No se pudieron cargar tus movimientos');
    }
  }

  @override
  Future<List<ShareableCredential>> getShareableCredentials() async {
    try {
      final response = await dio.get('/api/v1/shareable-credentials');
      return [for (final c in (response.data as List)) ShareableCredential.fromJson(c as Map<String, dynamic>)];
    } catch (e) {
      throw ApiException.from(e, 'No se pudieron cargar tus credenciales');
    }
  }

  @override
  Future<ShareableCredential> createShareableCredential(String skillTag) async {
    try {
      final response = await dio.post('/api/v1/shareable-credentials', data: {'skillTag': skillTag});
      return ShareableCredential.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw const ApiException('Esa habilidad todavía no está verificada', status: 409);
      }
      throw ApiException.from(e, 'No se pudo generar el enlace público');
    }
  }

  @override
  Future<CreditTransaction> redeem(String item) async {
    try {
      final response = await dio.post('/api/v1/credit-transactions/redeem', data: {'item': item});
      return CreditTransaction.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e, 'No se pudo canjear el beneficio');
    }
  }
}
