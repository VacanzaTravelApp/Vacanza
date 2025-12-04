// src/pages/auth/AuthLayout.jsx

import React from 'react';
import { useLocation } from 'react-router-dom';
// Ant Design ikonlarını (Feature Card için) import ediyoruz
import { ThunderboltOutlined, WalletOutlined, StarOutlined, CalendarOutlined } from '@ant-design/icons';
// React Icons (Ri) paketinden istatistikler için ikonları import ediyoruz
import { RiUserSmileLine, RiEarthLine, RiMapPinLine } from 'react-icons/ri'; 

// YENİ: React Icons'tan MdFlightTakeoff (Vacanza İkonu) import edildi
import { MdFlightTakeoff } from 'react-icons/md'; 

import './AuthLayout.css'; 

// ... FeatureCard ve StatItem bileşenleri (DEĞİŞMEDİ) ...

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
    // ... headerData kısmı (DEĞİŞMEDİ) ...
    const location = useLocation();
    const isLoginPage = location.pathname === '/login'; 

    const headerData = isLoginPage
        ? { // LOGIN EKRANI
            slogan: "Tekrar Hoş Geldiniz!", 
            description: "Planladığınız gezilerinize devam edin ve yeni rotalar keşfedin."
        }
        : { // REGISTER EKRANI (Varsayılan)
            slogan: "Seyahat Planlama Asistanınız", 
            description: "Gezi öncesi ve sonrası her detayı planla, rotanı optimize et, heyecanı takip et."
        };


    return (
        <div className="auth-container">
            {/* SOL GÖRSEL SÜTUN */}
            <div className="auth-visual-column">
                <div className="vacanza-header">
                    
                    {/* GÜNCELLENDİ: MdFlightTakeoff ikonu eklendi */}
                    <span className="logo-text">
                        <MdFlightTakeoff style={{ marginRight: '10px', fontSize: '36px' }} />
                        Vacanza
                    </span>

                    <p className="slogan">{headerData.slogan}</p> 
                    <p className="description">{headerData.description}</p>
                </div>

                {/* ... diğer bileşenler (DEĞİŞMEDİ) ... */}
                <div className="feature-grid">
                    <FeatureCard 
                        icon={<ThunderboltOutlined />} 
                        title="Akıllı Rota Planlama" 
                        description="AI destekli en verimli güzergah"
                    />
                    <FeatureCard 
                        icon={<WalletOutlined />} 
                        title="Bütçe Takibi" 
                        description="Harcamalarını anlık kontrol et"
                    />
                    <FeatureCard 
                        icon={<StarOutlined />} 
                        title="Kişisel Öneriler" 
                        description="Senin için özel gezi rotaları"
                    />
                    <FeatureCard 
                        icon={<CalendarOutlined />} 
                        title="Program Yönetimi" 
                        description="Günlük aktivite planlaması"
                    />
                </div>

                <div className="stats-container">
                    <StatItem
                        icon={<RiUserSmileLine />} 
                        number="50.000+"
                        text="Mutlu Gezgin"
                    />
                    <StatItem
                        icon={<RiEarthLine />} 
                        number="120+"
                        text="Ülke"
                    />
                    <StatItem
                        icon={<RiMapPinLine />} 
                        number="1000+"
                        text="Destinasyon"
                    />
                </div>
            </div>

            {/* SAĞ FORM SÜTUNU */}
            <div className="auth-form-column">
                {children}
            </div>
        </div>
    );
};

export default AuthLayout;