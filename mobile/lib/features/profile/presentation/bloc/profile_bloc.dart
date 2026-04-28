import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/user_preferences.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/profile_repository.dart';
import 'load_status.dart';
import 'profile_event.dart';
import 'profile_section.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _repository;

  ProfileBloc({required ProfileRepository repository})
      : _repository = repository,
        super(const ProfileState()) {
    on<ProfileStarted>(_onProfileStarted);
    on<ProfileRefreshed>(_onProfileRefreshed);
    on<ProfileSectionRetryRequested>(_onProfileSectionRetryRequested);
    on<PreferencesUpdateRequested>(_onPreferencesUpdateRequested);
    on<PreferencesUpdateErrorDismissed>(_onPreferencesUpdateErrorDismissed);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<ProfileUpdateErrorDismissed>(_onProfileUpdateErrorDismissed);
    on<ProfilePhotoUploadRequested>(_onProfilePhotoUploadRequested);
    on<ProfilePhotoDeleteRequested>(_onProfilePhotoDeleteRequested);
  }

  /// Build PUT /users/me/profile patch: only changed editable keys; no nulls; empty string allowed.
  static Map<String, dynamic> _buildProfilePatch(
    UserProfile draft,
    UserProfile initial,
  ) {
    final patch = <String, dynamic>{};
    if (draft.firstName != initial.firstName && draft.firstName.isNotEmpty) {
      patch['firstName'] = draft.firstName;
    }
    if (draft.middleName != initial.middleName) {
      patch['middleName'] = draft.middleName ?? '';
    }
    if (draft.lastName != initial.lastName && draft.lastName.isNotEmpty) {
      patch['lastName'] = draft.lastName;
    }
    if (draft.preferredName != initial.preferredName) {
      patch['preferredName'] = draft.preferredName ?? '';
    }
    if (draft.country != initial.country) {
      patch['country'] = draft.country ?? '';
    }
    if (draft.birthDate != initial.birthDate) {
      if (draft.birthDate != null && draft.birthDate!.isNotEmpty) {
        patch['birthDate'] = draft.birthDate!;
      }
    }
    if (draft.gender != initial.gender) {
      if (draft.gender != null && draft.gender!.isNotEmpty) {
        patch['gender'] = draft.gender!;
      }
    }
    if (draft.profileImageUrl != initial.profileImageUrl) {
      patch['profileImageUrl'] = draft.profileImageUrl ?? '';
    }
    return patch;
  }

  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final previous = state.profile;
    final draft = event.draft;
    final patch = _buildProfilePatch(draft, event.initialProfile);
    if (patch.isEmpty) return;

    emit(state.copyWith(
      profile: draft,
      clearProfileUpdateError: true,
    ));

    if (!isClosed) {
      try {
        final updated = await _repository.updateProfile(patch);
        if (!isClosed) {
          emit(state.copyWith(profile: updated));
        }
      } catch (e) {
        if (!isClosed) {
          emit(state.copyWith(
            profile: previous,
            profileUpdateError: 'Could not save your profile. Please try again.',
          ));
        }
      }
    }
  }

  void _onProfileUpdateErrorDismissed(
    ProfileUpdateErrorDismissed event,
    Emitter<ProfileState> emit,
  ) {
    emit(state.copyWith(clearProfileUpdateError: true));
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Build PUT patch from draft vs previous; only changed fields. Empty lists included to clear.
  static Map<String, dynamic> _buildPreferencesPatch(
    UserPreferences draft,
    UserPreferences previous,
  ) {
    final patch = <String, dynamic>{};
    if (draft.travelStyle != previous.travelStyle) {
      if (draft.travelStyle != null) patch['travelStyle'] = draft.travelStyle;
    }
    if (!_listEquals(draft.favoriteCategories, previous.favoriteCategories)) {
      patch['favoriteCategories'] = draft.favoriteCategories;
    }
    if (draft.activityLevel != previous.activityLevel) {
      if (draft.activityLevel != null) patch['activityLevel'] = draft.activityLevel;
    }
    if (!_listEquals(draft.cuisinePreferences, previous.cuisinePreferences)) {
      patch['cuisinePreferences'] = draft.cuisinePreferences;
    }
    if (draft.preferredClimate != previous.preferredClimate) {
      if (draft.preferredClimate != null) patch['preferredClimate'] = draft.preferredClimate;
    }
    if (draft.tripPace != previous.tripPace) {
      if (draft.tripPace != null) patch['tripPace'] = draft.tripPace;
    }
    if (draft.accommodationType != previous.accommodationType) {
      if (draft.accommodationType != null) patch['accommodationType'] = draft.accommodationType;
    }
    if (draft.transportPreference != previous.transportPreference) {
      if (draft.transportPreference != null) {
        patch['transportPreference'] = draft.transportPreference;
      }
    }
    if (!_listEquals(draft.dietaryRestrictions, previous.dietaryRestrictions)) {
      patch['dietaryRestrictions'] = draft.dietaryRestrictions;
    }
    if (!_listEquals(draft.accessibilityNeeds, previous.accessibilityNeeds)) {
      patch['accessibilityNeeds'] = draft.accessibilityNeeds;
    }
    if (!_listEquals(draft.avoidCategories, previous.avoidCategories)) {
      patch['avoidCategories'] = draft.avoidCategories;
    }
    if (draft.dailyBudget != previous.dailyBudget) {
      if (draft.dailyBudget != null) {
        final v = draft.dailyBudget!;
        patch['dailyBudget'] = (v is int) ? v.toDouble() : v;
      }
    }
    if (draft.budgetCurrency != previous.budgetCurrency) {
      if (draft.budgetCurrency != null) patch['budgetCurrency'] = draft.budgetCurrency;
    }
    if (!_listEquals(draft.splurgeCategories, previous.splurgeCategories)) {
      patch['splurgeCategories'] = draft.splurgeCategories;
    }
    if (draft.preferredLanguage != previous.preferredLanguage) {
      if (draft.preferredLanguage != null) {
        patch['preferredLanguage'] = draft.preferredLanguage;
      }
    }
    if (!_listEquals(draft.spokenLanguages, previous.spokenLanguages)) {
      patch['spokenLanguages'] = draft.spokenLanguages;
    }
    return patch;
  }

  Future<void> _onPreferencesUpdateRequested(
    PreferencesUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final previous = state.preferences;
    final draft = event.draft;
    final patch = _buildPreferencesPatch(draft, event.initialPrefs);
    if (patch.isEmpty) {
      return;
    }

    emit(state.copyWith(
      preferences: draft,
      clearPreferencesUpdateError: true,
    ));

    dev.log(
      '[ProfileBloc] preferences optimistic update applied; patchKeys=${patch.keys.toList()}',
      name: 'ProfileBloc',
    );

    if (!isClosed) {
      try {
        final updated = await _repository.updatePreferences(patch);
        if (!isClosed) {
          emit(state.copyWith(preferences: updated));
        }
        dev.log(
          '[ProfileBloc] preferences update confirmed from backend',
          name: 'ProfileBloc',
        );
      } catch (e) {
        if (!isClosed) {
          emit(state.copyWith(
            preferences: previous,
            clearPreferences: previous == null,
            preferencesUpdateError: 'Could not save your preferences. Please try again.',
          ));
        }
        dev.log(
          '[ProfileBloc] preferences update failed, rolling back to previous; error=$e',
          name: 'ProfileBloc',
        );
      }
    }
  }

  void _onPreferencesUpdateErrorDismissed(
    PreferencesUpdateErrorDismissed event,
    Emitter<ProfileState> emit,
  ) {
    emit(state.copyWith(clearPreferencesUpdateError: true));
  }

  Future<void> _onProfilePhotoUploadRequested(
    ProfilePhotoUploadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(
      isProfilePhotoBusy: true,
      clearProfileUpdateError: true,
    ));
    try {
      await _repository.uploadProfilePhoto(event.filePath);
      await _loadProfile(emit);
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          isProfilePhotoBusy: false,
          profileUpdateError: 'Could not upload profile photo. Please try again.',
        ));
      }
      return;
    }
    if (!isClosed) {
      emit(state.copyWith(isProfilePhotoBusy: false));
    }
  }

  Future<void> _onProfilePhotoDeleteRequested(
    ProfilePhotoDeleteRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(
      isProfilePhotoBusy: true,
      clearProfileUpdateError: true,
    ));
    try {
      await _repository.deleteProfilePhoto();
      await _loadProfile(emit);
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          isProfilePhotoBusy: false,
          profileUpdateError: 'Could not remove profile photo. Please try again.',
        ));
      }
      return;
    }
    if (!isClosed) {
      emit(state.copyWith(isProfilePhotoBusy: false));
    }
  }

  /// Load all sections in parallel; each section's failure is isolated.
  Future<void> _onProfileStarted(
    ProfileStarted event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(
      profileStatus: LoadStatus.loading,
      preferencesStatus: LoadStatus.loading,
      statsStatus: LoadStatus.loading,
      checkInsStatus: LoadStatus.loading,
      sectionErrors: {},
    ));

    await Future.wait([
      _loadProfile(emit),
      _loadPreferences(emit),
      _loadStats(emit),
      _loadCheckIns(emit),
    ]);
  }

  /// Re-fetch all; keep previous data (no flicker).
  Future<void> _onProfileRefreshed(
    ProfileRefreshed event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(
      profileStatus: LoadStatus.loading,
      preferencesStatus: LoadStatus.loading,
      statsStatus: LoadStatus.loading,
      checkInsStatus: LoadStatus.loading,
      sectionErrors: {},
    ));

    await Future.wait([
      _loadProfile(emit),
      _loadPreferences(emit),
      _loadStats(emit),
      _loadCheckIns(emit),
    ]);
  }

  Future<void> _onProfileSectionRetryRequested(
    ProfileSectionRetryRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final updatedErrors =
        Map<ProfileSection, String>.from(state.sectionErrors)
          ..remove(event.section);

    switch (event.section) {
      case ProfileSection.profile:
        emit(state.copyWith(
          profileStatus: LoadStatus.loading,
          sectionErrors: updatedErrors,
        ));
        await _loadProfile(emit);
        break;
      case ProfileSection.preferences:
        emit(state.copyWith(
          preferencesStatus: LoadStatus.loading,
          sectionErrors: updatedErrors,
        ));
        await _loadPreferences(emit);
        break;
      case ProfileSection.stats:
        emit(state.copyWith(
          statsStatus: LoadStatus.loading,
          sectionErrors: updatedErrors,
        ));
        await _loadStats(emit);
        break;
      case ProfileSection.checkIns:
        emit(state.copyWith(
          checkInsStatus: LoadStatus.loading,
          sectionErrors: updatedErrors,
        ));
        await _loadCheckIns(emit);
        break;
    }
  }

  Future<void> _loadProfile(Emitter<ProfileState> emit) async {
    if (!isClosed) {
      try {
        final profile = await _repository.getProfile();
        Uint8List? photoBytes;
        if (profile.hasProfilePhoto) {
          try {
            photoBytes = await _repository.fetchProfilePhotoBytes();
          } catch (_) {
            photoBytes = null;
          }
        }
        if (!isClosed) {
          final errors =
              Map<ProfileSection, String>.from(state.sectionErrors)
                ..remove(ProfileSection.profile);
          if (!profile.hasProfilePhoto) {
            emit(state.copyWith(
              profileStatus: LoadStatus.success,
              profile: profile,
              clearProfilePhotoBytes: true,
              sectionErrors: errors,
            ));
          } else if (photoBytes != null) {
            emit(state.copyWith(
              profileStatus: LoadStatus.success,
              profile: profile,
              profilePhotoBytes: photoBytes,
              clearProfilePhotoBytes: false,
              sectionErrors: errors,
            ));
          } else {
            emit(state.copyWith(
              profileStatus: LoadStatus.success,
              profile: profile,
              clearProfilePhotoBytes: true,
              sectionErrors: errors,
            ));
          }
        }
      } catch (e) {
        if (!isClosed) {
          final errors =
              Map<ProfileSection, String>.from(state.sectionErrors)
                ..[ProfileSection.profile] = 'Could not load profile. Please try again.';
          emit(state.copyWith(
            profileStatus: LoadStatus.failure,
            clearProfilePhotoBytes: true,
            sectionErrors: errors,
          ));
        }
      }
    }
  }

  Future<void> _loadPreferences(Emitter<ProfileState> emit) async {
    if (!isClosed) {
      try {
        final preferences = await _repository.getPreferences();
        if (!isClosed) {
          final errors =
              Map<ProfileSection, String>.from(state.sectionErrors)
                ..remove(ProfileSection.preferences);
          emit(state.copyWith(
            preferencesStatus: LoadStatus.success,
            preferences: preferences,
            sectionErrors: errors,
          ));
        }
      } catch (e) {
        if (!isClosed) {
          final errors =
              Map<ProfileSection, String>.from(state.sectionErrors)
                ..[ProfileSection.preferences] = 'Could not load preferences. Please try again.';
          emit(state.copyWith(
            preferencesStatus: LoadStatus.failure,
            sectionErrors: errors,
          ));
        }
      }
    }
  }

  Future<void> _loadStats(Emitter<ProfileState> emit) async {
    if (!isClosed) {
      try {
        final stats = await _repository.getStats();
        if (!isClosed) {
          final errors =
              Map<ProfileSection, String>.from(state.sectionErrors)
                ..remove(ProfileSection.stats);
          emit(state.copyWith(
            statsStatus: LoadStatus.success,
            stats: stats,
            sectionErrors: errors,
          ));
        }
      } catch (e) {
        if (!isClosed) {
          final errors =
              Map<ProfileSection, String>.from(state.sectionErrors)
                ..[ProfileSection.stats] = 'Could not load stats. Please try again.';
          emit(state.copyWith(
            statsStatus: LoadStatus.failure,
            sectionErrors: errors,
          ));
        }
      }
    }
  }

  Future<void> _loadCheckIns(Emitter<ProfileState> emit) async {
    if (!isClosed) {
      try {
        final checkIns = await _repository.getCheckIns();
        if (!isClosed) {
          final errors =
              Map<ProfileSection, String>.from(state.sectionErrors)
                ..remove(ProfileSection.checkIns);
          emit(state.copyWith(
            checkInsStatus: LoadStatus.success,
            checkIns: checkIns,
            sectionErrors: errors,
          ));
        }
      } catch (e) {
        if (!isClosed) {
          final errors =
              Map<ProfileSection, String>.from(state.sectionErrors)
                ..[ProfileSection.checkIns] = 'Could not load check-ins. Please try again.';
          emit(state.copyWith(
            checkInsStatus: LoadStatus.failure,
            sectionErrors: errors,
          ));
        }
      }
    }
  }
}
