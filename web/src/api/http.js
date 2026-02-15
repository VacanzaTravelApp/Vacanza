import axios from "axios";
import { auth } from "../firebase";

const http = axios.create({
  // baseURL yok -> istekler /... şeklinde gider, Vite proxy yakalar
  headers: { "Content-Type": "application/json" },
  timeout: 15000, // ✅ timeout => TIMEOUT normalize edilecek
});

http.interceptors.request.use(
  async (config) => {
    const user = auth.currentUser;

    if (user) {
      // Debug/stabilite için token'ı zorla yenile
      const token = await user.getIdToken(true);
      config.headers.Authorization = `Bearer ${token}`;
    } else {
      // İstersen debug için aç:
      // console.warn("No current user, sending request without Authorization");
    }

    return config;
  },
  (error) => Promise.reject(error)
);

http.interceptors.response.use(
  (response) => {
    // JSON beklerken Vite index.html (veya login HTML) gelirse yakala
    const contentType = response.headers?.["content-type"] || "";
    const isHtml =
      contentType.includes("text/html") ||
      (typeof response.data === "string" &&
        response.data.toLowerCase().includes("<!doctype html"));

    if (isHtml) {
      console.warn("⚠️ HTML döndü (JSON bekleniyordu). Proxy path veya auth kontrol et.");
      return Promise.reject(
        new Error("HTML response received (check Vite proxy paths and authentication).")
      );
    }

    return response;
  },
  (error) => {
    const status = error?.response?.status;

    if (status === 401 || status === 403) {
      console.warn("⚠️ Unauthorized/Forbidden (401/403). Token geçmiyor veya backend reddediyor.");
    }

    return Promise.reject(error);
  }
);

export default http;
