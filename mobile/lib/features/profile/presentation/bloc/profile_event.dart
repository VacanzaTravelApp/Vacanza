import 'package:equatable/equatable.dart';

import '../../data/models/user_preferences.dart';
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

/// Edit Preferences sheet saved: optimistic update then PUT; rollback on failure.
/// [initialPrefs] is the prefs when the sheet opened; bloc builds patch from draft vs initialPrefs.
class PreferencesUpdateRequested extends ProfileEvent {
  final UserPreferences initialPrefs;
  final UserPreferences draft;

  const PreferencesUpdateRequested(this.initialPrefs, this.draft);

  @override
  List<Object?> get props => [initialPrefs, draft];
}

/// Clear the one-off preferences update error (e.g. after showing SnackBar).
class PreferencesUpdateErrorDismissed extends ProfileEvent {
  const PreferencesUpdateErrorDismissed();
}
