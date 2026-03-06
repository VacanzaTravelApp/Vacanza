import 'package:equatable/equatable.dart';

import '../../data/models/check_in.dart';
import '../../data/models/travel_stats.dart';
import '../../data/models/user_preferences.dart';
import '../../data/models/user_profile.dart';
import 'load_status.dart';
import 'profile_section.dart';

class ProfileState extends Equatable {
  final LoadStatus profileStatus;
  final LoadStatus preferencesStatus;
  final LoadStatus statsStatus;
  final LoadStatus checkInsStatus;
  final UserProfile? profile;
  final UserPreferences? preferences;
  final TravelStats? stats;
  final List<CheckIn> checkIns;
  /// Per-section error messages; cleared on success or retry.
  final Map<ProfileSection, String> sectionErrors;

  const ProfileState({
    this.profileStatus = LoadStatus.initial,
    this.preferencesStatus = LoadStatus.initial,
    this.statsStatus = LoadStatus.initial,
    this.checkInsStatus = LoadStatus.initial,
    this.profile,
    this.preferences,
    this.stats,
    this.checkIns = const [],
    this.sectionErrors = const {},
  });

  ProfileState copyWith({
    LoadStatus? profileStatus,
    LoadStatus? preferencesStatus,
    LoadStatus? statsStatus,
    LoadStatus? checkInsStatus,
    UserProfile? profile,
    UserPreferences? preferences,
    TravelStats? stats,
    List<CheckIn>? checkIns,
    Map<ProfileSection, String>? sectionErrors,
  }) {
    return ProfileState(
      profileStatus: profileStatus ?? this.profileStatus,
      preferencesStatus: preferencesStatus ?? this.preferencesStatus,
      statsStatus: statsStatus ?? this.statsStatus,
      checkInsStatus: checkInsStatus ?? this.checkInsStatus,
      profile: profile ?? this.profile,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
      checkIns: checkIns ?? this.checkIns,
      sectionErrors: sectionErrors ?? this.sectionErrors,
    );
  }

  String? errorFor(ProfileSection section) => sectionErrors[section];

  @override
  List<Object?> get props => [
        profileStatus,
        preferencesStatus,
        statsStatus,
        checkInsStatus,
        profile,
        preferences,
        stats,
        checkIns,
        sectionErrors,
      ];
}
