# UC1.1 Backend Changes — Frontend Integration Guide

Bu döküman, UC1.1 (Create Account / Login) backend değişikliklerinin frontend'i nasıl etkilediğini açıklar.

---

## 1. Unverified User Blocking (⚠️ Breaking Change)

Backend artık `emailVerified = false` olan kullanıcıları **korumalı endpoint'lerden engelliyor**.

### Ne değişti?
- Firebase token'daki `emailVerified` flag'i backend tarafında kontrol ediliyor
- `emailVerified = false` ise → **403 Forbidden** döner
- Sadece şu endpoint'ler erişilebilir:
  - `GET /auth/me`
  - `GET /auth/login`
  - `POST /auth/register`
  - `POST /auth/logout`

### Frontend'de yapılması gereken
- Kullanıcı register olduktan sonra **email verify** yapana kadar korumalı sayfalara erişim engellenmelidir
- 403 response'u handle edilmeli — kullanıcıya "Email'inizi doğrulayın" mesajı gösterilmeli
- Firebase `sendEmailVerification()` çağrısı zaten yapılıyorsa sorun yok, sadece 403 handling eklenmeli

### Örnek 403 Response
```json
{
  "status": 403,
  "error": "Forbidden",
  "message": "Account not verified. Please verify your email first.",
  "path": "/users/me/profile"
}
```

---

## 2. Yeni Endpoint: POST /auth/logout

### Kullanım
```
POST /auth/logout
Authorization: Bearer <firebase_id_token>
```

### Response
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

### Not
- Bu endpoint **opsiyoneldir** — Firebase `signOut()` tek başına yeterlidir
- Backend'e logout bildirimi göndermek istiyorsanız, `signOut()` öncesinde bu endpoint'i çağırabilirsiniz
- Backend bu çağrıyı login history'ye kaydeder

---

## 3. Standart Error Response Formatı

Tüm backend hataları artık tutarlı JSON formatında dönüyor:

```json
{
  "timestamp": "2026-03-09T20:00:00Z",
  "status": 400,
  "error": "Bad Request",
  "message": "firstName and lastName are required to create profile",
  "path": "/auth/register"
}
```

### Olası HTTP Status Kodları

| Status | Anlam |
|--------|-------|
| 400 | Validation hatası (eksik/geçersiz alan) |
| 401 | Token yok veya geçersiz |
| 403 | Email verified değil |
| 404 | Kaynak bulunamadı |
| 409 | Email zaten kayıtlı (DB conflict) |

---

## 4. Mevcut Endpoint'ler (Değişiklik Yok)

Bu endpoint'ler aynen çalışmaya devam ediyor:

| Endpoint | Method | Açıklama |
|----------|--------|----------|
| `/auth/me` | GET | Kullanıcı bilgilerini döner |
| `/auth/login` | GET | `/auth/me` ile aynı |
| `/auth/register` | POST | Profil bilgilerini kaydeder |
| `/auth/logout` | POST | **Yeni** — logout kaydı |
