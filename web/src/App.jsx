import React, { useEffect } from "react";
import { BrowserRouter as Router, Routes, Route, Navigate, useLocation } from "react-router-dom";

import AuthLayout from "./pages/auth/AuthLayout";
import RegisterCard from "./pages/auth/RegisterCardtempclass";
import LoginCard from "./pages/auth/LoginCard";
import EmailVerificationPage from "./pages/auth/EmailVerificationPage";
import AuthActionPage from "./pages/auth/AuthActionPage";
import MapPage from "./pages/MapPage";
import GamificationSummary from "./gamification/GamificationSummary";
import SessionManager from "./components/SessionManager";
import { VacanzaToastProvider } from "./components/toast/VacanzaToast";

/** Old Firebase default path; keep redirect so past emails still work. */
function LegacyFirebaseAuthLinkRedirect() {
    const { search } = useLocation();
    return <Navigate to={{ pathname: "/confirm-email", search }} replace />;
}

const App = () => {
    // Mac Trackpad Pinches trigger 'wheel' (Chrome) or 'gesturestart' (Safari/Mac)
    // We prevent default browser UI zooming UNLESS we are hovering the map
    useEffect(() => {
        const handleZoomEvent = (e) => {
            // Check if gesture started or event is occurring over the map
            const isOverMap = e.target.closest('.mapboxgl-map') ||
                e.target.closest('.mapboxgl-canvas-container');

            if (isOverMap) return;

            // Block wheel zoom with ctrl (Chrome/Edge pinch)
            if (e.type === 'wheel' && e.ctrlKey) {
                e.preventDefault();
            }

            // Block MacOS Safari native pinch gesture
            if (e.type === 'gesturestart' || e.type === 'gesturechange') {
                e.preventDefault();
            }
        };

        // passive: false is mandatory to allow preventDefault()
        document.addEventListener('wheel', handleZoomEvent, { passive: false });
        document.addEventListener('gesturestart', handleZoomEvent, { passive: false });
        document.addEventListener('gesturechange', handleZoomEvent, { passive: false });

        return () => {
            document.removeEventListener('wheel', handleZoomEvent);
            document.removeEventListener('gesturestart', handleZoomEvent);
            document.removeEventListener('gesturechange', handleZoomEvent);
        };
    }, []);

    return (
        <Router>
          <VacanzaToastProvider>
            <SessionManager>
                <Routes>
                    <Route path="/" element={<Navigate to="/register" replace />} />

                    <Route
                        path="/register"
                        element={
                            <AuthLayout>
                                <RegisterCard />
                            </AuthLayout>
                        }
                    />

                    <Route
                        path="/login"
                        element={
                            <AuthLayout>
                                <LoginCard />
                            </AuthLayout>
                        }
                    />

                    {/* NEW ROUTES */}
                    <Route
                        path="/verify-email"
                        element={
                            <AuthLayout>
                                <EmailVerificationPage />
                            </AuthLayout>
                        }
                    />
                    {/* Not under /auth/* — in production that prefix is often proxied to the Java API, which made /auth/action return JSON and download as a file named "action". */}
                    <Route
                        path="/confirm-email"
                        element={
                            <AuthLayout>
                                <AuthActionPage />
                            </AuthLayout>
                        }
                    />
                    <Route path="/auth/action" element={<LegacyFirebaseAuthLinkRedirect />} />

                    <Route path="/map" element={<MapPage />} />
                    <Route path="/gamification" element={<GamificationSummary />} />

                    {/* Catch-all route */}
                    <Route path="*" element={<Navigate to="/login" replace />} />
                </Routes>
            </SessionManager>
          </VacanzaToastProvider>
        </Router>
    );
};

export default App;