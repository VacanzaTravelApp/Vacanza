import http from './http.js';

export const authApi = {
  login: () => http.get("/auth/login"),
  me: () => http.get("/auth/me"),
  register: (body) => http.post("/auth/register", body),
};
