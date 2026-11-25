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

  test('un 403 llega con el motivo del backend', () async {
    final adapter = DisputesAdapter(status: 403, body: {'title': 'NotAVerifier', 'detail': 'No eres un Verificador'});
    await expectLater(
      repositoryWith(adapter).getDisputes(),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 403).having((e) => e.message, 'message', 'No eres un Verificador')),
    );
  });
}
