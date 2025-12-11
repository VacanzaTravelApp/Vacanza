import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_colors.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/screens/register_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VacanzaApp());
}

class VacanzaApp extends StatelessWidget {
  const VacanzaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        // -----------------------------
        // AUTH REPOSITORY PROVIDER
        // -----------------------------
        //
        // Uygulamanın tamamında AuthRepository'ye ihtiyaç duyacağız
        // (register, login, logout, token yenileme vs.)
        //
        // Burada 1 kere oluşturup yukarıdan sağlıyoruz.
        // Örnek erişim:
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
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Vacanza',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
          fontFamily: 'SF Pro', // yoksa kaldırabiliriz
        ),
        // Şimdilik ilk ekran RegisterScreen.
        // İleride auth flow oturunca burayı bir "AppRouter" ile değiştirebiliriz.
        home: const RegisterScreen(),
      ),
    );
  }
}