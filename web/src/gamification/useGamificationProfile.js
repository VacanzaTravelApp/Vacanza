import { useQuery } from "@tanstack/react-query";
import { fetchMyGamification } from "./gamificationApi";

/**
 * Hook to fetch and cache the current user's gamification profile.
 * 
 * @returns {import("@tanstack/react-query").UseQueryResult}
 */
export const useGamificationProfile = () => {
    return useQuery({
        queryKey: ["gamification", "me"],
        queryFn: fetchMyGamification,
        staleTime: 5 * 60 * 1000, // 5 minutes (data remains "fresh")
        gcTime: 10 * 60 * 1000,   // 10 minutes (unused data stays in memory)
        retry: false,             // UI handles retries; 401 retries handled by http interceptor
        refetchOnWindowFocus: false, // Prevent refetching when switching tabs
    });
};
