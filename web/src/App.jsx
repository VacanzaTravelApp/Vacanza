import React from "react";
import { BrowserRouter as Router, Routes, Route, Navigate } from "react-router-dom";

import { QueryClient, QueryClientProvider } from "@tanstack/react-query";

import AuthLayout from "./pages/auth/AuthLayout";
import RegisterCard from "./pages/auth/RegisterCardtempclass";
import LoginCard from "./pages/auth/LoginCard";
import MapPage from "./pages/MapPage";

// Gamification sayfan doğru yoldan import edilmiş
import GamificationSummary from "./gamification/GamificationSummary";

const queryClient = new QueryClient();

const App = () => {
    return (
        <QueryClientProvider client={queryClient}>
            <Router>
                <Routes>
                    {/* Ana sayfaya gelenleri register'a yönlendirir */}
                    <Route path="/" element={<Navigate to="/register" replace />} />
                    
                    {/* Kayıt ve Giriş Sayfaları */}
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
                    
                    {/* Harita Sayfası */}
                    <Route path="/map" element={<MapPage />} />
                    
                    {/* Detaylı Gamification Sayfası */}
                    {/* MapPage'deki karta tıklandığında burası açılacak */}
                    <Route path="/gamification" element={<GamificationSummary />} />
                </Routes>
            </Router>
        </QueryClientProvider>
    );
};

export default App;