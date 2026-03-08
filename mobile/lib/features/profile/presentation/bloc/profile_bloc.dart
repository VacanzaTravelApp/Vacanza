import 'package:flutter_bloc/flutter_bloc.dart';

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
        if (!isClosed) {
          final errors =
              Map<ProfileSection, String>.from(state.sectionErrors)
                ..remove(ProfileSection.profile);
          emit(state.copyWith(
            profileStatus: LoadStatus.success,
            profile: profile,
            sectionErrors: errors,
          ));
        }
      } catch (e) {
        if (!isClosed) {
          final errors =
              Map<ProfileSection, String>.from(state.sectionErrors)
                ..[ProfileSection.profile] = e.toString();
          emit(state.copyWith(
            profileStatus: LoadStatus.failure,
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
                ..[ProfileSection.preferences] = e.toString();
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
                ..[ProfileSection.stats] = e.toString();
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
                ..[ProfileSection.checkIns] = e.toString();
          emit(state.copyWith(
            checkInsStatus: LoadStatus.failure,
            sectionErrors: errors,
          ));
        }
      }
    }
  }
}
