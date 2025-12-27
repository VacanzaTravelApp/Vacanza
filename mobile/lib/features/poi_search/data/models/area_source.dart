/// POI search alanının nereden geldiğini belirtir.
///
/// - viewport: kullanıcı çizim yapmadı, ekranın görünen alanı ile arama
/// - userSelection: kullanıcı rectangle/polygon çizdi, o alan ile arama
enum AreaSource {
  viewport,
  userSelection,
}