import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import 'assessment/application/bloc/case_review_bloc.dart';
import 'assessment/application/bloc/cases_bloc.dart';
import 'assessment/domain/repositories/verification_case_repository.dart';
import 'assessment/infrastructure/repositories/verification_case_repository_impl.dart';
import 'iam/application/bloc/session_bloc.dart';
import 'iam/domain/repositories/auth_repository.dart';
import 'iam/infrastructure/repositories/auth_repository_impl.dart';
import 'recognition/application/bloc/share_bloc.dart';
import 'recognition/application/bloc/wallet_bloc.dart';
import 'recognition/domain/repositories/recognition_repository.dart';
import 'recognition/infrastructure/repositories/recognition_repository_impl.dart';
import 'reputation/application/bloc/metrics_bloc.dart';
import 'reputation/domain/repositories/reputation_repository.dart';
import 'reputation/infrastructure/repositories/reputation_repository_impl.dart';
import 'shared/domain/services/storage_service.dart';
import 'shared/infrastructure/network/api_config.dart';
import 'shared/infrastructure/network/auth_interceptor.dart';
import 'shared/infrastructure/network/session_token.dart';
import 'shared/infrastructure/services/secure_storage_service.dart';

final getIt = GetIt.instance;

// Registra en un solo lugar el cliente HTTP, los repositorios de cada bounded context y los BLoCs.
void setupServiceLocator() {
  // ---------- shared ----------
  getIt.registerLazySingleton<SessionToken>(() => SessionToken());
  getIt.registerLazySingleton<StorageService>(() => SecureStorageService());
  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      headers: {
        'Accept': 'application/json',
        'Accept-Language': 'es-419', // mensajes de error del backend en español
      },
    ));
    dio.interceptors.add(AuthInterceptor(getIt<SessionToken>()));
    return dio;
  });

  // ---------- repositorios ----------
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(dio: getIt<Dio>(), storage: getIt<StorageService>(), token: getIt<SessionToken>()),
  );
  getIt.registerLazySingleton<VerificationCaseRepository>(() => VerificationCaseRepositoryImpl(dio: getIt<Dio>()));
  getIt.registerLazySingleton<ReputationRepository>(() => ReputationRepositoryImpl(dio: getIt<Dio>()));
  getIt.registerLazySingleton<RecognitionRepository>(() => RecognitionRepositoryImpl(dio: getIt<Dio>()));

  // ---------- BLoCs ----------
  getIt.registerLazySingleton<SessionBloc>(() => SessionBloc(authRepository: getIt<AuthRepository>()));
  // Los demás se crean por pantalla, con el usuario que inició sesión
  getIt.registerFactory<CasesBloc>(() => CasesBloc(
        userId: _currentUserId(),
        caseRepository: getIt<VerificationCaseRepository>(),
        reputationRepository: getIt<ReputationRepository>(),
        recognitionRepository: getIt<RecognitionRepository>(),
      ));
  getIt.registerFactory<CaseReviewBloc>(() => CaseReviewBloc(caseRepository: getIt<VerificationCaseRepository>()));
  getIt.registerFactory<WalletBloc>(
    () => WalletBloc(userId: _currentUserId(), recognitionRepository: getIt<RecognitionRepository>()),
  );
  getIt.registerFactory<ShareBloc>(() => ShareBloc(
        userId: _currentUserId(),
        recognitionRepository: getIt<RecognitionRepository>(),
        caseRepository: getIt<VerificationCaseRepository>(),
        reputationRepository: getIt<ReputationRepository>(),
      ));
  getIt.registerFactory<MetricsBloc>(() => MetricsBloc(reputationRepository: getIt<ReputationRepository>()));
}

int _currentUserId() {
  final state = getIt<SessionBloc>().state;
  return state is Authenticated ? state.user.id : 0;
}
