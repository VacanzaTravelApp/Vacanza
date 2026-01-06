// src/pages/auth/AuthLayout.jsx

import React from 'react';
import { useLocation } from 'react-router-dom';
// Importing Ant Design icons (for Feature Card)
import { ThunderboltOutlined, WalletOutlined, StarOutlined, CalendarOutlined } from '@ant-design/icons';
// Importing icons for statistics from the React Icons (Ri) package
import { RiUserSmileLine, RiEarthLine, RiMapPinLine } from 'react-icons/ri'; 

// NEW: Imported MdFlightTakeoff (Vacanza Icon) from React Icons (Md) package
import { MdFlightTakeoff } from 'react-icons/md'; 

import './AuthLayout.css'; 

// ... FeatureCard and StatItem components (UNCHANGED) ...

const FeatureCard = ({ icon, title, description }) => (
    <div className="feature-card">
        <span className="card-icon">{icon}</span>
        <div className="card-text">
            <p className="card-title">{title}</p>
            <p className="card-description">{description}</p>
        </div>
    </div>
);

const StatItem = ({ icon, number, text }) => (
    <div>
        <span className="stat-icon">{icon}</span> 
        <span className="stat-number">{number}</span>
        <p className="stat-text">{text}</p>
    </div>
);


const AuthLayout = ({ children }) => {
    // ... headerData part (UNCHANGED) ...
    const location = useLocation();
    const isLoginPage = location.pathname === '/login'; 

    const headerData = isLoginPage
        ? { // LOGIN SCREEN
            slogan: "Welcome Back!", 
            description: "Continue your planned journeys and discover new routes."
        }
        : { // REGISTER SCREEN (Default)
            slogan: "Your Travel Planning Assistant", 
            description: "Plan every detail before and after your trip, optimize your route, and track the excitement."
        };


    return (
        <div className="auth-container">
            {/* LEFT VISUAL COLUMN */}
            <div className="auth-visual-column">
                <div className="vacanza-header">
                    
                    {/* UPDATED: Added MdFlightTakeoff icon */}
                    <span className="logo-text">
                        <MdFlightTakeoff style={{ marginRight: '10px', fontSize: '36px' }} />
                        Vacanza
                    </span>

                    <p className="slogan">{headerData.slogan}</p> 
                    <p className="description">{headerData.description}</p>
                </div>

                {/* ... other components (UNCHANGED) ... */}
                <div className="feature-grid">
                    <FeatureCard 
                        icon={<ThunderboltOutlined />} 
                        title="Smart Route Planning" 
                        description="AI-supported most efficient itinerary"
                    />
                    <FeatureCard 
                        icon={<WalletOutlined />} 
                        title="Budget Tracking" 
                        description="Monitor your expenditures instantly"
                    />
                    <FeatureCard 
                        icon={<StarOutlined />} 
                        title="Personalized Recommendations" 
                        description="Custom travel routes just for you"
                    />
                    <FeatureCard 
                        icon={<CalendarOutlined />} 
                        title="Schedule Management" 
                        description="Daily activity planning"
                    />
                </div>

                <div className="stats-container">
                    <StatItem
                        icon={<RiUserSmileLine />} 
                        number="50.000+"
                        text="Happy Traveler"
                    />
                    <StatItem
                        icon={<RiEarthLine />} 
                        number="120+"
                        text="Countries"
                    />
                    <StatItem
                        icon={<RiMapPinLine />} 
                        number="1000+"
                        text="Destinations"
                    />
                </div>
            </div>

            {/* RIGHT FORM COLUMN */}
            <div className="auth-form-column">
                {children}
            </div>
        </div>
    );
};

export default AuthLayout;