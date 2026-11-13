import 'package:local_auth/local_auth.dart';

import '../../domain/services/device_authenticator.dart';

class LocalAuthAuthenticator implements DeviceAuthenticator {
  final LocalAuthentication _auth;

  LocalAuthAuthenticator({LocalAuthentication? auth}) : _auth = auth ?? LocalAuthentication();

  @override
  Future<DeviceAuthResult> confirm(String reason) async {
    // Sin huella, rostro, PIN, patrón ni contraseña no hay con qué confirmar
    if (!await _auth.isDeviceSupported()) return DeviceAuthResult.unavailable;
    try {
      // biometricOnly queda en false: si no hay huella registrada, el sistema ofrece PIN, patrón o contraseña
      final confirmed = await _auth.authenticate(localizedReason: reason);
      return confirmed ? DeviceAuthResult.confirmed : DeviceAuthResult.cancelled;
    } on LocalAuthException catch (e) {
      // Sin bloqueo de pantalla no se puede confirmar: se pide configurarlo, no se dice que se canceló
      if (e.code == LocalAuthExceptionCode.noCredentialsSet) return DeviceAuthResult.unavailable;
      // Cancelado, demasiados intentos fallidos u otro rechazo del sistema
      return DeviceAuthResult.cancelled;
    }
  }
}
