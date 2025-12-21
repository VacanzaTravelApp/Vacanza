import React, { useEffect, useState } from "react";
import { onAuthStateChanged, signOut } from "firebase/auth";
import { auth } from "../firebase";
import { authApi } from "../api/authApi";
import { AuthContext } from "./AuthContext";

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
        // Backend ile konuşamazsa Firebase oturumunu da sonlandır (Skip etme)
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
        isAuthenticated: !!authDto?.authenticated,
        user: authDto?.user ?? null,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}