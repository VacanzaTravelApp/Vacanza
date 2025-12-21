import axios from "axios";
import { auth } from "../firebase";

const http = axios.create({
  // .env içindeki URL'i kullanır
  baseURL: import.meta.env.VITE_BACKEND_URL || import.meta.env.VITE_API_BASE_URL,
  headers: { "Content-Type": "application/json" },
});

// Her istekte Firebase Token'ını Header'a ekler
http.interceptors.request.use(async (config) => {
  const user = auth.currentUser;
  if (user) {
    const token = await user.getIdToken();
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// YANIT KONTROLÜ: HTML yanıtlarını burada yakalıyoruz
http.interceptors.response.use(
  (response) => {
    // Eğer backend yanlışlıkla HTML hata sayfası dönerse, bunu durdur
    if (typeof response.data === 'string' && response.data.includes("<!doctype html>")) {
      console.warn("⚠️ Backend returned HTML instead of JSON. Check Spring Security.");
      return Promise.reject(new Error("Server Configuration Error: HTML response received."));
    }
    return response;
  },
  (error) => {
    return Promise.reject(error);
  }
);

export default http;