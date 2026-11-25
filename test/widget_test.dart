import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillswap_verifier/iam/domain/models/auth_user.dart';
import 'package:skillswap_verifier/shared/presentation/views/splash_view.dart';

void main() {
  test('AuthUser lee la respuesta de sign-in y la vuelve a escribir', () {
    final json = {
      'id': 7,
      'username': 'victor',
      'email': 'u2020@upc.edu.pe',
      'role': 'Student',
      'isVerified': true,
      'token': 'jwt-de-prueba',
    };

    final user = AuthUser.fromJson(json);

    expect(user.id, 7);
    expect(user.username, 'victor');
    expect(user.isVerified, isTrue);
    expect(user.token, 'jwt-de-prueba');
    expect(user.toJson(), json);
  });

  testWidgets('la pantalla de carga dice que es la app del Verificador', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashView()));

    expect(find.text('Verificador'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
