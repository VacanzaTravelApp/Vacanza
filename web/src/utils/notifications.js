const TURKISH_CHAR_RE = /[çğıöşüÇĞİÖŞÜ]/;
const TURKISH_WORD_RE = /\b(ve|veya|ile|için|lütfen|güncellendi|başar|hata|uyarı|geçersiz|bulunamadı|yüklenemedi|kaydedilemedi|silinemedi|tekrar|deneyin|rota|gün|yer)\b/i;

function looksLocalized(message) {
  if (!message) return false;
  return TURKISH_CHAR_RE.test(message) || TURKISH_WORD_RE.test(message);
}

export function pickEnglishNotificationMessage(candidate, fallback) {
  const normalizedCandidate = typeof candidate === "string" ? candidate.trim() : "";
  const normalizedFallback = typeof fallback === "string" ? fallback.trim() : "";

  if (!normalizedCandidate) return normalizedFallback;
  if (looksLocalized(normalizedCandidate)) return normalizedFallback || normalizedCandidate;
  return normalizedCandidate;
}

export function getErrorNotificationMessage(error, fallback) {
  return pickEnglishNotificationMessage(
    error?.friendlyMessage || error?.response?.data?.message || error?.message,
    fallback
  );
}
