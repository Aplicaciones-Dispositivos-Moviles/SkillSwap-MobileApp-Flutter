import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillswap_verifier/assessment/application/bloc/case_review_bloc.dart';
import 'package:skillswap_verifier/assessment/application/bloc/cases_bloc.dart';
import 'package:skillswap_verifier/assessment/domain/models/rubric.dart';
import 'package:skillswap_verifier/assessment/domain/models/verifier_profile.dart';
import 'package:skillswap_verifier/assessment/presentation/views/cases_view.dart';
import 'package:skillswap_verifier/iam/application/bloc/session_bloc.dart';
import 'package:skillswap_verifier/recognition/application/bloc/wallet_bloc.dart';
import 'package:skillswap_verifier/recognition/domain/models/wallet.dart';
import 'package:skillswap_verifier/service_locator.dart';

import 'bloc_test.dart' show FakeAuthRepository, FakeCaseRepository, FakeRecognitionRepository, FakeReputationRepository;

// Counts wallet loads so the test can tell whether the balance was refreshed.
class CountingRecognitionRepository extends FakeRecognitionRepository {
  int walletLoads = 0;

  @override
  Future<Wallet?> getWallet(int userId) async {
    walletLoads++;
    return null;
  }
}

void main() {
  testWidgets('resolving a case refreshes the SkillCredits wallet', (tester) async {
    final caseRepository = FakeCaseRepository()
      ..profile = VerifierProfile.fromJson({
        'id': 1, 'verifierUserId': 7, 'skillTags': ['sql'], 'available': true, 'verified': true,
        'rating': 4.5, 'reviewCount': 3, 'suspended': false,
      });
    final recognitionRepository = CountingRecognitionRepository();
    getIt.registerFactory<CaseReviewBloc>(() => CaseReviewBloc(caseRepository: caseRepository));
    addTearDown(getIt.reset);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => SessionBloc(authRepository: FakeAuthRepository())),
          BlocProvider(
            create: (_) => CasesBloc(
              userId: 7,
              caseRepository: caseRepository,
              reputationRepository: FakeReputationRepository(senior: false),
              // CasesBloc reads the wallet for its summary; keep its loads out of the count.
              recognitionRepository: FakeRecognitionRepository(),
            )..add(const CasesRequested()),
          ),
          // Eager, like in MainLayout, where the SkillCredits tab is built at start-up.
          BlocProvider(
            lazy: false,
            create: (_) => WalletBloc(userId: 7, recognitionRepository: recognitionRepository)
              ..add(const WalletRequested()),
          ),
        ],
        child: const MaterialApp(home: CasesView()),
      ),
    );
    await tester.pumpAndSettle();
    final loadsBeforeDecision = recognitionRepository.walletLoads;
    expect(loadsBeforeDecision, 1);

    final caseCard = find.textContaining('SK-2057');
    await tester.scrollUntilVisible(caseCard, 200);
    await tester.tap(caseCard);
    await tester.pumpAndSettle();
    // The approve button stays disabled until every rubric criterion is rated.
    final excellentChips = find.widgetWithText(ChoiceChip, RubricLevel.excellent.label);
    for (var i = 0; i < rubricFor(miniProject: false).length; i++) {
      await tester.ensureVisible(excellentChips.at(i));
      await tester.tap(excellentChips.at(i));
      await tester.pump();
    }
    final approveButton = find.widgetWithText(FilledButton, 'Aprobar caso');
    await tester.ensureVisible(approveButton);
    await tester.tap(approveButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Aprobar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();

    expect(caseRepository.sentDecision, 'Approved');
    expect(find.byType(CasesView), findsOneWidget);
    expect(recognitionRepository.walletLoads, greaterThan(loadsBeforeDecision));
  });
}
