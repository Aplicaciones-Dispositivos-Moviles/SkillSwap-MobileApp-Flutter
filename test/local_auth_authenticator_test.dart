import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:skillswap_verifier/shared/domain/services/device_authenticator.dart';
import 'package:skillswap_verifier/shared/infrastructure/services/local_auth_authenticator.dart';

class FakeLocalAuthentication extends Fake implements LocalAuthentication {
  final LocalAuthExceptionCode? failure;
  final bool confirmed;

  FakeLocalAuthentication({this.failure, this.confirmed = true});

  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<Object> authMessages = const <Object>[],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    if (failure != null) throw LocalAuthException(code: failure!);
    return confirmed;
  }
}

Future<DeviceAuthResult> confirmWith(FakeLocalAuthentication auth) =>
    LocalAuthAuthenticator(auth: auth).confirm('Confirma el canje');

void main() {
  test('confirma cuando el dispositivo valida a la persona', () async {
    expect(await confirmWith(FakeLocalAuthentication()), DeviceAuthResult.confirmed);
  });

  test('sin bloqueo de pantalla configurado avisa que no está disponible, no que se canceló', () async {
    expect(
      await confirmWith(FakeLocalAuthentication(failure: LocalAuthExceptionCode.noCredentialsSet)),
      DeviceAuthResult.unavailable,
    );
  });

  test('si la persona cancela devuelve cancelado', () async {
    expect(
      await confirmWith(FakeLocalAuthentication(failure: LocalAuthExceptionCode.userCanceled)),
      DeviceAuthResult.cancelled,
    );
  });
}
