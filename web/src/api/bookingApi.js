import axios from "axios";
import { auth } from "../firebase"; // senin verdiğin dosya

const API_BASE_URL = import.meta.env.VITE_BACKEND_BASE_URL;

// Axios instance
const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    "Content-Type": "application/json",
  },
  timeout: 15000,
});

// 🔥 Firebase token interceptor
api.interceptors.request.use(async (config) => {
  const user = auth.currentUser;

  if (user) {
    const token = await user.getIdToken();
    config.headers.Authorization = `Bearer ${token}`;
  }

  return config;
});

// Error mapping
function mapError(error) {
  if (!error.response) {
    return {
      type: "NETWORK_ERROR",
      message: "Network error. Please check your connection.",
    };
  }

  const status = error.response.status;

  if (status === 400) {
    return {
      type: "BAD_REQUEST",
      message: error.response.data?.message || "Invalid request.",
    };
  }

  if (status === 401) {
    return {
      type: "UNAUTHORIZED",
      message: "Session expired. Please login again.",
    };
  }

  if (status === 502) {
    return {
      type: "PROVIDER_ERROR",
      message: "Search service temporarily unavailable.",
    };
  }

  return {
    type: "UNKNOWN_ERROR",
    message: "Something went wrong.",
  };
}

// ======================
// HOTELS
// ======================

export async function searchHotels(body) {
  try {
    const res = await api.post(
      "/bookings/accommodations/search",
      body
    );

    return { success: true, data: res.data || [] };
  } catch (error) {
    return { success: false, error: mapError(error) };
  }
}

// ======================
// FLIGHTS
// ======================

export async function searchFlights(body) {
  try {
    const res = await api.post(
      "/bookings/transportation/search",
      body
    );

    return { success: true, data: res.data || [] };
  } catch (error) {
    return { success: false, error: mapError(error) };
  }
}