import 'package:dio/dio.dart';

import '../../domain/saved_poi.dart';

/// `/api/feedback` — same contract as web [feedbackApi.js].
class FeedbackApiClient {
  final Dio _dio;

  FeedbackApiClient(this._dio);

  Future<Map<String, Map<String, double>>> fetchAffinity() async {
    final res = await _dio.get<dynamic>('/api/feedback/affinity');
    final data = res.data;
    if (data is! Map) {
      throw const FormatException('Invalid affinity response');
    }
    return _parseAffinityMap(data);
  }

  Future<void> postPoiFeedbackEvent(Map<String, dynamic> body) async {
    await _dio.post<void>('/api/feedback/poi-events', data: body);
  }

  /// GET `/api/feedback/saved-pois` — liked POIs with display info.
  Future<List<SavedPoi>> fetchSavedPois() async {
    final res = await _dio.get<dynamic>('/api/feedback/saved-pois');
    final data = res.data;
    if (data is! List) {
      throw const FormatException('Invalid saved-pois response');
    }
    return data.map((e) => SavedPoi.fromJson(e)).toList(growable: false);
  }
}

Map<String, Map<String, double>> _parseAffinityMap(Map<dynamic, dynamic> raw) {
  Map<String, double> scores(dynamic v) {
    if (v is! Map) return {};
    return v.map(
      (k, val) => MapEntry(
        k.toString(),
        (val is num) ? val.toDouble() : double.tryParse(val.toString()) ?? 0.0,
      ),
    );
  }

  final poi = scores(raw['poiScores']);
  final cat = scores(raw['categoryScores']);
  return {'poiScores': poi, 'categoryScores': cat};
}
