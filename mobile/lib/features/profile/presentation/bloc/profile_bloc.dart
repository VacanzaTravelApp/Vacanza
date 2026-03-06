import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/check_in.dart';
import '../../data/models/travel_stats.dart';
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
  }

  Future<void> _onProfileStarted(
    ProfileStarted event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(
      profileStatus: LoadStatus.loading,
      preferencesStatus: LoadStatus.loading,
      statsStatus: LoadStatus.loading,
      checkInsStatus: LoadStatus.loading,
      errorMessage: null,
    ));

    await Future.wait([
      _loadProfile(emit),
      _loadPreferences(emit),
      _loadStats(emit),
      _loadCheckIns(emit),
    ]);
  }

  Future<void> _onProfileRefreshed(
    ProfileRefreshed event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(
      profileStatus: LoadStatus.loading,
      preferencesStatus: LoadStatus.loading,
      statsStatus: LoadStatus.loading,
      checkInsStatus: LoadStatus.loading,
      errorMessage: null,
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
    switch (event.section) {
      case ProfileSection.profile:
        emit(state.copyWith(profileStatus: LoadStatus.loading, errorMessage: null));
        await _loadProfile(emit);
        break;
      case ProfileSection.preferences:
        emit(state.copyWith(
            preferencesStatus: LoadStatus.loading, errorMessage: null));
        await _loadPreferences(emit);
        break;
      case ProfileSection.stats:
        emit(state.copyWith(statsStatus: LoadStatus.loading, errorMessage: null));
        await _loadStats(emit);
        break;
      case ProfileSection.checkIns:
        emit(state.copyWith(
            checkInsStatus: LoadStatus.loading, errorMessage: null));
        await _loadCheckIns(emit);
        break;
    }
  }

  Future<void> _loadProfile(Emitter<ProfileState> emit) async {
    if (!isClosed) {
      try {
        final profile = await _repository.getProfile();
        emit(state.copyWith(
          profileStatus: LoadStatus.success,
          profile: profile,
          errorMessage: null,
        ));
      } catch (e) {
        emit(state.copyWith(
          profileStatus: LoadStatus.failure,
          errorMessage: e.toString(),
        ));
      }
    }
  }

  Future<void> _loadPreferences(Emitter<ProfileState> emit) async {
    if (!isClosed) {
      try {
        final preferences = await _repository.getPreferences();
        emit(state.copyWith(
          preferencesStatus: LoadStatus.success,
          preferences: preferences,
          errorMessage: null,
        ));
      } catch (e) {
        emit(state.copyWith(
          preferencesStatus: LoadStatus.failure,
          errorMessage: e.toString(),
        ));
      }
    }
  }

  Future<void> _loadStats(Emitter<ProfileState> emit) async {
    if (!isClosed) {
      try {
        final stats = await _repository.getStats();
        emit(state.copyWith(
          statsStatus: LoadStatus.success,
          stats: stats,
          errorMessage: null,
        ));
      } catch (e) {
        emit(state.copyWith(
          statsStatus: LoadStatus.failure,
          errorMessage: e.toString(),
        ));
      }
    }
  }

  Future<void> _loadCheckIns(Emitter<ProfileState> emit) async {
    if (!isClosed) {
      try {
        final checkIns = await _repository.getCheckIns();
        emit(state.copyWith(
          checkInsStatus: LoadStatus.success,
          checkIns: checkIns,
          errorMessage: null,
        ));
      } catch (e) {
        emit(state.copyWith(
          checkInsStatus: LoadStatus.failure,
          errorMessage: e.toString(),
        ));
      }
    }
  }
}
