/// Mapbox **public** access token (`pk.…`).
///
/// Bu dosyayı yerelde doldurun; gerçek anahtarı paylaşılan branch’lere commit etmeyin.
/// Boş bırakılırsa harita başlatılamaz.
///
/// iOS: [MBXAccessToken] in `ios/Runner/Info.plist` must be the **same** `pk.` string
/// as here (Mapbox Maps SDK reads the plist; Dart calls [MapboxOptions.setAccessToken]).
const String kMapboxAccessToken = 'pk.eyJ1IjoicHJpeGltYSIsImEiOiJjbTlkMDdhdHcwbW92Mmtxd2swbXMyNTd0In0.c4zFX1Yh1mP4ioGHYiJrfQ';
