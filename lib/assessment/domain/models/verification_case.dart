import '../../../shared/domain/utils/formatters.dart';

// VerificationCaseResource: un caso asignado al Verificador.
class VerificationCase {
  final int id;
  final int? attemptId;
  final int? submissionId;
  final int pathNodeId;
  final String skillTag;
  final String caseType; // Quiz | MiniProject
  final String status; // Pending | Assigned | Resolved
  final String? decision; // Approved | Rejected
  final String? rubricNotes;
  final String? evidenceUrl;
  final int appealCount;
  final DateTime? openedAt;
  final DateTime? reviewDueAt;
  final DateTime? resolvedAt;

  const VerificationCase({
    required this.id,
    required this.attemptId,
    required this.submissionId,
    required this.pathNodeId,
    required this.skillTag,
    required this.caseType,
    required this.status,
    required this.decision,
    required this.rubricNotes,
    required this.evidenceUrl,
    required this.appealCount,
    required this.openedAt,
    required this.reviewDueAt,
    required this.resolvedAt,
  });

  factory VerificationCase.fromJson(Map<String, dynamic> json) => VerificationCase(
        id: (json['id'] as num).toInt(),
        attemptId: (json['attemptId'] as num?)?.toInt(),
        submissionId: (json['submissionId'] as num?)?.toInt(),
        pathNodeId: (json['pathNodeId'] as num? ?? 0).toInt(),
        skillTag: (json['skillTag'] ?? '') as String,
        caseType: (json['caseType'] ?? 'Quiz') as String,
        status: (json['status'] ?? 'Assigned') as String,
        decision: json['decision'] as String?,
        rubricNotes: json['rubricNotes'] as String?,
        evidenceUrl: json['evidenceUrl'] as String?,
        appealCount: (json['appealCount'] as num? ?? 0).toInt(),
        openedAt: parseDate(json['openedAt']),
        reviewDueAt: parseDate(json['reviewDueAt']),
        resolvedAt: parseDate(json['resolvedAt']),
      );

  bool get isResolved => status == 'Resolved';
  bool get isMiniProject => caseType == 'MiniProject';
  bool get isAppeal => appealCount > 0;
  String get code => 'SK-$id';
  String get typeLabel => isMiniProject ? 'Miniproyecto' : (isAppeal ? 'Apelación' : 'Quiz no aprobado');
}

// AssessmentAttemptResource dentro del detalle del caso (null si lo abrió un miniproyecto)
class CaseAttempt {
  final int score;
  final int totalQuestions;
  final bool passed;
  final String? weakSubTopic;

  const CaseAttempt({required this.score, required this.totalQuestions, required this.passed, this.weakSubTopic});

  factory CaseAttempt.fromJson(Map<String, dynamic> json) => CaseAttempt(
        score: (json['score'] as num? ?? 0).toInt(),
        totalQuestions: (json['totalQuestions'] as num? ?? 0).toInt(),
        passed: (json['passed'] ?? false) as bool,
        weakSubTopic: json['weakSubTopic'] as String?,
      );
}

// FailedQuestionResource: pregunta fallada y la opción que eligió el Estudiante (nunca la correcta)
class FailedQuestion {
  final int position;
  final String question;
  final List<String> answers;
  final int selectedAnswer;

  const FailedQuestion(this.position, this.question, this.answers, this.selectedAnswer);

  factory FailedQuestion.fromJson(Map<String, dynamic> json) => FailedQuestion(
        (json['position'] as num? ?? 0).toInt(),
        (json['question'] ?? '') as String,
        [for (final a in (json['answers'] as List? ?? const [])) a as String],
        (json['selectedAnswer'] as num? ?? -1).toInt(),
      );

  String? get selectedText => selectedAnswer >= 0 && selectedAnswer < answers.length ? answers[selectedAnswer] : null;
}

// VerificationCaseDetailResource: el caso, el intento y las preguntas falladas.
class CaseDetail {
  final VerificationCase verificationCase;
  final CaseAttempt? attempt;
  final List<FailedQuestion> failedQuestions;

  const CaseDetail(this.verificationCase, this.attempt, this.failedQuestions);

  factory CaseDetail.fromJson(Map<String, dynamic> json) => CaseDetail(
        VerificationCase.fromJson(json['verificationCase'] as Map<String, dynamic>),
        json['attempt'] == null ? null : CaseAttempt.fromJson(json['attempt'] as Map<String, dynamic>),
        [
          for (final q in (json['failedQuestions'] as List? ?? const []))
            FailedQuestion.fromJson(q as Map<String, dynamic>)
        ],
      );
}
