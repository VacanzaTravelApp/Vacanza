// src/api/userApi.js veya authApi.js
import http from "./http";

export const authApi = {
  // Login ve app açılışında session restore için (Senin AuthController'ındaki @GetMapping("/login"))
  login: () => http.get("/auth/login", { timeout: 8000 }),

  // Register sonrası profil oluşturma/senkronizasyon için (UserInfoController'daki @PostMapping("/auth/register"))
  register: (userData) => http.post("/auth/register", userData),

  // Session kontrolü için
  me: () => http.get("/auth/me"),
};

export const userApi = {
  // Profiles
  getProfile: () => http.get("/users/me/profile"),
  updateProfile: (body) => http.put("/users/me/profile", body),

  // Preferences
  getPreferences: () => http.get("/users/me/preferences"),
  updatePreferences: (body) => http.put("/users/me/preferences", body),

  // Check-ins & Stats
  getCheckins: () => http.get("/users/me/checkins"),
  getStats: () => http.get("/users/me/stats"),
  autoCheckIn: (coords) => http.post("/users/me/checkins/auto", coords),

  // Photos
  getPhoto: () => http.get("/users/me/profile/photo", { responseType: "blob" }),
  uploadPhoto: (formData) => http.post("/users/me/profile/photo", formData),
  deletePhoto: () => http.delete("/users/me/profile/photo"),
};