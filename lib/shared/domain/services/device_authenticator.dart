// Resultado de pedirle al dispositivo que confirme la identidad de quien lo usa.
enum DeviceAuthResult {
  confirmed, // huella, rostro o, si no hay, PIN, patrón o contraseña del dispositivo
  cancelled, // la persona canceló o no pasó la verificación
  unavailable, // el dispositivo no tiene ningún bloqueo de pantalla configurado
}

// Confirmación local antes de acciones sensibles (el servidor no la verifica; ver 2.6.6 del informe).
abstract class DeviceAuthenticator {
  Future<DeviceAuthResult> confirm(String reason);
}
