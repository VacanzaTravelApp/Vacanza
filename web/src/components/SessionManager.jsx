import React, { useEffect, useRef } from "react";
import { onAuthStateChanged, signOut } from "firebase/auth";
import { auth } from "../firebase";
import { authApi } from "../api/userApi";
import { useNavigate, useLocation } from "react-router-dom";
import { message } from "antd";

const INACTIVITY_TIMEOUT = 15 * 60 * 1000; // 15 minutes

const SessionManager = ({ children }) => {
    const navigate = useNavigate();
    const location = useLocation();
    const timerRef = useRef(null);
    const syncDoneRef = useRef(false);

    const handleLogout = async (reason = "inactivity") => {
        try {
            if (reason === "inactivity") {
                message.warning("Logged out due to inactivity.");
            }
            await signOut(auth);
            // Backend automatically clears session when token is gone or explicitly:
            // await authApi.logout(); 
            navigate("/login");
        } catch (err) {
            console.error("Logout failed:", err);
        }
    };

    const resetTimer = () => {
        if (timerRef.current) clearTimeout(timerRef.current);

        // Only set inactivity timer if we are NOT on auth pages
        const isAuthPage = ["/login", "/register", "/verify-email"].includes(location.pathname);
        if (!isAuthPage && auth.currentUser) {
            timerRef.current = setTimeout(() => handleLogout("inactivity"), INACTIVITY_TIMEOUT);
        }
    };

    useEffect(() => {
        const unsubAuth = onAuthStateChanged(auth, async (user) => {
            if (user) {
                // 1. Initial Sync (across tab closes)
                if (!syncDoneRef.current) {
                    try {
                        await authApi.login();
                        console.log("[SessionManager] Backend session restored.");
                        syncDoneRef.current = true;
                    } catch (e) {
                        console.warn("[SessionManager] Session sync failed:", e.message);
                    }
                }

                resetTimer();
            } else {
                syncDoneRef.current = false;
                if (timerRef.current) clearTimeout(timerRef.current);
            }
        });

        // Activity listeners
        const events = ["mousedown", "mousemove", "keypress", "scroll", "touchstart"];
        const throttledReset = () => {
            // Small optimization: only reset every 5s if many events fire
            resetTimer();
        };

        events.forEach((name) => document.addEventListener(name, throttledReset));

        return () => {
            unsubAuth();
            events.forEach((name) => document.removeEventListener(name, throttledReset));
            if (timerRef.current) clearTimeout(timerRef.current);
        };
    }, [navigate, location.pathname]);

    return <>{children}</>;
};

export default SessionManager;
