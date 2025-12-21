// src/context/AuthProvider.jsx
import React, { useEffect, useState } from "react";
import { onAuthStateChanged, signOut } from "firebase/auth";
import { auth } from "../firebase";
import { authApi } from "../api/authApi";
import { AuthContext } from "./AuthContext";

export default function AuthProvider({ children }) {
  const [loading, setLoading] = useState(true);
  const [authDto, setAuthDto] = useState(null); // backend UserAuthenticationDTO

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      try {
        // ❌ Firebase user yok → logged out state
        if (!firebaseUser) {
          setAuthDto(null);
          setLoading(false);
          return;
        }

        // ✅ Firebase user var → backend sync (session restore)
        const res = await authApi.login();
        setAuthDto(res.data);
      } catch (error) {
        console.error("Auth sync failed, logging out:", error);
        setAuthDto(null);

        // token invalid → Firebase logout
        try {
          await signOut(auth);
        } catch (signOutErr) {
          // ✅ boş catch değil → ESLint susar
          console.warn("Firebase signOut failed:", signOutErr);
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
