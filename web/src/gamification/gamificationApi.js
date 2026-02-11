import http from "../api/http";

const USE_MOCK = import.meta.env.VITE_USE_GAMIFICATION_MOCK === "true";

/**
 * Fetches the current user's gamification profile.
 * Requires Firebase ID token (handled by http interceptor).
 *
 * @returns {Promise<Object>} Gamification profile data
 */
export const fetchMyGamification = async () => {
    // ✅ DEV MOCK (env ile kontrol)
    if (USE_MOCK) {
        return new Promise((resolve) => {
            setTimeout(() => {
                resolve({
                    roleText: "Urban Adventurer",
                    levelText: "Level 12",
                    // progress için: xp / nextLevelXp -> yüzde hesaplanır
                    params: { xp: 3240, nextLevelXp: 5000 },

                    // UI’daki 3 stat: Places / Badges / Days
                    stats: [
                        { label: "Places", value: 24 },
                        { label: "Badges", value: 18 },
                        { label: "Days", value: 156 },
                    ],

                    badgesSectionTitle: "Achievement Badges",

                    // Badge’lere unlock ekledim (locked olanlar soluk görünsün diye)
                    badges: [
                        { id: 1, title: "Explorer", iconKey: "trophy", color: "orange", unlocked: true },
                        { id: 2, title: "Foodie", iconKey: "star", color: "coral", unlocked: true },
                        { id: 3, title: "Navigator", iconKey: "map", color: "blue", unlocked: true },
                        { id: 4, title: "Photographer", iconKey: "camera", color: "green", unlocked: true },
                        { id: 5, title: "Culture", iconKey: "medal", color: "pink", unlocked: false },
                        { id: 6, title: "Speed", iconKey: "bolt", color: "purple", unlocked: false },
                    ],
                });
            }, 600);
        });
    }

    // ✅ REAL BACKEND
    const { data } = await http.get("/users/me/gamification", { auth: true });

    if (!data) {
        throw new Error("Invalid gamification response.");
    }

    return data;
};
