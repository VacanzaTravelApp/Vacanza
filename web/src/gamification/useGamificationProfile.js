import { useState, useEffect } from "react";
import { useQuery } from "@tanstack/react-query";
import { fetchMyGamification } from "./gamificationApi";
import { auth } from "../firebase"; // Dosya yoluna göre ayarla

export function useGamificationProfile() {
  const [currentUser, setCurrentUser] = useState(null);
  const [authLoaded, setAuthLoaded] = useState(false);

  useEffect(() => {
    // Firebase auth durumunu dinle
    const unsub = auth.onAuthStateChanged((user) => {
      setCurrentUser(user);
      setAuthLoaded(true);
    });
    return () => unsub();
  }, []);

  return useQuery({
    queryKey: ["gamification", "profile", currentUser?.uid],
    queryFn: fetchMyGamification,
    // Sadece auth kontrolü bittiyse VE kullanıcı varsa API'ye git
    enabled: authLoaded && !!currentUser, 
    staleTime: 1000 * 60 * 5,
    retry: 1,
  });
}