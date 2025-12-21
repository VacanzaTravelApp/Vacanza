import axios from "axios";
import { auth } from "../firebase";

const http = axios.create({
  baseURL: import.meta.env.VITE_BACKEND_URL, // örn: http://localhost:8080
  headers: { "Content-Type": "application/json" },
});

http.interceptors.request.use(async (config) => {
  const user = auth.currentUser;
  if (user) {
    const token = await user.getIdToken();
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export default http;
