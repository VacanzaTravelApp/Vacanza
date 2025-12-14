// src/App.jsx

import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';

// Auth sayfaları importu
import AuthLayout from './pages/auth/AuthLayout';
import RegisterCard from './pages/auth/Registercard';
import LoginCard from './pages/auth/LoginCard';

// Harita sayfası importu (bu dosyanın src/pages/MapPage.jsx konumunda olması kritik)
import MapPage from './pages/MapPage'; 

import './pages/auth/AuthLayout.css'; 

const App = () => {
    return (
        <Router>
            <Routes>

                {/* 1. KÖK ROTA YÖNLENDİRMESİ: "/" rotası doğrudan "/register" rotasına yönlendirilir. */}
                <Route path="/" element={<Navigate to="/register" replace />} />

                {/* 2. KAYIT OL SAYFASI ROTASI */}
                <Route path="/register" element={
                    <AuthLayout>
                        <RegisterCard />
                    </AuthLayout>
                } />

                {/* 3. GİRİŞ YAP SAYFASI ROTASI */}
                <Route path="/login" element={
                    <AuthLayout>
                        <LoginCard />
                    </AuthLayout>
                } />

                {/* 4. HARİTA SAYFASI ROTASI: Başarılı Kayıt/Giriş sonrası bu rota açılır. */}
                <Route path="/map" element={<MapPage />} /> 

            </Routes>
        </Router>
    );
};

export default App;