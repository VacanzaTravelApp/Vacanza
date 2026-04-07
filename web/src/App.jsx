import React from "react";
import { BrowserRouter as Router, Routes, Route, Navigate } from "react-router-dom";

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
                    <Route path="/verify-email" element={<EmailVerificationPage />} />
                    <Route path="/auth/action" element={<AuthActionPage />} />

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