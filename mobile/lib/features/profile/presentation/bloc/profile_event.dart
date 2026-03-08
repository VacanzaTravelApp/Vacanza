import 'package:equatable/equatable.dart';

import 'profile_section.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Load all profile data when screen opens. Failures are isolated per section.
class ProfileStarted extends ProfileEvent {
  const ProfileStarted();
}

/// Re-fetch all sections; keep previous data while loading (no flicker).
class ProfileRefreshed extends ProfileEvent {
  const ProfileRefreshed();
}

/// Re-fetch only the given section.
class ProfileSectionRetryRequested extends ProfileEvent {
  final ProfileSection section;

  const ProfileSectionRetryRequested(this.section);

  @override
  List<Object?> get props => [section];
}
