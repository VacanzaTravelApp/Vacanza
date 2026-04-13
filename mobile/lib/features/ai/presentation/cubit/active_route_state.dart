import 'package:equatable/equatable.dart';
import 'package:mobile/features/ai/utils/route_map.dart';

enum ActiveRouteStatus { idle, loading, ready, failure }

class ActiveRouteState extends Equatable {
  final ActiveRouteStatus status;
  final String? errorMessage;

  /// Backend IDs (may be null if route is client-only).
  final String? routeId;
  final String? conversationId;

  final RouteMapModel? route;
  final int activeDay;

  /// When false, route payload stays for reopening the sheet / mini pill, but the map clears polyline + markers.
  final bool showRouteOnMap;

  const ActiveRouteState({
    required this.status,
    required this.errorMessage,
    required this.routeId,
    required this.conversationId,
    required this.route,
    required this.activeDay,
    required this.showRouteOnMap,
  });

  const ActiveRouteState.initial()
    : status = ActiveRouteStatus.idle,
      errorMessage = null,
      routeId = null,
      conversationId = null,
      route = null,
      activeDay = 1,
      showRouteOnMap = false;

  ActiveRouteState copyWith({
    ActiveRouteStatus? status,
    String? errorMessage,
    String? routeId,
    String? conversationId,
    RouteMapModel? route,
    int? activeDay,
    bool? showRouteOnMap,
    bool clearError = false,
  }) {
    return ActiveRouteState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      routeId: routeId ?? this.routeId,
      conversationId: conversationId ?? this.conversationId,
      route: route ?? this.route,
      activeDay: activeDay ?? this.activeDay,
      showRouteOnMap: showRouteOnMap ?? this.showRouteOnMap,
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    routeId,
    conversationId,
    route,
    activeDay,
    showRouteOnMap,
  ];
}
