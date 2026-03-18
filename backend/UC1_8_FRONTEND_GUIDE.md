# UC1.8 (Booking) Backend Changes — Frontend Integration Guide

Bu doküman, UC1.8 (Book Accommodation and Transportation) kapsamında Amadeus API'dan SerpApi'a geçişin frontend tarafını nasıl etkilediğini açıklar.

---

## 1. Doğal Dil ile Hotel Araması (🌟 Yeni Özellik / Breaking Change)

Backend artık otel aramalarında IATA şehir kodu (örn. `IST`, `PAR`) yerine **doğal dil** kabul ediyor.

### Ne değişti?
- `/bookings/accommodations/search` endpoint'indeki zorunlu `cityCode` alanı kaldırıldı.
- Yerine `query` alanı eklendi.

### Frontend'de yapılması gereken
- Kullanıcıya bir şehir seçtirmek (veya IATA kodunu arka planda bulmak) yerine, doğrudan bir arama çubuğu (Search Bar) sunabilirsiniz.
- Kullanıcı `"Istanbul"`, `"Hotels in Paris"`, `"Bali resorts"` hatta `"Boutique hotels near Eiffel Tower"` gibi serbest metin girebilir.

### Request Değişimi

**Eski (Amadeus):**
```json
{
  "cityCode": "PAR", 
  "checkInDate": "2025-07-01",
  "checkOutDate": "2025-07-05",
  "adults": 2
}
```

**Yeni (SerpApi):**
```json
{
  "query": "Hotels in Paris", // <-- DİKKAT: cityCode yerine query geldi
  "checkInDate": "2025-07-01",
  "checkOutDate": "2025-07-05",
  "adults": 2,
  "budget": 500.00,
  "currency": "USD",
  "sortBy": "PRICE_ASC"
}
```

---

## 2. Zenginleştirilmiş Hotel Response Verisi (✨ Yeni Alanlar)

SerpApi (Google Hotels) sayesinde frontend'e çok daha zengin veriler dönüyor.

### Ne değişti?
- `AccommodationOptionDTO` içerisine UI'da gösterilmek üzere yeni alanlar eklendi.

### Frontend'de yapılması gereken
- Otel kartlarında (Hotel Cards) bu yeni alanları gösterebilirsiniz:
  - `imageUrl`: Otel fotoğrafı
  - `hotelClass`: Yıldız sayısı (Örn: 4 veya 5)
  - `totalReviews`: Toplam değerlendirme sayısı
  - `providerName`: Veriyi sağlayan kaynak ("Google Hotels")
  - `latitude` / `longitude`: Otelin haritadaki konumu (Map entegrasyonu için)

### Örnek Response (AccommodationOptionDTO)
```json
[
  {
    "hotelId": "ChwIq...",
    "hotelName": "Hotel Le Marais",
    "providerName": "Google Hotels", // YENİ
    "description": "Chic quarters in a...", // YENİ
    "price": 185.50,
    "pricePerNight": 46.38,
    "currency": "USD",
    "rating": 4.2,
    "totalReviews": 320, // YENİ
    "hotelClass": 4, // YENİ - Otel yıldızı
    "imageUrl": "https://lh5.google...", // YENİ - Thumbnail
    "latitude": 48.8566, // YENİ
    "longitude": 2.3522, // YENİ
    "externalBookingUrl": "https://www.google.com/travel/hotels/..."
  }
]
```

---

## 3. Uçuş Araması Değişiklikleri (`POST /bookings/transportation/search`)

Uçuş tarafında (Google Flights) arama parametreleri aynı kaldı ancak dönen veri formatı ve türlerinde önemli değişiklikler var.

### 3a. Havaalanı / Şehir Adı Autocomplete (🌟 Yeni Endpoint)

Artık kullanıcıların IATA kodlarını bilmesine gerek yok! Kullanıcı yazmaya başladığında bir autocomplete/type-ahead widget sunabilirsiniz.

#### Endpoint

```
GET /bookings/airports/search?q={query}
```

| Parametre | Zorunlu | Açıklama |
|-----------|---------|----------|
| `q` | ✅ | Aranacak şehir veya havaalanı adı. **Min. 2 karakter.** |

#### Örnek Request

```
GET /bookings/airports/search?q=istanbul
```

#### Örnek Response

