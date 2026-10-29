import 'package:flutter_test/flutter_test.dart';
import 'package:skillswap_verifier/assessment/application/bloc/case_review_bloc.dart';
import 'package:skillswap_verifier/assessment/application/bloc/cases_bloc.dart';
import 'package:skillswap_verifier/assessment/domain/models/verification_case.dart';
import 'package:skillswap_verifier/assessment/domain/models/verifier_profile.dart';
import 'package:skillswap_verifier/assessment/domain/repositories/verification_case_repository.dart';
import 'package:skillswap_verifier/iam/application/bloc/session_bloc.dart';
import 'package:skillswap_verifier/iam/domain/models/auth_user.dart';
import 'package:skillswap_verifier/iam/domain/repositories/auth_repository.dart';
import 'package:skillswap_verifier/recognition/domain/models/shareable_credential.dart';
import 'package:skillswap_verifier/recognition/domain/models/wallet.dart';
import 'package:skillswap_verifier/recognition/domain/repositories/recognition_repository.dart';
import 'package:skillswap_verifier/reputation/application/bloc/metrics_bloc.dart';
import 'package:skillswap_verifier/reputation/application/bloc/supervision_bloc.dart';
import 'package:skillswap_verifier/reputation/domain/models/platform_metrics.dart';
import 'package:skillswap_verifier/reputation/domain/models/verifier_reliability.dart';
import 'package:skillswap_verifier/reputation/domain/repositories/reputation_repository.dart';
import 'package:skillswap_verifier/shared/infrastructure/network/api_exception.dart';

// ---------- repositorios falsos ----------
class FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthUser?> restoreSession() async => null;

  @override
  Future<AuthUser> signIn(String username, String password) async {
    if (password != 'clave') throw const ApiException('Usuario o contraseña incorrectos', status: 401);
    return AuthUser(id: 1, username: username, email: '', role: 'Student', isVerified: true, token: 'jwt');
  }

  @override
  Future<void> signOut() async {}
}

VerificationCase _case({String status = 'Assigned', String? decision}) => VerificationCase.fromJson({
      'id': 2057, 'pathNodeId': 3, 'skillTag': 'pandas', 'caseType': 'Quiz', 'status': status,
      'decision': decision, 'appealCount': 0,
    });

VerifierProfile _profile({bool available = false, bool suspended = false}) => VerifierProfile.fromJson({
      'id': 1, 'verifierUserId': 7, 'skillTags': ['sql'], 'available': available, 'verified': true,
      'rating': 4.5, 'reviewCount': 3, 'suspended': suspended,
    });

class FakeCaseRepository implements VerificationCaseRepository {
  VerifierProfile? profile;
  bool failAvailability = false;
  bool? sentAvailability;
  int? sentSuspendedId;
  String? sentJustification;
  int? reinstatedId;
  bool failSuspension = false;
  String? sentDecision;
  String? sentNotes;
  bool alreadyResolved = false;

  @override
  Future<CaseDetail> getCaseDetail(int caseId) async => CaseDetail(_case(), null, const []);

  @override
  Future<VerificationCase> resolveCase(int caseId, {required String decision, required String rubricNotes}) async {
    if (alreadyResolved) throw const ApiException('Este caso ya fue resuelto', status: 409);
    sentDecision = decision;
    sentNotes = rubricNotes;
    return _case(status: 'Resolved', decision: decision);
  }

  @override
  Future<List<VerificationCase>> getAssignedCases() async => [_case()];

  @override
  Future<VerifierProfile?> getMyProfile() async => profile;

  @override
  Future<VerifierProfile> updateAvailability(bool available) async {
    if (failAvailability) throw const ApiException('No se pudo actualizar tu disponibilidad', status: 500);
    sentAvailability = available;
    return _profile(available: available);
  }

  @override
  Future<VerifierProfile> suspendVerifier(int verifierUserId, String justification) async {
    if (failSuspension) {
      throw const ApiException('Solo se suspende a quien tiene confiabilidad menor a 60', status: 409);
    }
    sentSuspendedId = verifierUserId;
    sentJustification = justification;
    return _profile(suspended: true);
  }

