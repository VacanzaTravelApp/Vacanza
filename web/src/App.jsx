import React from "react";
import { BrowserRouter as Router, Routes, Route, Navigate, useLocation } from "react-router-dom";

import AuthLayout from "./pages/auth/AuthLayout";
import RegisterCard from "./pages/auth/RegisterCardtempclass";
import LoginCard from "./pages/auth/LoginCard";
import EmailVerificationPage from "./pages/auth/EmailVerificationPage";
import AuthActionPage from "./pages/auth/AuthActionPage";
import MapPage from "./pages/MapPage";
import GamificationSummary from "./gamification/GamificationSummary";
import SessionManager from "./components/SessionManager";

import { message } from "antd";

message.config({
    top: 60,
    duration: 3,
    maxCount: 2,
});

/** Old Firebase default path; keep redirect so past emails still work. */
function LegacyFirebaseAuthLinkRedirect() {
    const { search } = useLocation();
    return <Navigate to={{ pathname: "/confirm-email", search }} replace />;
}

const App = () => {
    return (
        <Router>
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
                    <Route path="/confirm-email" element={<AuthActionPage />} />
                    <Route path="/auth/action" element={<LegacyFirebaseAuthLinkRedirect />} />

                    <Route path="/map" element={<MapPage />} />
                    <Route path="/gamification" element={<GamificationSummary />} />

                    {/* Catch-all route */}
                    <Route path="*" element={<Navigate to="/login" replace />} />
                </Routes>
            </SessionManager>
        </Router>
    );
};

export default App;