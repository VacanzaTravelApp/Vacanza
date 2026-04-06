// src/api/userApi.js veya authApi.js
import http from "./http";

export const authApi = {
  // Login ve app açılışında session restore için (Senin AuthController'ındaki @GetMapping("/login"))
  login: () => http.get("/auth/login"),

  // Register sonrası profil oluşturma/senkronizasyon için (UserInfoController'daki @PostMapping("/auth/register"))
  register: (userData) => http.post("/auth/register", userData),

  // Session kontrolü için
  me: () => http.get("/auth/me"),
};

export const userApi = {
  // Profiles
  getProfile: () => http.get("/users/me/profile"),
  updateProfile: (body) => http.put("/users/me/profile", body),

  // Profile Photo (New)
  uploadProfilePhoto: (file) => {
    const formData = new FormData();
    formData.append("file", file);
    // ⚠️ DO NOT set Content-Type header manually for multipart/form-data, 
    // axios/browser will handle it with the correct boundary.
    return http.post("/users/me/profile/photo", formData);
  },
  getProfilePhoto: () => http.get("/users/me/profile/photo", { responseType: "blob" }),
  deleteProfilePhoto: () => http.delete("/users/me/profile/photo"),

  // Preferences
  getPreferences: () => http.get("/users/me/preferences"),
  updatePreferences: (body) => http.put("/users/me/preferences", body),

  // Check-ins & Stats
  getCheckins: () => http.get("/users/me/checkins"),
  getStats: () => http.get("/users/me/stats"),
  autoCheckIn: (coords) => http.post("/users/me/checkins/auto", coords),
};