  @override
  Future<VerifierProfile> reinstateVerifier(int verifierUserId) async {
    reinstatedId = verifierUserId;
    return _profile();
  }
}

class FakeRecognitionRepository implements RecognitionRepository {
  @override
  Future<Wallet?> getWallet(int userId) async => null;

  @override
  Future<List<CreditTransaction>> getTransactions(int userId) async => const [];

  @override
  Future<List<ShareableCredential>> getShareableCredentials() async => const [];

  @override
  Future<ShareableCredential> createShareableCredential(String skillTag) async =>
      throw UnimplementedError('No se usa en estas pruebas');
}

class FakeReputationRepository implements ReputationRepository {
  final bool senior;
  final List<VerifierMetric> verifiers;
  String? lastVerifiersOrder;

  FakeReputationRepository({required this.senior, this.verifiers = const []});

  ApiException get _forbidden => const ApiException('No es Verificador senior', status: 403);

  @override
  Future<DemandMetrics> getDemand(DateTime from, DateTime to) async =>
      senior ? const DemandMetrics([SkillDemand('sql', 'SQL', 98)], []) : throw _forbidden;

  @override
  Future<DifficultyMetrics> getDifficulty(DateTime from, DateTime to) async =>
      senior ? const DifficultyMetrics([], []) : throw _forbidden;

  @override
  Future<List<VerifierMetric>> getVerifiers({String order = 'desc'}) async {
    lastVerifiersOrder = order;
    return senior ? verifiers : throw _forbidden;
  }

  @override
  Future<VerifierReliability?> getReliability(int verifierUserId) async => null;
}

VerifierMetric _metric(int id, int score, {bool suspended = false}) => VerifierMetric.fromJson({
      'verifierUserId': id, 'fullName': 'Verificador $id', 'score': score, 'rank': 'Bronze',
      'resolvedCasesCount': 10, 'missedDeadlinesCount': 2, 'seniorVerifier': false, 'suspended': suspended,
    });

