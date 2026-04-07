import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile/core/navigation/navigation_service.dart';

import '../../../auth/data/repositories/auth_repository.dart';
import '../../data/models/user_profile.dart';
import '../bloc/load_status.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_section.dart';
import '../bloc/profile_state.dart';
import '../widgets/edit_profile_sheet.dart';
import '../widgets/appearance_settings_sheet.dart';

class AccountDetailsScreen extends StatelessWidget {
  const AccountDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chevron_left, size: 28),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          cs.surfaceContainerHighest.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Account Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<ProfileBloc, ProfileState>(
                  buildWhen: (p, n) =>
                      p.profileStatus != n.profileStatus ||
                      p.profile != n.profile,
                  builder: (context, state) {
                    if (state.profileStatus == LoadStatus.loading &&
                        state.profile == null) {
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onSurfaceVariant,
                        ),
                      );
                    }
                    if (state.profileStatus == LoadStatus.failure) {
                      return _ErrorState(
                        message:
                            state.errorFor(ProfileSection.profile) ?? 'Error',
                      );
                    }
                    final p = state.profile;
                    if (p == null) {
                      return Text(
                        'No profile loaded.',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      );
                    }

                    final joined = p.joinDate != null
                        ? '${p.joinDate!.year}-${p.joinDate!.month.toString().padLeft(2, '0')}-${p.joinDate!.day.toString().padLeft(2, '0')}'
                        : '—';

                    return ListView(
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            final profileBloc = context.read<ProfileBloc>();
                            final initial = profileBloc.state.profile ??
                                UserProfile.defaultForDraft(
                                  userId: profileBloc.state.profile?.userId ?? '',
                                  email: profileBloc.state.profile?.email ?? '',
                                );
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => BlocProvider.value(
                                value: profileBloc,
                                child: EditProfileSheet(initialProfile: initial),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: const Text('Edit Profile'),
                        ),
                        const SizedBox(height: 12),
                        _InfoCard(
                          title: 'Basics',
                          children: [
                            _InfoRow(label: 'Email', value: p.email),
                            _InfoRow(label: 'Joined', value: joined),
                            _InfoRow(label: 'Country', value: p.country ?? '—'),
                            _InfoRow(
                              label: 'Gender',
                              value: p.gender?.replaceAll('_', ' ') ?? '—',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _InfoCard(
                          title: 'Actions',
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Appearance'),
                              subtitle:
                                  const Text('Theme: system / scheduled / manual'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => showAppearanceSettingsSheet(context),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Logout',
                                style: TextStyle(color: cs.error),
                              ),
                              trailing: Icon(Icons.logout_rounded, color: cs.error),
                              onTap: () => _logout(context),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await context.read<AuthRepository>().logout();
    } finally {
      NavigationService.resetToLogin();
    }
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: cs.error, fontSize: 14),
        ),
      ),
    );
  }
}

