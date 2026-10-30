import 'package:flutter_test/flutter_test.dart';
import 'package:skillswap_verifier/assessment/domain/models/rubric.dart';
import 'package:skillswap_verifier/assessment/domain/models/verification_case.dart';
import 'package:skillswap_verifier/recognition/domain/models/redeemable_benefit.dart';
import 'package:skillswap_verifier/recognition/domain/models/shareable_credential.dart';
import 'package:skillswap_verifier/recognition/domain/models/wallet.dart';
import 'package:skillswap_verifier/reputation/domain/models/platform_metrics.dart';
import 'package:skillswap_verifier/shared/domain/utils/formatters.dart';
import 'package:skillswap_verifier/shared/infrastructure/network/api_exception.dart';

void main() {
  group('VerificationCase y CaseDetail', () {
    final caseJson = {
      'id': 2041,
      'attemptId': null,
      'submissionId': 9,
      'studentId': 3,
      'verifierUserId': 7,
      'pathNodeId': 15,
      'skillTag': 'python-data-science',
      'caseType': 'MiniProject',
      'status': 'Assigned',
      'decision': null,
      'rubricNotes': null,
      'evidenceUrl': 'https://github.com/est-4821/dashboard-ventas',
      'appealCount': 0,
      'openedAt': '2026-10-06T18:40:00Z',
      'reviewDueAt': '2026-10-08T18:40:00Z',
      'assignedAt': '2026-10-06T18:45:00Z',
      'resolvedAt': null,
    };

    test('lee el caso asignado de un miniproyecto', () {
      final c = VerificationCase.fromJson(caseJson);
      expect(c.code, 'SK-2041');
      expect(c.isMiniProject, isTrue);
      expect(c.isResolved, isFalse);
      expect(c.typeLabel, 'Miniproyecto');
      expect(c.reviewDueAt, DateTime.utc(2026, 10, 8, 18, 40));
    });

    test('el detalle sin intento (miniproyecto) no tiene preguntas falladas', () {
      final d = CaseDetail.fromJson({'verificationCase': caseJson, 'attempt': null, 'failedQuestions': null});
      expect(d.attempt, isNull);
      expect(d.failedQuestions, isEmpty);
    });

    test('el detalle de un quiz trae el intento y la respuesta elegida', () {
      final d = CaseDetail.fromJson({
        'verificationCase': {...caseJson, 'caseType': 'Quiz', 'attemptId': 4, 'submissionId': null},
        'attempt': {'score': 2, 'totalQuestions': 5, 'passed': false, 'weakSubTopic': 'Agregaciones con groupby'},
        'failedQuestions': [
          {'position': 3, 'question': '¿Qué devuelve groupby?', 'answers': ['A', 'B', 'C', 'D'], 'selectedAnswer': 2},
        ],
      });
      expect(d.attempt!.weakSubTopic, 'Agregaciones con groupby');
      expect(d.failedQuestions.single.selectedText, 'C');
      expect(d.verificationCase.typeLabel, 'Quiz no aprobado');
    });
  });

  group('Rúbrica', () {
    final criteria = rubricFor(miniProject: true);

    test('arma las notas con una línea por criterio y el comentario', () {
      final levels = {for (final c in criteria) c.name: RubricLevel.good};
      final notes = buildRubricNotes(criteria, levels, '  Buen README  ');
      expect(notes.split('\n'), hasLength(criteria.length + 1));
      expect(notes, contains('Funcionamiento: Bueno'));
      expect(notes, endsWith('Comentario: Buen README'));
    });

    test('nunca supera el máximo de 2000 caracteres del backend', () {
      final levels = {for (final c in criteria) c.name: RubricLevel.excellent};
      expect(buildRubricNotes(criteria, levels, 'x' * 3000).length, rubricNotesMaxLength);
    });

    test('sugiere rechazar si algún criterio es Insuficiente', () {
      expect(suggestsApproval({'a': RubricLevel.excellent, 'b': RubricLevel.insufficient}), isFalse);
      expect(suggestsApproval({'a': RubricLevel.good, 'b': RubricLevel.basic}), isTrue);
      expect(suggestsApproval({'a': RubricLevel.basic, 'b': RubricLevel.basic, 'c': RubricLevel.good}), isFalse);
    });
  });

  group('Métricas', () {
    test('la tasa de aprobación es lo contrario de la de fallos', () {
      final d = DifficultyMetrics.fromJson({
        'skills': [
          {'skillTag': 'sql', 'skillName': 'Análisis de datos con SQL', 'attempts': 50, 'failed': 13, 'failureRate': 0.26},
        ],
        'subTopics': [],
      });
      expect(d.skills.single.approvalRate, closeTo(0.74, 1e-9));
    });

    test('porcentaje dentro del plazo y nombre por defecto', () {
      final v = verifierMetricsFromJson({
        'verifiers': [
          {'verifierUserId': 9, 'fullName': null, 'score': 92, 'rank': 'Gold', 'resolvedCasesCount': 20,
           'overturnedDecisionsCount': 0, 'missedDeadlinesCount': 1, 'seniorVerifier': true, 'suspended': false,
           'averageResolutionHours': 5.5},
          {'verifierUserId': 10, 'fullName': 'Camila Rojas', 'score': 80, 'rank': 'Silver', 'resolvedCasesCount': 0,
           'overturnedDecisionsCount': 0, 'missedDeadlinesCount': 0, 'seniorVerifier': false, 'suspended': false,
           'averageResolutionHours': null},
        ],
      });
      expect(v.first.displayName, 'Verificador #9');
      expect(v.first.onTimePercent, 95);
      expect(v.last.onTimePercent, isNull);
    });
  });

  test('la publicación agrega el enlace solo si el texto no lo trae', () {
    final base = {'skillTag': 'sql', 'skillName': 'SQL', 'token': 't', 'url': 'https://skillswap.pe/c/t', 'createdAt': null};
    expect(ShareableCredential.fromJson({...base, 'shareText': 'Verifiqué SQL https://skillswap.pe/c/t'}).publication,
        'Verifiqué SQL https://skillswap.pe/c/t');
    expect(ShareableCredential.fromJson({...base, 'shareText': 'Verifiqué SQL'}).publication,
        'Verifiqué SQL\nhttps://skillswap.pe/c/t');
  });

  group('Formatos', () {
    test('nombre de la habilidad a partir del tag', () {
      expect(skillLabel('python-data-science'), 'Python data science');
    });

    test('plazo de revisión', () {
      final now = DateTime(2026, 10, 27, 10);
      expect(dueLabel(DateTime(2026, 10, 27, 16), now: now), 'Vence en 6 h');
      expect(dueLabel(DateTime(2026, 10, 29, 10, 30), now: now), 'Vence en 2 días');
      expect(dueLabel(DateTime(2026, 10, 27, 9), now: now), 'Vencido');
      expect(dueLabel(null), isNull);
    });

    test('día ISO para las métricas', () => expect(isoDay(DateTime(2026, 3, 5)), '2026-03-05'));
  });

  test('ApiException toma el detail del ProblemDetail', () {
    expect(ApiException.fromResponse(409, {'title': 'AlreadyResolved', 'detail': 'El caso ya fue resuelto'}, 'x').message,
        'El caso ya fue resuelto');
    expect(ApiException.fromResponse(500, 'error', 'No se pudo').message, 'No se pudo');
  });

  group('Tienda de beneficios', () {
    test('el catálogo fijo coincide con los valores y costos del backend', () {
      expect(
        [for (final b in RedeemableBenefit.values) (b.apiValue, b.cost)],
        [('Badge', 200), ('ContributionCertificate', 300), ('AdvancedPathUnlock', 500), ('SponsoredCertification', 1500)],
      );
    });

    test('solo la insignia se canjea una vez', () {
      expect([for (final b in RedeemableBenefit.values) if (b.oncePerUser) b], [RedeemableBenefit.badge]);
    });

    test('reconoce un canje previo por el redemptionItem del movimiento', () {
      final canje = CreditTransaction.fromJson({
        'id': 1, 'amount': -200, 'type': 'Redeemed', 'description': null, 'relatedCaseId': null,
        'createdAt': '2026-10-20T15:00:00Z', 'redemptionItem': 'Badge',
      });
      final ganado = CreditTransaction.fromJson({
        'id': 2, 'amount': 40, 'type': 'Earned', 'relatedCaseId': 2041, 'createdAt': '2026-10-20T15:00:00Z',
      });
      expect(ganado.redemptionItem, isNull);
      expect([ganado, canje].hasRedeemed(RedeemableBenefit.badge), isTrue);
      expect([ganado].hasRedeemed(RedeemableBenefit.badge), isFalse);
    });
  });
}
