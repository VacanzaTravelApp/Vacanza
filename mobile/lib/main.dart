import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/presentation/screens/register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("🔥 Firebase initialized apps: ${Firebase.apps}");
  runApp(const VacanzaApp());
}

class VacanzaApp extends StatelessWidget {
  const VacanzaApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Vacanza',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        fontFamily: 'SF Pro', // varsa kalsın, yoksa da sorun değil
      ),
      home: const RegisterScreen(),
    );
  }
}