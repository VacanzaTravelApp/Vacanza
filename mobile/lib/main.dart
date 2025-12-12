import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobile/features/auth/presentation/screens/login_screen.dart';

import 'core/theme/app_colors.dart';
import 'firebase_options.dart';

// Auth data layer
import 'features/auth/data/repositories/auth_repository.dart';

import 'package:mobile/core/navigation/navigation_service.dart';
// Auth BLoCs
import 'features/auth/presentation/bloc/register_bloc.dart';
import 'features/auth/presentation/bloc/login_bloc.dart';

// Entry gate that decides Login vs Map on app start
import 'features/auth/presentation/screens/auth_gate.dart';

void main() async {
  // Flutter binding'i initialize ediyoruz (Firebase gibi async init'ler için şart).
  WidgetsFlutterBinding.ensureInitialized();

  // ----------------------------------------
  // 🔥 Firebase init
  // ----------------------------------------
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
        // ----------------------------------------
        // 🌐 AuthRepository Provider
        // ----------------------------------------
        //
        // Uygulamanın her yerinde AuthRepository'e ihtiyaç duyacağız
        // (register, login, logout, token yenileme vs).
        //
        // Burada 1 kere oluşturup widget tree'ye yukarıdan enjekte ediyoruz.
        // Örnek erişim:
        //
        //   final authRepo = context.read<AuthRepository>();
        //
        RepositoryProvider<AuthRepository>(
          create: (_) => AuthRepository(),
        ),

        // İLERİDE:
        // Buraya yeni repository'ler eklenebilir:
        // - ProfileRepository
        // - TripsRepository
        // - MapRepository
        // vs.
      ],
      child: MultiBlocProvider(
        providers: [
          // ----------------------------------------
          // 🧠 RegisterBloc Provider
          // ----------------------------------------
          //
          // "Register" ekranının iş mantığını yönetir:
          // - RegisterSubmitted event'ini alır
          // - AuthRepository üzerinden Firebase register çağırır
          // - (Backend hazır olunca) /auth/register endpoint'ine de gidecek
          // - UI için status (initial/submitting/success/failure) üretir
          //
          BlocProvider<RegisterBloc>(
            create: (context) => RegisterBloc(
              authRepository: context.read<AuthRepository>(),
            ),
          ),

          // ----------------------------------------
          // 🧠 LoginBloc Provider
          // ----------------------------------------
          //
          // "Login" ekranının iş mantığını yönetir:
          // - LoginSubmitted event'ini alır
          // - AuthRepository.loginWithEmailAndPassword üzerinden
          //   Firebase login + (ileride) backend login akışını yönetir.
          //
          BlocProvider<LoginBloc>(
            create: (context) => LoginBloc(
              authRepository: context.read<AuthRepository>(),
            ),
          ),

          // İLERİDE:
          // - ProfileBloc
          // - MapBloc
          // gibi bloklar da buraya eklenecek.
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
            fontFamily: 'SF Pro', // yoksa kaldırılabilir
          ),

          // Artık doğrudan RegisterScreen veya LoginScreen açmıyoruz.
          //
          // AuthGate:
          //  - App açıldığında SecureStorage içindeki access_token'a bakar
          //  - Token varsa → MapScreen
          //  - Token yoksa → LoginScreen
          //
          // Böylece VACANZA-85'te istenen "authenticated state'e geçiş"
          // ve "app tekrar açıldığında doğrudan Home'a gitme" kurgusu sağlanmış olur.
          //home: const AuthGate(), just for now until VACANZA 87
          home: const LoginScreen(),
        ),
      ),
    );
  }
}