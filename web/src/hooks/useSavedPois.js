import { useQuery } from "@tanstack/react-query";
import { fetchSavedPois } from "../api/feedbackApi";
import { useAuth } from "../context/useAuth";

export function useSavedPois() {
  const { isAuthenticated } = useAuth();
  return useQuery({
    queryKey: ["feedback", "saved-pois"],
    queryFn: fetchSavedPois,
    enabled: isAuthenticated,
    staleTime: 30_000,
  });
}
