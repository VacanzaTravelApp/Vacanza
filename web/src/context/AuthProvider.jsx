import React, { useEffect, useState } from "react";
import { onAuthStateChanged, signOut } from "firebase/auth";
import { auth } from "../firebase";
import { authApi } from "../api/userApi";
import { AuthContext } from "./AuthContext";
import { toast } from "../components/toast/toast";

export default function AuthProvider({ children }) {
  const [loading, setLoading] = useState(true);
  const [authDto, setAuthDto] = useState(null); // Backend UserAuthenticationDTO

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      try {
        // 1. Firebase oturumu yoksa durumu temizle
        if (!firebaseUser) {
          setAuthDto(null);
          setLoading(false);
          return;
        }

        // 2. Firebase oturumu var, backend ile senkronize ol (ZORUNLU)
        const res = await authApi.login();

        // Backend'in HTML dönüp dönmediğini kontrol et (JSON bekliyoruz)
        if (typeof res.data === "string" && res.data.includes("<!doctype html>")) {
          throw new Error("Backend returned HTML instead of JSON. Check Spring Security.");
        }

        setAuthDto(res.data);
      } catch (error) {
        console.error("Auth sync failed, backend connection required:", error);
        toast.error({
          title: "Server unreachable",
          message: error?.friendlyMessage || "We are performing a quick maintenance. Please try again in a few minutes.",
        });
        setAuthDto(null);

        try {
          await signOut(auth);
        } catch (signOutErr) {
          console.warn("Firebase signOut failed during sync error:", signOutErr);
          // signOut failed but we still need to redirect away from the map
          if (window.location.pathname === "/map") {
            window.location.href = "/login";
          }
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
        // Backend UserAuthenticationDTO has userId (no "authenticated" flag)
        isAuthenticated: !!authDto?.userId,
        user: authDto?.user ?? null,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}