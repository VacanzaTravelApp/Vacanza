import http from "./http";

export const authApi = {
    login: () => http.get("/auth/login"),
    register: (userData) => http.post("/auth/register", userData),
    me: () => http.get("/auth/me"),
};

export const userApi = {
    getProfile: () => http.get("/users/me/profile"),
    updateProfile: (body) => http.put("/users/me/profile", body),
    getAllUsers: () => http.get("/admin/users"),
    getPreferences: () => http.get("/users/me/preferences"),
    updatePreferences: (body) => http.put("/users/me/preferences", body),
    getCheckins: () => http.get("/users/me/checkins"),
    getStats: () => http.get("/users/me/stats"),
    autoCheckIn: (coords) => http.post("/users/me/checkins/auto", coords),
    promoteUserToAdmin: (email) => http.patch(`/admin/users/promote`, null, { params: { email } }),
};
