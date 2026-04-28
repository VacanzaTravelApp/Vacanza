import React from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import AdminLayout from "./components/AdminLayout";
import Home from "./pages/Home";
import Monitoring from "./pages/Monitoring";
import Analytics from "./pages/Analytics";
import UserManagement from "./pages/UserManagement";
import Login from "./pages/Login";
import { useAuth } from "./context/useAuth";
import { ConfigProvider, Spin, App as AntApp } from "antd";
import "./App.css";

// Basic PrivateRoute component
const PrivateRoute = ({ children }) => {
    const { isAuthenticated, loading } = useAuth();

    if (loading) {
        return (
            <div style={{ display: "flex", justifyContent: "center", alignItems: "center", height: "100vh" }}>
                <Spin size="large" description="Verifying session..." />
            </div>
        );
    }

    return isAuthenticated ? children : <Navigate to="/login" replace />;
};

const PublicRoute = ({ children }) => {
    const { isAuthenticated, loading } = useAuth();
    if (loading) return null;
    return isAuthenticated ? <Navigate to="/" replace /> : children;
};

function App() {
    return (
        <ConfigProvider
            theme={{
                token: {
                    colorPrimary: "#FF6B6B",
                    borderRadius: 8,
                },
            }}
        >
            <AntApp>
                <BrowserRouter>
                    <Routes>
                        <Route path="/login" element={
                            <PublicRoute>
                                <Login />
                            </PublicRoute>
                        } />

                        <Route path="/" element={<PrivateRoute><AdminLayout /></PrivateRoute>}>
                            <Route index element={<Home />} />
                            <Route path="monitoring" element={<Monitoring />} />
                            <Route path="analytics" element={<Analytics />} />
                            <Route path="users" element={<UserManagement />} />
                            <Route path="*" element={<Navigate to="/" replace />} />
                        </Route>
                    </Routes>
                </BrowserRouter>
            </AntApp>
        </ConfigProvider>
    );
}

export default App;
