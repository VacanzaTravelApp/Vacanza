import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/presentation/screens/register_screen.dart';

void main() {
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
        fontFamily: 'SF Pro', // yoksa silebilirsin
      ),
      home: const RegisterScreen(),
    );
  }
}
