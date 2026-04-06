import http from "./http";

// ======================
// HOTELS
// ======================

export async function searchHotels(params) {
  try {
    const res = await http.post("/bookings/accommodations/search", params);
    return { success: true, data: res.data || [] };
  } catch (error) {
    return {
      success: false,
      error: {
        type: error.response?.status,
        message: error.friendlyMessage || "Hotel search failed."
      }
    };
  }
}

// ======================
// FLIGHTS
// ======================

export async function searchFlights(params) {
  try {
    const res = await http.post("/bookings/transportation/search", params);
    return { success: true, data: res.data || [] };
  } catch (error) {
    return {
      success: false,
      error: {
        type: error.response?.status,
        message: error.friendlyMessage || "Flight search failed."
      }
    };
  }
}

// ======================
// AIRPORTS (AUTOCOMPLETE)
// ======================

export async function searchAirports(query) {
  try {
    const res = await http.get(`/bookings/airports/search?q=${encodeURIComponent(query)}`);
    return res.data || [];
  } catch (error) {
    console.error("Airport search error:", error);
    return [];
  }
}

// ======================
// DESTINATIONS (HOTELS AUTOCOMPLETE)
// ======================
export async function searchDestinations(query) {
  try {
    const res = await http.get(`/bookings/destinations/search?q=${encodeURIComponent(query)}`);
    return res.data || [];
  } catch (error) {
    console.error("Hotel destination search error:", error);
    return [];
  }
}

