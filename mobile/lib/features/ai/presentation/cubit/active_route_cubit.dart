import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile/core/network/backend_error_parser.dart';
import 'package:mobile/features/ai/data/api/ai_route_api_client.dart';
import 'package:mobile/features/ai/utils/route_map.dart';
import 'package:mobile/features/chat/data/api/chat_api_client.dart';
import 'package:mobile/features/chat/data/models/chat_models.dart';

import 'active_route_state.dart';

class ActiveRouteCubit extends Cubit<ActiveRouteState> {
  final ChatApiClient _chatApi;
  final AiRouteApiClient _routeApi;

  ActiveRouteCubit({
    required ChatApiClient chatApi,
    required AiRouteApiClient routeApi,
  }) : _chatApi = chatApi,
       _routeApi = routeApi,
       super(const ActiveRouteState.initial());

  void clearError() => emit(state.copyWith(clearError: true));

  void reset() => emit(const ActiveRouteState.initial());

  /// Sheet X: keep last route for mini pill + reopen, hide polyline/markers only.
  void hideRouteFromMap() {
    if (state.route == null) return;
    emit(state.copyWith(showRouteOnMap: false));
  }

  /// Mini pill tap after [hideRouteFromMap]: draw route on map again.
  void showRouteOnMapAgain() {
    if (state.route == null) return;
    emit(state.copyWith(showRouteOnMap: true));
  }

  void setActiveDay(int day) {
    if (state.route == null) return;
    if (day < 1 || day > state.route!.totalDays) return;
    emit(state.copyWith(activeDay: day));
  }

  /// Called when chat returns a route payload (may or may not be saved).
  void setFromChatResponse(MessageSendResponse res) {
    final rd = res.routeData;
    if (rd == null) return;
    final model = RouteMapModel.fromChat(rd);
    final day = firstCalendarDayForMap(model);
    emit(
      state.copyWith(
        status: ActiveRouteStatus.ready,
        errorMessage: null,
        route: model,
        activeDay: day,
        routeId: res.routeId,
        conversationId: res.conversationId,
        showRouteOnMap: true,
      ),
    );
  }

  Future<void> createFromPolygon({
    required List<List<double>> coordinates,
    int? totalDays,
    String? travelStyle,
    List<String>? categories,
    bool? includeFavorites,
  }) async {
    emit(state.copyWith(status: ActiveRouteStatus.loading, clearError: true));
    try {
      final res = await _chatApi.createRouteFromPolygon(
        coordinates: coordinates,
        totalDays: totalDays,
        travelStyle: travelStyle,
        categories: categories,
        includeFavorites: includeFavorites,
      );
      if (res.routeData == null) {
        emit(
          state.copyWith(
            status: ActiveRouteStatus.failure,
            errorMessage: 'Route could not be generated. Please try again.',
          ),
        );
        return;
      }
      setFromChatResponse(res);
    } on DioException catch (e, st) {
      dev.log(
        'createFromPolygon failed: $e',
        stackTrace: st,
        name: 'ActiveRoute',
      );
      emit(
        state.copyWith(
          status: ActiveRouteStatus.failure,
          errorMessage: extractBackendMessage(e),
        ),
      );
    } catch (e, st) {
      dev.log(
        'createFromPolygon failed: $e',
        stackTrace: st,
        name: 'ActiveRoute',
      );
      emit(
        state.copyWith(
          status: ActiveRouteStatus.failure,
          errorMessage: 'Route could not be generated. Please try again.',
        ),
      );
    }
  }

  Future<void> replanDayFromPolygon({
    required String conversationId,
    required int day,
    required List<List<double>> coordinates,
    String? travelStyle,
    List<String>? categories,
  }) async {
    emit(state.copyWith(status: ActiveRouteStatus.loading, clearError: true));
    try {
      final res = await _chatApi.replanDayFromPolygon(
        conversationId: conversationId,
        day: day,
        coordinates: coordinates,
        travelStyle: travelStyle,
        categories: categories,
      );
      if (res.routeData == null) {
        emit(
          state.copyWith(
            status: ActiveRouteStatus.failure,
            errorMessage: 'Route could not be replanned. Please try again.',
          ),
        );
        return;
      }
      setFromChatResponse(res);
    } on DioException catch (e, st) {
      dev.log(
        'replanDayFromPolygon failed: $e',
        stackTrace: st,
        name: 'ActiveRoute',
      );
      emit(
        state.copyWith(
          status: ActiveRouteStatus.failure,
          errorMessage: extractBackendMessage(e),
        ),
      );
    } catch (e, st) {
      dev.log(
        'replanDayFromPolygon failed: $e',
        stackTrace: st,
        name: 'ActiveRoute',
      );
      emit(
        state.copyWith(
          status: ActiveRouteStatus.failure,
          errorMessage: 'Route could not be replanned. Please try again.',
        ),
      );
    }
  }

