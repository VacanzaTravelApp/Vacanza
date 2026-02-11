import axios from "axios";
import { auth } from "../firebase";

const http = axios.create({
  baseURL: import.meta.env.VITE_BACKEND_URL || import.meta.env.VITE_API_BASE_URL,
  headers: { "Content-Type": "application/json" },
  timeout: 15000, // ✅ timeout => TIMEOUT normalize edilecek
});

const ERROR_CODES = {
  UNAUTHENTICATED: "UNAUTHENTICATED",
  UNAUTHORIZED: "UNAUTHORIZED",
  TIMEOUT: "TIMEOUT",
  NETWORK: "NETWORK",
  SERVER_HTML: "SERVER_HTML",
};

function makeError(code, message, meta = {}) {
  const err = new Error(message);
  err.code = code;
  err.meta = meta;
  return err;
}

async function getFirebaseIdToken(forceRefresh = false) {
  const user = auth.currentUser;
  if (!user) return null;
  return user.getIdToken(forceRefresh);
}

// ✅ REQUEST INTERCEPTOR: { auth: true } ise token zorunlu
http.interceptors.request.use(
  async (config) => {
    const needsAuth = config?.auth === true; // axios config’e custom field koyabiliriz

    if (!needsAuth) return config;

    const token = await getFirebaseIdToken(false);

    if (!token) {
      // ✅ “strictly reject”: request hiç gitmesin
      return Promise.reject(
        makeError(ERROR_CODES.UNAUTHENTICATED, "User not signed in.")
      );
    }

    config.headers = config.headers || {};
    config.headers.Authorization = `Bearer ${token}`;

    // retry flag reset (each request starts clean)
    config._retry = false;

    return config;
  },
  (error) => Promise.reject(error)
);

// ✅ RESPONSE INTERCEPTOR: HTML guard + normalize + 401 refresh retry
http.interceptors.response.use(
  (response) => {
    // HTML hata sayfası guard
    if (
      typeof response.data === "string" &&
      response.data.toLowerCase().includes("<!doctype html")
    ) {
      console.warn("⚠️ Backend returned HTML instead of JSON. Check backend config.");
      return Promise.reject(
        makeError(
          ERROR_CODES.SERVER_HTML,
          "Server Configuration Error: HTML response received."
        )
      );
    }
    return response;
  },
  async (error) => {
    // Eğer bizim custom error’ımızsa (UNAUTHENTICATED vb.) direkt geçir
    if (error?.code && Object.values(ERROR_CODES).includes(error.code)) {
      return Promise.reject(error);
    }

    const config = error?.config || {};
    const needsAuth = config?.auth === true;

    // Timeout
    if (error?.code === "ECONNABORTED") {
      return Promise.reject(makeError(ERROR_CODES.TIMEOUT, "Request timed out."));
    }

    // Network (response yok)
    if (!error?.response) {
      return Promise.reject(makeError(ERROR_CODES.NETWORK, "Network error."));
    }

    const status = error.response.status;

    // ✅ 401/403 → 1 kez token refresh + retry (auth requests only)
    if (needsAuth && (status === 401 || status === 403) && !config._retry) {
      config._retry = true;

      const refreshed = await getFirebaseIdToken(true);
      if (!refreshed) {
        return Promise.reject(
          makeError(ERROR_CODES.UNAUTHENTICATED, "User not signed in.")
        );
      }

      config.headers = config.headers || {};
      config.headers.Authorization = `Bearer ${refreshed}`;

      return http(config); // retry original request
    }

    // Normalize unauthorized
    if (status === 401 || status === 403) {
      return Promise.reject(makeError(ERROR_CODES.UNAUTHORIZED, "Unauthorized.", { status }));
    }

    // Diğer HTTP hataları → NETWORK/SERVER gibi tek code altında tutmak istersen burayı genişletebilirsin
    return Promise.reject(
      makeError(ERROR_CODES.NETWORK, "Request failed.", { status, data: error.response.data })
    );
  }
);

export default http;
export { ERROR_CODES };
