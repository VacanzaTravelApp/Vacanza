import { useQuery } from "@tanstack/react-query";
import http from "../api/http";
import { useAuth } from "../context/useAuth";

/**
 * Cached GET /api/feedback/affinity — POI and category score maps for thumb UI hydration.
 */
export function useFeedbackAffinity() {
  const { isAuthenticated } = useAuth();
  return useQuery({
    queryKey: ["feedback", "affinity"],
    queryFn: async () => {
      const { data } = await http.get("/api/feedback/affinity");
      return data;
    },
    enabled: isAuthenticated,
    staleTime: 30_000,
  });
}
