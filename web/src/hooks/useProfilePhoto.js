import { useQuery } from "@tanstack/react-query";
import { userApi } from "../api/userApi";
import { useAuthReady } from "./useUserProfileData";

const blobToBase64 = (blob) => {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onloadend = () => resolve(reader.result);
        reader.onerror = reject;
        reader.readAsDataURL(blob);
    });
};

export const useProfilePhoto = () => {
    const isReady = useAuthReady();

    const { data: profilePhotoUrl, isLoading: loading } = useQuery({
        queryKey: ["user", "photo"],
        queryFn: async () => {
            try {
                const res = await userApi.getPhoto();
                const base64Str = await blobToBase64(res.data);
                localStorage.setItem("profilePhotoBase64", base64Str);
                return base64Str;
            } catch (err) {
                if (err.response?.status === 404) {
                    localStorage.removeItem("profilePhotoBase64");
                    return null;
                }
                throw err;
            }
        },
        enabled: isReady,
        initialData: () => {
            const cached = localStorage.getItem("profilePhotoBase64");
            return cached ? cached : undefined;
        },
        staleTime: 1000 * 60 * 5, // 5 mins before fetching in background
        cacheTime: 1000 * 60 * 60, // 1 hour
    });

    return { profilePhotoUrl, loading };
};
