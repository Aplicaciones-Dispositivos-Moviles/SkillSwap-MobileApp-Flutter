import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillswap_verifier/shared/presentation/components/justification_dialog.dart';

void main() {
  testWidgets('exige la justificación y devuelve el texto sin espacios sobrantes', (tester) async {
    String? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await showDialog<String>(
            context: context,
            builder: (_) => const JustificationDialog(
              title: 'Suspender a Ana',
              description: 'Dejará de recibir casos nuevos hasta que lo reactives.',
              confirmLabel: 'Suspender',
              maxLength: 2000,
              destructive: true,
            ),
          ),
          child: const Text('Abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Suspender'));
    await tester.pump();
    expect(find.text('Escribe la justificación'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '  Faltó a tres plazos  ');
    await tester.tap(find.text('Suspender'));
    await tester.pumpAndSettle();
    expect(result, 'Faltó a tres plazos');
    expect(find.byType(JustificationDialog), findsNothing);
  });
}
