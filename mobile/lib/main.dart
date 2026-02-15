import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'core/config/mapbox_config.dart';
import 'core/theme/app_colors.dart';
import 'firebase_options.dart';

import 'core/navigation/navigation_service.dart';
import 'core/network/app_dio.dart';

import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/data/storage/secure_storage_service.dart';

import 'features/poi_search/data/api/poi_search_api_client.dart';

import 'features/gamification/data/api/gamification_api_client.dart';
import 'features/gamification/data/repositories/gamification_repository.dart';
import 'features/gamification/presentation/cubit/gamification_cubit.dart';

import 'features/auth/presentation/bloc/register_bloc.dart';
import 'features/auth/presentation/bloc/login_bloc.dart';
import 'features/auth/presentation/screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mapbox token
  MapboxOptions.setAccessToken(MapboxConfig.accessToken);

  // Firebase init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const VacanzaApp());
}

class VacanzaApp extends StatelessWidget {
  const VacanzaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        /// Storage tek instance (token burada tutuluyor)
        RepositoryProvider<SecureStorageService>(
          create: (_) => SecureStorageService(),
        ),

        /// Dio tek instance (baseUrl + interceptor burada)
        RepositoryProvider<Dio>(
          create: (ctx) => createAppDio(
            storage: ctx.read<SecureStorageService>(),
          ),
        ),

        /// AuthRepository aynı Dio'yu kullanır
        RepositoryProvider<AuthRepository>(
          create: (ctx) => AuthRepository(
            dio: ctx.read<Dio>(),
            storage: ctx.read<SecureStorageService>(),
          ),
        ),

        /// POI Search client aynı Dio'yu kullanır
        RepositoryProvider<PoiSearchApiClient>(
          create: (ctx) => PoiSearchApiClient(ctx.read<Dio>()),
        ),

        /// Gamification API client (MOB-8)
        RepositoryProvider<GamificationApiClient>(
          create: (ctx) => GamificationApiClient(ctx.read<Dio>()),
        ),

        /// Gamification repository (MOB-8)
        RepositoryProvider<GamificationRepository>(
          create: (ctx) => GamificationRepository(
            apiClient: ctx.read<GamificationApiClient>(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<RegisterBloc>(
            create: (context) => RegisterBloc(
              authRepository: context.read<AuthRepository>(),
            ),
          ),
          BlocProvider<LoginBloc>(
            create: (context) => LoginBloc(
              authRepository: context.read<AuthRepository>(),
            ),
          ),

          /// Gamification cubit (MOB-8) — app-wide for Profile + MOB-12
          BlocProvider<GamificationCubit>(
            create: (context) => GamificationCubit(
              repository: context.read<GamificationRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          navigatorKey: NavigationService.navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Vacanza',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.light,
            ),
            fontFamily: 'SF Pro',
          ),
          home: const AuthGate(),
        ),
      ),
    );
  }
}