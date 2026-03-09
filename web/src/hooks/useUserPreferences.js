import { useQuery } from "@tanstack/react-query";
import { userApi } from "../api/userApi";
import { auth } from "../firebase";
import { useEffect, useState } from "react";

export function useUserPreferences() {
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
        queryKey: ["user", "preferences"],
        queryFn: async () => {
            const { data } = await userApi.getPreferences();
            return data;
        },
        enabled: userReady,
        staleTime: 1000 * 60 * 10, // 10 minutes
    });
}
