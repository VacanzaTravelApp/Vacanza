import { useQuery } from "@tanstack/react-query";
import { fetchMyGamification } from "./gamificationApi";
import { useEffect, useState } from "react";
import { auth } from "../firebase";

export function useGamificationProfile() {
  const [userReady, setUserReady] = useState(false);

  useEffect(() => {
    const unsub = auth.onAuthStateChanged((user) => {
      if (user) {
        setUserReady(true);
      }
    });

    return () => unsub();
  }, []);

  return useQuery({
    queryKey: ["gamification", "profile"],
    queryFn: fetchMyGamification,
    enabled: userReady,   // ⭐ user hazır olana kadar request atılmaz
    staleTime: 1000 * 60 * 5,
    retry: 1,
  });
}
