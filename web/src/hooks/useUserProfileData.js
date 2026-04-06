import { useQuery } from "@tanstack/react-query";
import { userApi } from "../api/userApi";
import { auth } from "../firebase";
import { useEffect, useState } from "react";

function useAuthReady() {
    const [userReady, setUserReady] = useState(false);
    useEffect(() => {
        const unsub = auth.onAuthStateChanged((user) => {
            if (user) setUserReady(true);
        });
        return () => unsub();
    }, []);
    return userReady;
}

export function useUserProfile() {
    const isReady = useAuthReady();
    return useQuery({
        queryKey: ["user", "profile"],
        queryFn: async () => {
            const { data } = await userApi.getProfile();
            return data;
        },
        enabled: isReady,
    });
}

export function useUserStats() {
    const isReady = useAuthReady();
    return useQuery({
        queryKey: ["user", "stats"],
        queryFn: async () => {
            const { data } = await userApi.getStats();
            return data;
        },
        enabled: isReady,
    });
}

export function useUserCheckins() {
    const isReady = useAuthReady();
    return useQuery({
        queryKey: ["user", "checkins"],
        queryFn: async () => {
            const { data } = await userApi.getCheckins();
            return data;
        },
        enabled: isReady,
    });
}

export function useProfilePhoto(hasPhoto) {
    const isReady = useAuthReady();
    return useQuery({
        queryKey: ["user", "photo"],
        queryFn: async () => {
            const blob = await userApi.getProfilePhoto();
            if (!blob || blob.size === 0) return null;
            return URL.createObjectURL(blob);
        },
        enabled: isReady && !!hasPhoto,
        staleTime: 1000 * 60 * 60, // 1 hour
        gcTime: 1000 * 60 * 60 * 2, // 2 hours
    });
}


