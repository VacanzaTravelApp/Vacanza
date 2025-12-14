import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/screens/login_screen.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  /// Logout butonuna basılınca çalışır.
  /// 1) tokenları temizler + firebase signout
  /// 2) stack temizleyerek login ekranına gider
  Future<void> _handleLogout(BuildContext context) async {
    await context.read<AuthRepository>().logout();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: const Center(
        child: Text('Mock Map Screen'),
      ),
    );
  }
}