void main() {
  group('SessionBloc', () {
    test('pide usuario y contraseña antes de llamar al backend', () async {
      final bloc = SessionBloc(authRepository: FakeAuthRepository());
      bloc.add(const SignInRequested('', ''));
      final state = await bloc.stream.first;
      expect(state, isA<Unauthenticated>().having((s) => s.message, 'message', 'Ingrese usuario y contraseña'));
      await bloc.close();
    });

    test('inicia sesión y muestra el error del backend si falla', () async {
      final bloc = SessionBloc(authRepository: FakeAuthRepository());
      bloc.add(const SignInRequested('rodrigo', 'otra'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<Authenticating>(),
          isA<Unauthenticated>().having((s) => s.message, 'message', 'Usuario o contraseña incorrectos'),
        ]),
      );
      bloc.add(const SignInRequested('rodrigo', 'clave'));
      await expectLater(bloc.stream, emitsInOrder([isA<Authenticating>(), isA<Authenticated>()]));
      await bloc.close();
    });
  });

  group('CaseReviewBloc', () {
    test('carga el caso y envía la decisión con las notas de la rúbrica', () async {
      final repo = FakeCaseRepository();
      final bloc = CaseReviewBloc(caseRepository: repo)..add(const CaseReviewRequested(2057));
      await expectLater(bloc.stream, emitsInOrder([isA<CaseReviewLoading>(), isA<CaseReviewLoaded>()]));
      bloc.add(const CaseDecisionSubmitted(approve: true, rubricNotes: 'Dominio: Bueno'));
      await expectLater(bloc.stream, emitsInOrder([isA<CaseReviewLoaded>(), isA<CaseResolved>()]));
      expect(repo.sentDecision, 'Approved');
      expect(repo.sentNotes, 'Dominio: Bueno');
      await bloc.close();
    });

    test('si el caso ya fue resuelto muestra el error y sigue en pantalla', () async {
      final repo = FakeCaseRepository()..alreadyResolved = true;
      final bloc = CaseReviewBloc(caseRepository: repo)..add(const CaseReviewRequested(2057));
      await expectLater(bloc.stream, emitsInOrder([isA<CaseReviewLoading>(), isA<CaseReviewLoaded>()]));
      bloc.add(const CaseDecisionSubmitted(approve: false, rubricNotes: 'Dominio: Básico'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<CaseReviewLoaded>().having((s) => s.submitting, 'submitting', isTrue),
          isA<CaseReviewLoaded>().having((s) => s.error, 'error', 'Este caso ya fue resuelto'),
        ]),
      );
      await bloc.close();
    });
  });

  group('MetricsBloc', () {
    test('el Verificador senior ve las métricas del periodo', () async {
      final bloc = MetricsBloc(reputationRepository: FakeReputationRepository(senior: true))
        ..add(const MetricsRequested(days: 7));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<MetricsLoading>(),
          isA<MetricsLoaded>().having((s) => s.demand.topSkills.single.pathCount, 'pathCount', 98),
        ]),
      );
      expect(bloc.state.days, 7);
      await bloc.close();
    });

    test('un Verificador que no es senior recibe 403', () async {
      final bloc = MetricsBloc(reputationRepository: FakeReputationRepository(senior: false))
        ..add(const MetricsRequested());
      await expectLater(bloc.stream, emitsInOrder([isA<MetricsLoading>(), isA<MetricsForbidden>()]));
      await bloc.close();
    });
  });

  group('CasesBloc · disponibilidad', () {
    CasesBloc buildBloc(FakeCaseRepository repo) => CasesBloc(
          userId: 7,
          caseRepository: repo,
          reputationRepository: FakeReputationRepository(senior: false),
          recognitionRepository: FakeRecognitionRepository(),
        );

    test('activa la disponibilidad y actualiza el perfil', () async {
      final repo = FakeCaseRepository()..profile = _profile();
      final bloc = buildBloc(repo)..add(const CasesRequested());
      await expectLater(bloc.stream, emitsInOrder([isA<CasesLoading>(), isA<CasesLoaded>()]));
      bloc.add(const AvailabilityChanged(true));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<CasesLoaded>().having((s) => s.updatingAvailability, 'updatingAvailability', isTrue),
          isA<CasesLoaded>()
              .having((s) => s.profile.available, 'available', isTrue)
              .having((s) => s.updatingAvailability, 'updatingAvailability', isFalse),
        ]),
      );
      expect(repo.sentAvailability, isTrue);
      await bloc.close();
    });

    test('si falla conserva el valor anterior y muestra el error', () async {
      final repo = FakeCaseRepository()
        ..profile = _profile(available: true)
        ..failAvailability = true;
      final bloc = buildBloc(repo)..add(const CasesRequested());
      await expectLater(bloc.stream, emitsInOrder([isA<CasesLoading>(), isA<CasesLoaded>()]));
      bloc.add(const AvailabilityChanged(false));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<CasesLoaded>().having((s) => s.updatingAvailability, 'updatingAvailability', isTrue),
          isA<CasesLoaded>()
              .having((s) => s.profile.available, 'available', isTrue)
              .having((s) => s.availabilityError, 'availabilityError', 'No se pudo actualizar tu disponibilidad'),
        ]),
      );
      await bloc.close();
    });

    test('un Verificador suspendido no puede cambiar su disponibilidad', () async {
      final repo = FakeCaseRepository()..profile = _profile(suspended: true);
      final bloc = buildBloc(repo)..add(const CasesRequested());
      await expectLater(bloc.stream, emitsInOrder([isA<CasesLoading>(), isA<CasesLoaded>()]));
      bloc.add(const AvailabilityChanged(true));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(repo.sentAvailability, isNull);
      await bloc.close();
    });
  });

  group('SupervisionBloc', () {
    SupervisionBloc buildBloc(FakeCaseRepository repo, {bool senior = true, FakeReputationRepository? reputation}) =>
        SupervisionBloc(
          userId: 1,
          reputationRepository: reputation ??
              FakeReputationRepository(
                senior: senior,
                verifiers: [_metric(1, 95), _metric(2, 40), _metric(3, 80, suspended: true)],
              ),
          caseRepository: repo,
        );

    Future<SupervisionBloc> loadedBloc(FakeCaseRepository repo) async {
      final bloc = buildBloc(repo)..add(const SupervisionRequested());
      await expectLater(bloc.stream, emitsInOrder([isA<SupervisionLoading>(), isA<SupervisionLoaded>()]));
      return bloc;
    }

    test('lista a los demás Verificadores de menor a mayor confiabilidad', () async {
      final reputation = FakeReputationRepository(
        senior: true,
        verifiers: [_metric(1, 95), _metric(2, 40), _metric(3, 80)],
      );
      final bloc = buildBloc(FakeCaseRepository(), reputation: reputation)..add(const SupervisionRequested());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SupervisionLoading>(),
          isA<SupervisionLoaded>().having((s) => [for (final v in s.verifiers) v.verifierUserId], 'ids', [2, 3]),
        ]),
      );
      expect(reputation.lastVerifiersOrder, 'asc');
      await bloc.close();
    });

    test('un Verificador sin rango senior recibe 403', () async {
      final bloc = buildBloc(FakeCaseRepository(), senior: false)..add(const SupervisionRequested());
      await expectLater(bloc.stream, emitsInOrder([isA<SupervisionLoading>(), isA<SupervisionForbidden>()]));
      await bloc.close();
    });

    test('suspende con la justificación y marca al Verificador como suspendido', () async {
      final repo = FakeCaseRepository();
      final bloc = await loadedBloc(repo);
      bloc.add(const VerifierSuspended(2, '  Faltó a tres plazos  '));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SupervisionLoaded>().having((s) => s.busyUserId, 'busyUserId', 2),
          isA<SupervisionLoaded>()
              .having((s) => s.notice, 'notice', 'Verificador suspendido')
              .having((s) => s.verifiers.first.suspended, 'suspended', isTrue)
              .having((s) => s.busyUserId, 'busyUserId', isNull),
        ]),
      );
      expect(repo.sentSuspendedId, 2);
      expect(repo.sentJustification, 'Faltó a tres plazos');
      await bloc.close();
    });

    test('exige la justificación y no llama al backend si está vacía', () async {
      final repo = FakeCaseRepository();
      final bloc = await loadedBloc(repo);
      bloc.add(const VerifierSuspended(2, '   '));
      await expectLater(
        bloc.stream,
        emits(isA<SupervisionLoaded>().having((s) => s.error, 'error', 'Escribe la justificación de la suspensión')),
      );
      expect(repo.sentSuspendedId, isNull);
      await bloc.close();
    });

    test('si el backend rechaza la suspensión muestra el error y no cambia al Verificador', () async {
      final repo = FakeCaseRepository()..failSuspension = true;
      final bloc = await loadedBloc(repo);
      bloc.add(const VerifierSuspended(2, 'Faltó a tres plazos'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SupervisionLoaded>().having((s) => s.busyUserId, 'busyUserId', 2),
          isA<SupervisionLoaded>()
              .having((s) => s.error, 'error', 'Solo se suspende a quien tiene confiabilidad menor a 60')
              .having((s) => s.verifiers.first.suspended, 'suspended', isFalse),
        ]),
      );
      await bloc.close();
    });

    test('reactiva a un Verificador suspendido', () async {
      final repo = FakeCaseRepository();
      final bloc = await loadedBloc(repo);
      bloc.add(const VerifierReinstated(3));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SupervisionLoaded>().having((s) => s.busyUserId, 'busyUserId', 3),
          isA<SupervisionLoaded>()
              .having((s) => s.notice, 'notice', 'Verificador reactivado')
              .having((s) => s.verifiers.last.suspended, 'suspended', isFalse),
        ]),
      );
      expect(repo.reinstatedId, 3);
      await bloc.close();
    });
  });
}
