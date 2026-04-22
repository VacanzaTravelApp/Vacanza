import React, { useEffect, useState } from "react";
import { onAuthStateChanged, signOut } from "firebase/auth";
import { auth } from "../firebase";
import { authApi } from "../api/userApi";
import { AuthContext } from "./AuthContext";

export default function AuthProvider({ children }) {
    const [loading, setLoading] = useState(true);
    const [authDto, setAuthDto] = useState(null);

    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
            setLoading(true); // Start loading immediately when auth state changes
            try {
                if (!firebaseUser) {
                    setAuthDto(null);
                    setLoading(false);
                    return;
                }

                const res = await authApi.login();

                if (typeof res.data === "string" && res.data.includes("<!doctype html>")) {
                    throw new Error("Backend returned HTML instead of JSON. Check Spring Security.");
                }

                setAuthDto(res.data);
            } catch (error) {
                console.error("Auth sync failed, backend connection required:", error);
                setAuthDto(null);

                try {
                    await signOut(auth);
                } catch (signOutErr) {
                    console.warn("Firebase signOut failed during sync error:", signOutErr);
                }
            } finally {
                setLoading(false);
            }
        });

        return () => unsubscribe();
    }, []);

    const logout = async () => {
        try {
            await signOut(auth);
        } catch (e) {
            console.warn("Logout failed:", e);
        } finally {
            setAuthDto(null);
        }
    };

    return (
        <AuthContext.Provider
            value={{
                loading,
                authDto,
                isAuthenticated: !!authDto,
                user: authDto ?? null,
                logout,
            }}
        >
            {children}
        </AuthContext.Provider>
    );
}
