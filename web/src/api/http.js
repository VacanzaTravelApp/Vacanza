import axios from "axios";
import { auth } from "../firebase";

const http = axios.create({
  // Using / instead of full URL to use Vite Proxy.
  // This prevents CORS errors.
  baseURL: "/",
  headers: { "Content-Type": "application/json" },
  withCredentials: true,
});

http.interceptors.request.use(
  async (config) => {
    const user = auth.currentUser;

    if (user) {
      // Force token refresh for stability/debug
      const token = await user.getIdToken(true);
      config.headers.Authorization = `Bearer ${token}`;
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
      console.warn("HTML returned (JSON expected). Check Proxy path or auth.");
      return Promise.reject(
        new Error("HTML response received (check Vite proxy paths and authentication).")
      );
    }

    return response;
  },
  (error) => {
    const status = error?.response?.status;
    const message = error?.response?.data?.message || "";

    if (status === 403) {
      // Email verification check
      const isEmailNotVerified =
        message.toLowerCase().includes("not verified") ||
        message.toLowerCase().includes("verify your email") ||
        message.toLowerCase().includes("email");

      if (isEmailNotVerified) {
        console.warn("403: Email not verified. Backend requires email verification.");
        // Attach a custom flag so components can detect this specific error
        error.isEmailNotVerified = true;
        error.friendlyMessage = "Please verify your email address first. Check your inbox for the verification link.";
      } else {
        console.warn("403 Forbidden. Access denied.");
        error.friendlyMessage = "Access denied. You don't have permission for this action.";
      }
    } else if (status === 401) {
      console.warn("401 Unauthorized. Token invalid or expired.");
      error.friendlyMessage = "Session expired. Please log in again.";
    } else if (status === 400) {
      error.friendlyMessage = message || "Invalid request. Please check your input.";
    } else if (status === 409) {
      error.friendlyMessage = message || "This email is already registered.";
    }

    return Promise.reject(error);
  }
);

export default http;
