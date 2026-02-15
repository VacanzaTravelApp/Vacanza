import React from "react";
import { BrowserRouter as Router, Routes, Route, Navigate } from "react-router-dom";

import { QueryClient, QueryClientProvider } from "@tanstack/react-query";

import AuthLayout from "./pages/auth/AuthLayout";
import RegisterCard from "./pages/auth/RegisterCardtempclass";
import LoginCard from "./pages/auth/LoginCard";
import MapPage from "./pages/MapPage";

import GamificationSummary from "./gamification/GamificationSummary";

const queryClient = new QueryClient();

const App = () => {
    return (
        <QueryClientProvider client={queryClient}>
            <Router>
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
                    <Route path="/map" element={<MapPage />} />
                    <Route path="/gamification" element={<GamificationSummary />} />
                </Routes>
            </Router>
        </QueryClientProvider>
    );
};

export default App;
