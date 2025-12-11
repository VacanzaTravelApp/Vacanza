import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_colors.dart';

// Firebase options (flutterfire configure ile oluşan dosya)
import 'features/auth/presentation/bloc/login_bloc.dart';
import 'firebase_options.dart';

// Auth katmanı
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/register_bloc.dart';
import 'features/auth/presentation/bloc/register_state.dart';
import 'features/auth/presentation/screens/register_screen.dart';

void main() async {
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
        // Erişim örneği:
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
          // Sadece "Register" ekranının iş mantığını yönetir:
          // - RegisterSubmitted eventini alır
          // - AuthRepository üzerinden Firebase register çağırır
          // - (Backend hazır olunca) /auth/register endpointine de gidecek
          // - UI için status (initial/submitting/success/failure) üretir
          //
          // Bu sayede:
          //   context.read<RegisterBloc>().add(RegisterSubmitted(...));
          //   context.watch<RegisterBloc>().state
          // gibi kullanım mümkün hale gelir.
          //
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
          // İLERİDE:
          // - LoginBloc
          // - ProfileBloc
          // - MapBloc
          // gibi bloklar da buraya eklenecek.
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Vacanza',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.light,
            ),
            fontFamily: 'SF Pro', // yoksa silebilirsin
          ),

          // Şimdilik başlangıç ekranı RegisterScreen.
          // VACANZA-82 ve sonrası ile:
          // - register success → home/map/profil akışını
          // - auth state'e göre yönlendirmeyi
          // ayrı bir router veya AuthGate ile yapacağız.
          home: const RegisterScreen(),
        ),
      ),
    );
  }
}