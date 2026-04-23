import { useState, useEffect } from "react";
import { userApi } from "../api/userApi";

export const useProfilePhoto = (profile) => {
    const [profilePhotoUrl, setProfilePhotoUrl] = useState(null);
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        let objectUrl = null;
        if (profile?.hasProfilePhoto) {
            setLoading(true);
            userApi.getPhoto().then(res => {
                objectUrl = URL.createObjectURL(res.data);
                setProfilePhotoUrl(objectUrl);
            }).catch(err => {
                console.error("[useProfilePhoto] Failed to load binary photo", err);
            }).finally(() => {
                setLoading(false);
            });
        } else {
            setProfilePhotoUrl(null);
        }

        return () => {
            if (objectUrl) URL.revokeObjectURL(objectUrl);
        };
    }, [profile?.hasProfilePhoto]);

    return { profilePhotoUrl, loading };
};
