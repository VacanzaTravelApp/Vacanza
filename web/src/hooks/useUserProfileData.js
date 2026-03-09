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
