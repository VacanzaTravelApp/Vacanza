# Vacanza Admin Panel - Backend Implementation Guide

Bu döküman, Admin Web panelinin (React/Vite) ihtiyaç duyduğu backend servislerini ve veri yapılarını açıklamaktadır.

## 🟢 1. Genel Gereksinimler
- **Base Path:** `/admin`
- **Security:** Tüm endpointler `Role.ADMIN` kontrolü altında olmalıdır.
- **Authentication:** Firebase UID token'ı Header'da `Bearer` olarak gelir. Backend, Firebase UID üzerinden veritabanındaki `User` tablosuna bakıp `User.role == ADMIN` kontrolü yapmalıdır.
- **Dönüş Tipi:** JSON (standard REST API)

---

## 📊 2. UC2.1: System & API Monitoring
Yönetici panelinde sistemin genel sağlığını ve API performansını izlemek için kullanılır.

### Endpoint: `GET /admin/monitoring`
Bu endpoint aşağıdaki verileri dönmelidir:
- **System Health:** Genel sistem durumu (0.0 - 1.0 arası bir skor).
- **Service Status:** Aşağıdaki servislerin anlık durumu, latency (gecikme) ve yük (load) bilgisi.
    - Auth Service
    - Gamification Engine
    - POI / Maps API
    - User Service
    - Booking System
    - AI Recommendation API
- **System Logs:** Son n adet (örn: 50) sistem aktivite logu.

### Veri Yapısı (SystemMonitoringDTO):
```java
public class SystemMonitoringDTO {
    private double systemHealth;
    private List<ServiceStatus> services;
    private List<LogEntry> logs;
}
```

---

## 📈 3. UC2.2: Generate Analytics Report
Kullanıcı büyümesi, popüler noktalar ve demografik verileri raporlamak için kullanılır.

### Endpoint: `GET /admin/analytics`
Opsiyonel query parametreleri: `startDate`, `endDate`.

### Dönüş Verileri:
- **Total Users:** Toplam kayıtlı kullanıcı sayısı.
- **Active Sessions:** Anlık aktif kullanıcı/oturum sayısı.
- **Total Check-ins:** Tüm zamanların check-in sayısı.
- **Growth Trends:** Aylık veya haftalık bazda yeni kullanıcı kayıt sayıları.
- **Category Distribution:** POI kategorilerine göre check-in dağılımı (History, Nature, Culture, etc.).
- **Top POIs:** En çok ziyaret edilen ilk 10 yerin listesi (İsim, Kategori, Ziyaret Sayısı).

### Veri Yapısı (AdminAnalyticsDTO):
```java
public class AdminAnalyticsDTO {
    private long totalUsers;
    private long totalCheckins;
    private List<Metric> growthTrends;
    private List<CategoryMetric> categoryDist;
}
```

---

## 👥 4. Kullanıcı Yönetimi (Mevcut Endpointler)
Panel halihazırda aşağıdaki endpointi kullanmaktadır, Admin için erişimin açık olduğundan emin olunmalıdır:
- `GET /user/get-all-user`: Tüm kullanıcı listesini döner.

---

## 🛠️ Repository Katmanında Gereken Sorgular (Öneri)

**CheckInRepository:**
```java
// Kategori dağılımı için
@Query("SELECT c.pointOfInterest.category, COUNT(c) FROM CheckIn c GROUP BY c.pointOfInterest.category")
List<Object[]> findCategoryDistribution();

// En popüler POI'ler
@Query("SELECT c.pointOfInterest.name, COUNT(c) FROM CheckIn c GROUP BY c.pointOfInterest.name ORDER BY COUNT(c) DESC")
List<Object[]> findTopPois();
```

**UserRepository:**
```java
// Yeni kullanıcı trendi (X tarihinden sonra)
long countByCreatedAtAfter(Instant date);
```
