import React from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import AdminLayout from "./components/AdminLayout";
import Home from "./pages/Home";
import Monitoring from "./pages/Monitoring";
import Analytics from "./pages/Analytics";
import Login from "./pages/Login";
import { useAuth } from "./context/useAuth";
import { ConfigProvider, Spin, App as AntApp } from "antd";
import { MdFlightTakeoff } from "react-icons/md";
import { motion } from "framer-motion";
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

const customSpinIndicator = (
    <motion.div
        animate={{
            y: [-2, 2, -2],
            rotate: [0, 5, -5, 0]
        }}
        transition={{
            duration: 2,
            repeat: Infinity,
            ease: "easeInOut"
        }}
        style={{ color: '#1677ff', fontSize: '32px', display: 'inline-flex' }}
    >
        <MdFlightTakeoff />
    </motion.div>
);

function App() {
    return (
        <ConfigProvider
            theme={{
                token: {
                    colorPrimary: "#1677ff",
                    borderRadius: 8,
                },
            }}
            spin={{ indicator: customSpinIndicator }}
            renderEmpty={() => (
                <div style={{ textAlign: "center", padding: "24px" }}>
                    <MdFlightTakeoff style={{ fontSize: '48px', color: '#d9d9d9', marginBottom: '8px' }} />
                    <p style={{ color: "#8c8c8c", margin: 0 }}>No Data Found (Waiting for takeoff...)</p>
                </div>
            )}
        >
            <AntApp>
                <BrowserRouter>
                    <Routes>
                        <Route path="/login" element={<Login />} />

                        <Route path="/" element={<PrivateRoute><AdminLayout /></PrivateRoute>}>
                            <Route index element={<Home />} />
                            <Route path="monitoring" element={<Monitoring />} />
                            <Route path="analytics" element={<Analytics />} />
                            <Route path="*" element={<Navigate to="/" replace />} />
                        </Route>
                    </Routes>
                </BrowserRouter>
            </AntApp>
        </ConfigProvider>
    );
}

export default App;
