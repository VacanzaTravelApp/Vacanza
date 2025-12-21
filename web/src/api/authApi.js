import { http } from "./http";

export const authApi = {
  login: () => http.get("/auth/login"),
  me: () => http.get("/auth/me"),
  register: (dto) => http.post("/auth/register", dto),
};
