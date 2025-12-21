// src/api/userApi.js veya authApi.js
import { http } from "./http";

export const authApi = {
  // Login ve app açılışında session restore için (Senin AuthController'ındaki @GetMapping("/login"))
  login: () => http.get("/auth/login"),
  
  // Register sonrası profil oluşturma/senkronizasyon için (UserInfoController'daki @PostMapping("/auth/register"))
  register: (userData) => http.post("/auth/register", userData),
  
  // Session kontrolü için
  me: () => http.get("/auth/me"),
};

export const userApi = {
  getProfile: () => http.get("/user/profile"),
  updateProfile: (body) => http.put("/user/profile", body),
};