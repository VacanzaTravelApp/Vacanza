/// Repository-level exception (Bloc/UI sadece bunu görür)
class PoiSearchRepositoryException implements Exception {
  final String code;
  final String message;

  const PoiSearchRepositoryException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'PoiSearchRepositoryException($code): $message';
}

/// Backend error formatı "CODE: message" ise parse eder.
class CodeMessage {
  final String code;
  final String message;
  const CodeMessage(this.code, this.message);
}

CodeMessage parseCodeMessage(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return const CodeMessage('UNKNOWN_ERROR', 'Empty error');

  final i = s.indexOf(':');
  if (i <= 0) return CodeMessage('UNKNOWN_ERROR', s);

  final code = s.substring(0, i).trim();
  final msg = s.substring(i + 1).trim();
  if (code.isEmpty) return CodeMessage('UNKNOWN_ERROR', s);
  return CodeMessage(code, msg.isEmpty ? s : msg);
}