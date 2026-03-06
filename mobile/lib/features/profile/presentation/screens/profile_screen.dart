import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/load_status.dart';
import '../bloc/profile_state.dart';

/// Profile hub screen. Triggers [ProfileStarted] on open.
/// Header and gamification UI stay here; section cards come in Task 3.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileBloc>().add(const ProfileStarted());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFFFAFAFA),
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          final loading = state.profileStatus == LoadStatus.loading &&
              state.preferencesStatus == LoadStatus.loading &&
              state.statsStatus == LoadStatus.loading &&
              state.checkInsStatus == LoadStatus.loading;
          final anyError = state.profileStatus == LoadStatus.failure ||
              state.preferencesStatus == LoadStatus.failure ||
              state.statsStatus == LoadStatus.failure ||
              state.checkInsStatus == LoadStatus.failure;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.profile != null) ...[
                  Text(
                    state.profile!.displayNameFallback,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.profile!.email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5F7A8F),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (loading && state.profile == null)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (anyError && state.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
