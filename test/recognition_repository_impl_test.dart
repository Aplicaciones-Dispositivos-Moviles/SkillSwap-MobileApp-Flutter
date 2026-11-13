import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillswap_verifier/recognition/infrastructure/repositories/recognition_repository_impl.dart';

// Captures the outgoing request and answers like the redeem endpoint.
class RecordingAdapter implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode({'id': 90, 'amount': -500, 'type': 'Redeemed', 'redemptionItem': 'Badge'}),
      201,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  RecognitionRepositoryImpl repositoryWith(RecordingAdapter adapter) =>
      RecognitionRepositoryImpl(dio: Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = adapter);

  test('envía la clave de idempotencia en el encabezado Idempotency-Key', () async {
    final adapter = RecordingAdapter();
    final transaction = await repositoryWith(adapter).redeem('Badge', idempotencyKey: 'key-1');
    expect(adapter.request!.path, '/api/v1/credit-transactions/redeem');
    expect(adapter.request!.headers['Idempotency-Key'], 'key-1');
    expect(adapter.request!.data, {'item': 'Badge'});
    expect(transaction.id, 90);
  });

  test('sin clave no envía el encabezado', () async {
    final adapter = RecordingAdapter();
    await repositoryWith(adapter).redeem('Badge');
    expect(adapter.request!.headers.containsKey('Idempotency-Key'), isFalse);
  });
}
