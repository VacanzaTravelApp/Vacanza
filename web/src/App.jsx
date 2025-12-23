import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import AuthLayout from './pages/auth/AuthLayout';
import RegisterCard from './pages/auth/Registercardtempp';
import LoginCard from './pages/auth/LoginCard';
import './pages/auth/AuthLayout.css'; 
import MapPage from './pages/MapPage';
//import "mapbox-gl/dist/mapbox-gl.css";

import "./pages/auth/AuthLayout.css";

const App = () => {
    return (
        <Router>
            <Routes>
        <Route path="/map" element={<MapPage />} /> 
            
                <Route path="/" element={<Navigate to="/register" replace />} />
                <Route path="/register" element={
                    <AuthLayout>
                        <RegisterCard />
                    </AuthLayout>
                } />
                <Route path="/login" element={
                    <AuthLayout>
                        <LoginCard />
                    </AuthLayout>
                } />
                <Route path="/map" element={<MapPage />} /> 
            </Routes>
        </Router>
    );
};

export default App;
