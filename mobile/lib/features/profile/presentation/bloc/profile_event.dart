import 'package:equatable/equatable.dart';

import 'profile_section.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Load all profile data when screen opens.
class ProfileStarted extends ProfileEvent {
  const ProfileStarted();
}

/// Refresh all sections (e.g. pull-to-refresh).
class ProfileRefreshed extends ProfileEvent {
  const ProfileRefreshed();
}

/// Retry only one section after failure.
class ProfileSectionRetryRequested extends ProfileEvent {
  final ProfileSection section;

  const ProfileSectionRetryRequested(this.section);

  @override
  List<Object?> get props => [section];
}