  /// Hydrate the route payload from a saved routeId (GET /routes/{id}).
  /// This enables showing the same route even if chat did not include route_data later.
  Future<void> loadSavedRoute(String routeId) async {
    final preservedConversationId = state.conversationId;
    emit(state.copyWith(status: ActiveRouteStatus.loading, clearError: true));
    try {
      final json = await _routeApi.getRoute(routeId);
      final routeData = json['routeData'] ?? json['route_data'];
      if (routeData is! Map<String, dynamic>) {
        emit(
          state.copyWith(
            status: ActiveRouteStatus.failure,
            errorMessage: 'Route could not be loaded.',
          ),
        );
        return;
      }
      final selectedHotelRaw = json['selectedHotel'] ?? json['selected_hotel'];
      RouteHotel? selectedHotel;
      if (selectedHotelRaw is Map<String, dynamic>) {
        selectedHotel = RouteHotel.fromJson(selectedHotelRaw);
      } else if (selectedHotelRaw is Map) {
        selectedHotel = RouteHotel.fromJson(
          Map<String, dynamic>.from(selectedHotelRaw),
        );
      }
      final chatLike = ChatRouteData.fromJson(routeData);
      final model = RouteMapModel.fromSavedRoute(
        routeData: chatLike,
        selectedHotel: selectedHotel,
      );
      emit(
        state.copyWith(
          status: ActiveRouteStatus.ready,
          routeId: routeId,
          route: model,
          activeDay: firstCalendarDayForMap(model),
          conversationId: preservedConversationId,
          showRouteOnMap: true,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: ActiveRouteStatus.failure,
          errorMessage: extractBackendMessage(e),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ActiveRouteStatus.failure,
          errorMessage: 'Route could not be loaded.',
        ),
      );
    }
  }

  /// User reported a stop is closed — same flow as web `POST /api/routes/{id}/adjust`.
  Future<void> markWaypointClosed({
    required String poiName,
    required int day,
  }) async {
    final rid = state.routeId;
    if (rid == null) {
      emit(
        state.copyWith(
          status: ActiveRouteStatus.failure,
          errorMessage:
              'This route must be saved before reporting a closed place.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: ActiveRouteStatus.loading, clearError: true));
    try {
      final result = await _routeApi.adjustRoute(
        routeId: rid,
        body: {
          'triggerType': 'USER_REPORTED',
          'severity': 'MEDIUM',
          'affectedPoiName': poiName,
          'affectedDay': day,
          'reason': 'User reported this place is closed.',
        },
      );

      final rawNew = result['newRouteId'] ?? result['new_route_id'];
      if (rawNew == null) {
        final async = result['async'] == true;
        emit(
          state.copyWith(
            status: ActiveRouteStatus.failure,
            errorMessage:
                async
                    ? 'Route update is still processing. Please try again in a moment.'
                    : 'Could not update the route.',
          ),
        );
        return;
      }

      await loadSavedRoute(rawNew.toString());
    } on DioException catch (e, st) {
      dev.log(
        'markWaypointClosed failed: $e',
        stackTrace: st,
        name: 'ActiveRoute',
      );
      emit(
        state.copyWith(
          status: ActiveRouteStatus.failure,
          errorMessage: extractBackendMessage(e),
        ),
      );
    } catch (e, st) {
      dev.log(
        'markWaypointClosed failed: $e',
        stackTrace: st,
        name: 'ActiveRoute',
      );
      emit(
        state.copyWith(
          status: ActiveRouteStatus.failure,
          errorMessage: 'Could not update the route.',
        ),
      );
    }
  }
}
