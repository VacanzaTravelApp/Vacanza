import 'package:flutter/material.dart';

/// Ana harita ekranımızın şimdilik mock / placeholder versiyonu.
///
/// Gerçek uygulamada burada:
///  - Google Maps / Mapbox widget'ı
///  - Üstte search bar
///  - Altta bottom navigation / trip cards
/// gibi bileşenler olacak.
///
/// Şu an VACANZA-82 kapsamında amacımız:
///  - Register başarıyla tamamlandığında
///    kullanıcıyı "uygulamanın ana ekranı" hissi veren
///    bir sayfaya yönlendirmek.
///  - Bu yüzden sade, ama net bir placeholder bırakıyoruz.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Uygulamanın ana rengiyle uyumlu basit bir AppBar.
      appBar: AppBar(
        title: const Text('Vacanza Map'),
        centerTitle: true,
      ),

      // Body kısmında şimdilik sadece mock bir "map" alanı var.
      body: Column(
        children: [
          // Üstte kısa bir info alanı bırakıyoruz.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Mock Map Screen – burada gerçek harita bileşeni olacak.',
              style: TextStyle(fontSize: 14),
            ),
          ),

          // Haritayı temsil eden büyük bir kutu.
          // İleride buraya GoogleMap / Mapbox widget'ı gelecek.
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.blueGrey.shade100,
                border: Border.all(
                  color: Colors.blueGrey.shade300,
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Text(
                  '🗺️ MAP PLACEHOLDER\n\n'
                      'Buraya gerçek harita bileşeni eklenecek.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}