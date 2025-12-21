import React from "react";
import { BrowserRouter as Router, Routes, Route, Navigate } from "react-router-dom";

import AuthLayout from "./pages/auth/AuthLayout";
import RegisterCard from "./pages/auth/Registercard";
import LoginCard from "./pages/auth/LoginCard";
import MapPage from "./pages/MapPage";

import "./pages/auth/AuthLayout.css";

const App = () => {
  return (
    <Router>
      <Routes>
        {/* Açılış */}
        <Route path="/" element={<Navigate to="/register" replace />} />

        {/* Auth sayfaları */}
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

        {/* App ekranı */}
        <Route path="/map" element={<MapPage />} />

        {/* 404 fallback */}
        <Route path="*" element={<Navigate to="/register" replace />} />
      </Routes>
    </Router>
  );
};

export default App;
