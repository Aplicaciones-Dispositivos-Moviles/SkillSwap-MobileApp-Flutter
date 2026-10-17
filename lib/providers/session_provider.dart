import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

// Sesión del Verificador. El usuario y el token se guardan en SharedPreferences
// para no pedir el login cada vez que se abre la app.
class SessionProvider extends ChangeNotifier {
  static const _storageKey = 'session_user';

  final ApiClient api;
  final AuthService auth;

  SessionProvider(this.api, this.auth);

  AuthUser? user;
  bool loading = false;
  String errorMessage = '';

  // Al abrir la app: recupera la sesión guardada, si hay.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    try {
      user = AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      api.token = user!.token;
    } catch (_) {
      await prefs.remove(_storageKey);
    }
  }

  Future<bool> signIn(String username, String password) async {
    loading = true;
    errorMessage = '';
    notifyListeners();
    try {
      final signedIn = await auth.signIn(username, password);
      user = signedIn;
      api.token = signedIn.token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(signedIn.toJson()));
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    user = null;
    api.token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }

  // Si el backend responde 401 (token vencido), la app vuelve al login.
  Future<void> sessionExpired() => signOut();
}
