# UC1.8 (Booking) Backend Changes — Frontend Integration Guide

Bu doküman, UC1.8 (Book Accommodation and Transportation) kapsamında Amadeus API'dan SerpApi'a geçişin frontend tarafını nasıl etkilediğini ve Flight Search entegrasyonunda dikkat edilmesi gerekenleri açıklar.

---

## 1. Flight Search (Uçuş Araması) ve Autocomplete Entegrasyonu (Kritik Değişiklik)

Kullanıcıların uçuş ararken IATA kodlarını (örn. `IST`, `SAW`, `ESB`) ezbere bilmesi beklenmez. Frontend'in mutlaka kullanıcıya bir "Autocomplete / Dropdown" menüsü sunması ve seçilen şehrin **yalnızca IATA kodunu** uçuş arama isteğine göndermesi gerekmektedir. 

"ankara" gibi IATA kodu olmayan uzun dize veya şehir isimleri doğrudan uçuş aramasına (`POST /bookings/transportation/search`) gönderilirse servis **400 Bad Request** dönecektir!

### 1a. Havaalanı / Şehir Adı Autocomplete Endpoint'i

Kullanıcı yazmaya başladığında bu endpoint çağrılmalı ve dönen sonuçlar dropdown içerisinde kullanıcıya gösterilmelidir.

#### Endpoint Oluşturma

```http
GET /bookings/airports/search?q={query}
```

| Parametre | Zorunlu | Açıklama |
|-----------|---------|----------|
| `q`       | ✅       | Aranacak şehir veya havaalanı adı. **Min. 2 karakter.** (Örn: "ankara", "istan") |

#### Örnek Response (GET /bookings/airports/search?q=ankara)

```json
[
  {
    "iataCode": "ESB",
    "name": "Ankara Esenboğa Airport",
    "city": "Ankara",
    "country": "Turkey",
    "kgmid": "/m/01y63"
  }
]
```

### 1b. Uçuş Araması Endpoint'inin Kullanımı (`POST /bookings/transportation/search`)

Kullanıcı dropdown üzerinden "Ankara Esenboğa Airport" seçeneğine tıkladığında, frontend uçuş arama isteğini başlatırken arka planda **şehrin adını ("ankara") DEĞİL, yukarıdaki servisten dönen `iataCode` değerini ("ESB")** `origin` (veya `destination`) olarak göndermelidir.

#### Beklenen Örnek Body:

```json
{
  "origin": "ESB",       // <-- DİKKAT: Sadece 3 harfli IATA kodları kabul edilir
  "destination": "PAR",  // <-- DİKKAT: Sadece 3 harfli IATA kodları kabul edilir
  "departureDate": "2025-07-01",
  "returnDate": "2025-07-05", // (Opsiyonel, tek yön ise null gönderin)
  "adults": 1,
  "budget": 300.00,
  "currency": "USD",
  "sortBy": "PRICE_ASC"
}
```

#### Neden Önemli? (Yeni 400 Validation Hatası)
Backend tarafına `origin` ve `destination` alanları için **3 harf IATA kodu (Regex: `^[A-Z]{3}$`) validasyonu eklenmiştir**. Eğer autocomplete kullanmadan "Ankara" gibi bir değer atılırsa, API 502 hatası yerine frontend'i doğru yönlendirebilmek adına aşağıdaki gibi **400 Bad Request** validasyon hatası fırlatacordur:

```json
{
  "error": "Bad Request",
  "message": "Origin must be a valid 3-letter IATA code"
}
```

#### Önerilen Frontend UX Akışı (ÖZET)

1. Kullanıcı formda gidiş yönüne "anka" yazar.
2. Frontend (debounce ~300ms) ile `GET /bookings/airports/search?q=anka` atar.
3. Ekranda "Ankara Esenboğa Airport (ESB)" seçeneği belirir.
4. Kullanıcı seçeneğe tıklar (State'de `origin="ESB"` olarak saklanır, UI'da "Ankara" vs. gösterilebilir).
5. "Ara" butonuna basıldığında `POST /bookings/transportation/search` bodysinde `"origin": "ESB"` gönderilir.

---

## 2. Doğal Dil ile Hotel Araması

Backend artık otel aramalarında IATA şehir kodu (örn. `IST`, `PAR`) yerine **doğal dil** araması kabul ediyor.

### Ne değişti?
- `/bookings/accommodations/search` endpoint'indeki zorunlu `cityCode` alanı kaldırıldı.
- Yerine `query` alanı eklendi ("Paris", "Hotels in Barcelona" gibi serbest metin alır).

### Request Değişimi

```json
{
  "query": "Boutique hotels in Paris", 
  "checkInDate": "2025-07-01",
  "checkOutDate": "2025-07-05",
  "adults": 2,
  "budget": 500.00,
  "currency": "USD",
  "sortBy": "RATING_DESC"
}
```

---

## 3. Zenginleştirilmiş Veri Yanıtları (Hotels & Flights)

### 3a. Hotel Alanları
- Otel kartlarında (Hotel Cards) bu yeni alanları gösterebilirsiniz:
  - `imageUrl`: Otel fotoğrafı
  - `hotelClass`: Yıldız sayısı (Örn: 4 veya 5)
  - `totalReviews`: Toplam değerlendirme sayısı
  - `providerName`: Veriyi sağlayan kaynak ("Google Hotels")
  - `latitude` / `longitude`: Otelin haritadaki konumu (Map entegrasyonu için)

### 3b. Flight Alanları
- Uçuş listesinde havayolu adının yanına `airlineLogo`'yu koyarak zenginleştirebilirsiniz.
- Tarih/Saat parse işlemlerini string üzerinden yapmalısınız (Google Flights genelde `"2025-07-01 08:30"` formatında string döner, LocalDateTime DEĞİLDİR).
- Bilet sınıfı (`travelClass`) ve uçuş kodu (`flightNumber`) gibi detayları UI'a ekleyebilirsiniz.

---

## 4. Olası Hatalar ve Status Kodları

Booking işlemlerinde frontend'in yakalaması gereken hata kodları:

| Status | Anlam | Aksiyon / Çözüm |
|--------|-------|---------|
| **400** | Validation Hatası | "query" gibi zorunlu alanların eksik olması veya **IATA kodu gereken yere uzun şehir adı ("ankara") gönderilmesi** (`Origin must be a valid 3-letter IATA code`). |
| **401** | Unauthorized | Hedef endpoint korumalıdır, kullanıcının bearer tokenı eklenmemiştir/süresi dolmuştur. |
| **500** | SerpApi Error | Dış API tarafında geçici bir arıza. "Arama şu anda gerçekleştirilemiyor, lütfen daha sonra tekrar deneyin" mesajı gösterilmelidir. |
| **502** | Bad Gateway | SerpApi'dan geçerli bir yanıt alınamadı. (Örn: Geçersiz parametreler gönderildi ve 400 Validasyonlarına takılmadı) |
| **503** | Rate Limit / Kota | SerpApi istek kotası aşıldı. Kullanıcıya "Şu an servis meşgul" denmelidir. |
