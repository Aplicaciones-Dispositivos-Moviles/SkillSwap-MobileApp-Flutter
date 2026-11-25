import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillswap_verifier/moderation/infrastructure/repositories/moderation_repository_impl.dart';
import 'package:skillswap_verifier/shared/infrastructure/network/api_exception.dart';

// Captura la petición y responde como GET /api/v1/disputes.
class DisputesAdapter implements HttpClientAdapter {
  RequestOptions? request;
  final int status;
  final Object body;

  DisputesAdapter({this.status = 200, this.body = const []});

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  ModerationRepositoryImpl repositoryWith(DisputesAdapter adapter) =>
      ModerationRepositoryImpl(dio: Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = adapter);

  test('pide las pendientes por defecto y las resueltas con el filtro', () async {
    final adapter = DisputesAdapter(body: [
      {'id': 3, 'sourceType': 'CertificateReview', 'sourceReferenceId': 50, 'reason': 'DuplicateFile', 'status': 'Pending'},
    ]);
    final repository = repositoryWith(adapter);

    final pending = await repository.getDisputes();
    expect(adapter.request!.path, '/api/v1/disputes');
    expect(adapter.request!.queryParameters, {'status': 'Pending'});
    expect(pending.single.id, 3);

    await repository.getDisputes(resolved: true);
    expect(adapter.request!.queryParameters, {'status': 'Resolved'});
  });

  test('pide la evidencia de la disputa', () async {
    final adapter = DisputesAdapter(body: {
      'dispute': {'id': 12, 'sourceType': 'CertificateReview', 'sourceReferenceId': 77, 'reason': 'DuplicateFile'},
      'certificate': null,
    });
    final evidence = await repositoryWith(adapter).getEvidence(12);
    expect(adapter.request!.method, 'GET');
    expect(adapter.request!.path, '/api/v1/disputes/12/evidence');
    expect(evidence.dispute.id, 12);
    expect(evidence.certificate, isNull);
  });

  test('resuelve la disputa con PATCH, el resultado y las observaciones', () async {
    final adapter = DisputesAdapter(body: {
      'id': 12, 'sourceType': 'CertificateReview', 'sourceReferenceId': 77, 'reason': 'DuplicateFile',
      'status': 'Resolved', 'outcome': 'Overturned', 'resolutionNotes': 'Es falso',
    });
    final resolved = await repositoryWith(adapter).resolveDispute(12, outcome: 'Overturned', resolutionNotes: 'Es falso');
    expect(adapter.request!.method, 'PATCH');
    expect(adapter.request!.path, '/api/v1/disputes/12/resolve');
    expect(adapter.request!.data, {'outcome': 'Overturned', 'resolutionNotes': 'Es falso'});
    expect(resolved.outcomeLabel, 'Certificado rechazado');
  });

  test('un 409 al resolver llega con el motivo del backend', () async {
    final adapter = DisputesAdapter(status: 409, body: {'title': 'AlreadyResolved', 'detail': 'La disputa ya fue resuelta'});
    await expectLater(
      repositoryWith(adapter).resolveDispute(12, outcome: 'Upheld', resolutionNotes: 'Bien'),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 409)),
    );
  });

  test('un 403 llega con el motivo del backend', () async {
    final adapter = DisputesAdapter(status: 403, body: {'title': 'NotAVerifier', 'detail': 'No eres un Verificador'});
    await expectLater(
      repositoryWith(adapter).getDisputes(),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 403).having((e) => e.message, 'message', 'No eres un Verificador')),
    );
  });
}