```json
[
  {
    "iataCode": "IST",
    "name": "Istanbul Airport",
    "city": "Istanbul",
    "country": "Turkey",
    "kgmid": null
  },
  {
    "iataCode": "SAW",
    "name": "Istanbul Sabiha Gokcen Airport",
    "city": "Istanbul",
    "country": "Turkey",
    "kgmid": null
  },
  {
    "iataCode": "/m/06mkj",
    "name": "All airports — Istanbul",
    "city": "Istanbul",
    "country": "Turkey",
    "kgmid": "/m/06mkj"
  }
]
```

> **Not:** `kgmid` değeri doluysa, bu ID şehrin tüm havaalanlarını temsil eder. `origin`/`destination` olarak `iataCode` alanını kullanın.

#### Önerilen Frontend UX Akışı

```
Kullanıcı "istan" yazmaya başlar
    → (debounce ~300ms)
    → GET /bookings/airports/search?q=istan
    → Dropdown: [Istanbul Airport (IST)] [Sabiha Gokcen (SAW)] [All Istanbul airports]
Kullanıcı "Istanbul Airport (IST)" seçer
    → origin = "IST" (field'a otomatik dolar, kullanıcı görmez)
Kullanıcı "Ara" butonuna basar
    → POST /bookings/transportation/search { "origin": "IST", ... }
```

#### Hata Durumları

| Status | Durum | Aksiyon |
|--------|-------|---------|
| 400 | `q` eksik veya < 2 karakter | Arama başlatmayın, validasyon mesajı gösterin |
| 503 | SerpApi rate limit | "Şu an arama yapılamıyor" mesajı |

---

### 3b. Ne değişti? (Flight Search — Mevcut)

1. Uçuş aramasında hala **IATA kodları** (`origin` ve `destination`) kullanılıyor. (Burada değişiklik yok).
2. `departureTime` ve `arrivalTime` tipleri `LocalDateTime`'dan **`String`**'e çevrildi.
3. UI'ı zenginleştirecek havaalanı logosu ve uçuş numarası gibi yeni alanlar eklendi.

### Frontend'de yapılması gereken
- Uçuş listesinde havayolu adının yanına `airlineLogo`'yu koyabilirsiniz.
- Tarih/Saat parse işlemlerini string üzerinden yapmalısınız (Google Flights genelde `"2025-07-01 08:30"` formatında döner).
- Bilet sınıfı (`travelClass`) ve uçuş kodu (`flightNumber`) gibi detayları UI'a ekleyebilirsiniz.

### Örnek Response (TransportOptionDTO)
```json
[
  {
    "flightId": null,
    "carrier": "Turkish Airlines",
    "airlineLogo": "https://www.gstatic.com/flights/...", // YENİ
    "flightNumber": "TK 1829", // YENİ
    "travelClass": "Economy", // YENİ
    "origin": "IST",
    "destination": "CDG",
    "departureTime": "2025-07-01 08:30", // DEĞİŞTİ (Artık String)
    "arrivalTime": "2025-07-01 11:45", // DEĞİŞTİ (Artık String)
    "duration": "3h 15m",
    "price": 320.00,
    "currency": "USD",
    "stops": 0,
    "bookingToken": "CjkSO...=", // YENİ
    "externalBookingUrl": "https://www.google.com/travel/flights?q=..."
  }
]
```

---

## 4. Olası Hatalar ve Status Kodları

Booking işlemlerinde alınabilecek standart hata kodları (Önceki UC'lerde belirlenen standart JSON formatındadır):

| Status | Anlam | Aksiyon |
|--------|-------|---------|
| 400 | Validation hatası | "query", "checkInDate" gibi zorunlu alanların eksik veya hatalı tipte gönderilmesi. |
| 401 | Unauthorized | Kullanıcı giriş yapmamış (veya token süresi dolmuş). |
| 500 | SerpApi Error | 3rd party API (SerpApi) tarafında limit aşımı (Rate Limit - 429) veya bağlantı sorunu. Kullanıcıya "Arama şu anda gerçekleştirilemiyor, lütfen daha sonra tekrar deneyin" mesajı gösterilmeli. |

*(Not: Ortamınızda SerpApi yetkilendirme anahtarının (`SERPAPI_API_KEY`) set edilmiş olduğundan emin olun, aksi takdirde backend 500 döner.)*
