// src/App.jsx
import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import AuthLayout from './pages/auth/AuthLayout';
import RegisterCard from './pages/auth/Registercard';
import LoginCard from './pages/auth/LoginCard';
import './pages/auth/AuthLayout.css'; 

const App = () => {
    return (
        <Router>
            <Routes>

                {/* 1. Açılışta Register'a yönlendir */}
                <Route path="/" element={<Navigate to="/register" replace />} />

                {/* 2. Kayıt Ol Sayfası */}
                <Route path="/register" element={
                    <AuthLayout>
                        <RegisterCard />
                    </AuthLayout>
                } />

                {/* 3. Giriş Yap Sayfası */}
                <Route path="/login" element={
                    <AuthLayout>
                        <LoginCard />
                    </AuthLayout>
                } />

            </Routes>
        </Router>
    );
};

export default App;
