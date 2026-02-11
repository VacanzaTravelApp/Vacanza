import http from "../api/http";

/**
 * Fetches the current user's gamification profile.
 * Requires Firebase ID token (handled by http interceptor).
 * 
 * @returns {Promise<Object>} Gamification profile data
 */
export const fetchMyGamification = async () => {
    const { data } = await http.get("/users/me/gamification", { auth: true });

    if (!data) {
        throw new Error("Invalid gamification response.");
    }

    return data;
};

