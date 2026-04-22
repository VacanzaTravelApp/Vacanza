import axios from "axios";
import { auth } from "../firebase";

const http = axios.create({
    baseURL: "/",
    headers: {
        "Content-Type": "application/json",
        "Accept-Language": "en"
    },
    withCredentials: true,
});

http.interceptors.request.use(
    async (config) => {
        const user = auth.currentUser;

        if (user) {
            const token = await user.getIdToken(true);
            config.headers.Authorization = `Bearer ${token}`;
        }

        return config;
    },
    (error) => Promise.reject(error)
);

http.interceptors.response.use(
    (response) => {
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
            const isEmailNotVerified =
                message.toLowerCase().includes("not verified") ||
                message.toLowerCase().includes("verify your email") ||
                message.toLowerCase().includes("email");

            if (isEmailNotVerified) {
                error.isEmailNotVerified = true;
                error.friendlyMessage = "Please verify your email address first.";
            } else {
                error.friendlyMessage = "Access denied. You don't have permission.";
            }
        } else if (status === 401) {
            error.friendlyMessage = "Session expired. Please log in again.";
        }

        return Promise.reject(error);
    }
);

export default http;
