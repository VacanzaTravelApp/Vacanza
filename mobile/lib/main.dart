import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'core/config/mapbox_config.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/theme/theme_lifecycle.dart';
import 'firebase_options.dart';

import 'core/navigation/navigation_service.dart';
import 'core/network/app_dio.dart';

import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/data/storage/secure_storage_service.dart';

import 'features/poi_search/data/api/poi_search_api_client.dart';

import 'features/gamification/data/api/gamification_api_client.dart';
import 'features/gamification/data/repositories/gamification_repository.dart';
import 'features/gamification/presentation/cubit/gamification_cubit.dart';

import 'features/booking/data/api/booking_api_client.dart';
import 'features/booking/data/repositories/booking_repository.dart';

import 'features/chat/data/api/chat_api_client.dart';

import 'features/profile/data/datasources/profile_remote_data_source.dart';
import 'features/profile/data/repositories/profile_repository.dart';

import 'features/auth/presentation/bloc/register_bloc.dart';
import 'features/auth/presentation/bloc/login_bloc.dart';
import 'features/auth/presentation/screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mapbox public token (build-time only; never commit — see MapboxConfig)
  if (MapboxConfig.accessToken.isEmpty) {
    throw StateError(
      'MAPBOX_ACCESS_TOKEN is not set. Run with:\n'
      '  flutter run --dart-define=MAPBOX_ACCESS_TOKEN=pk.your_public_token\n'
      'Or add the same flag to your IDE run configuration.',
    );
  }
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

        /// Booking API client (UC1.8-MOB4)
        RepositoryProvider<BookingApiClient>(
          create: (ctx) => BookingApiClient(ctx.read<Dio>()),
        ),

        /// Booking repository (UC1.8-MOB5)
        RepositoryProvider<BookingRepository>(
          create: (ctx) => BookingRepository(
            apiClient: ctx.read<BookingApiClient>(),
          ),
        ),

        /// Chat API client (AI chatbot)
        RepositoryProvider<ChatApiClient>(
          create: (ctx) => ChatApiClient(ctx.read<Dio>()),
        ),

        /// Profile (MOB-9 / profile feature)
        RepositoryProvider<ProfileRemoteDataSource>(
          create: (ctx) => ProfileRemoteDataSource(ctx.read<Dio>()),
        ),
        RepositoryProvider<ProfileRepository>(
          create: (ctx) => ProfileRepository(
            dataSource: ctx.read<ProfileRemoteDataSource>(),
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
        child: BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(),
          child: BlocBuilder<ThemeCubit, ThemeCubitState>(
            buildWhen: (a, b) => a.resolvedThemeMode != b.resolvedThemeMode,
            builder: (context, themeState) {
              return ThemeLifecycle(
                child: MaterialApp(
                  navigatorKey: NavigationService.navigatorKey,
                  debugShowCheckedModeBanner: false,
                  title: 'Vacanza',
                  theme: AppTheme.light(),
                  darkTheme: AppTheme.dark(),
                  themeMode: themeState.resolvedThemeMode,
                  home: const AuthGate(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}