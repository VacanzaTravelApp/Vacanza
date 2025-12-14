/// Mapbox ile ilgili tüm config değerleri burada tutulur.
///
/// ⚠️ ŞİMDİLİK:
/// - Access token hardcoded.
/// - Prod ortamda .env veya platform config'e taşınabilir.
class MapboxConfig {
  /// Mapbox public access token
  ///
  /// NOT:
  /// - Bu token PUBLIC token'dır.
  /// - Mobil uygulama içinde bulunması normaldir.
  /// - Secret token ile karıştırma.
  static const String accessToken =
      'pk.eyJ1IjoicHJpeGltYSIsImEiOiJjbTlkMDdhdHcwbW92Mmtxd2swbXMyNTd0In0.c4zFX1Yh1mP4ioGHYiJrfQ ';
}