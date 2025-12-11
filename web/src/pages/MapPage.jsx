// src/pages/MapPage.jsx

import React, { useState, useEffect } from 'react';
import { Layout, Button, Card, Avatar, FloatButton, Space } from 'antd';
import { 
    LogoutOutlined, 
    UserOutlined, 
    GlobalOutlined, 
    CompassOutlined, 
    ReloadOutlined,
    HeatMapOutlined 
} from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import Map, {
    NavigationControl,
    GeolocateControl,
} from "react-map-gl";


// Firebase importları
import { auth } from '../firebase'; 
import { onAuthStateChanged, signOut } from 'firebase/auth'; 

const { Header, Content, Footer } = Layout;

const INITIAL_VIEW_STATE = {
    longitude: 32.8597,
    latitude: 39.9334,
    zoom: 8,
};

const MAPBOX_TOKEN = import.meta.env.VITE_MAPBOX_TOKEN;

const MapPage = () => {
    const navigate = useNavigate(); 
    const [user, setUser] = useState(null); 
    const [loading, setLoading] = useState(true);
    const [viewState, setViewState] = useState(INITIAL_VIEW_STATE);
    const [mapStyle, setMapStyle] = useState("mapbox://styles/mapbox/streets-v12");

    // Sayfa yüklendiğinde kullanıcı bilgilerini al ve oturumu kontrol et
    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
            if (currentUser) {
                setUser(currentUser);
            } else {
                console.log("Oturum yok, Login'e yönlendiriliyor.");
                navigate('/login'); 
            }
            setLoading(false);
        });

        return () => unsubscribe();
    }, [navigate]);

    
    // Çıkış (Logout) Fonksiyonu
    const handleLogout = async () => {
        try {
            await signOut(auth);
            console.log("Kullanıcı çıkış yaptı.");
        } catch (error) {
            console.error("Çıkış hatası:", error);
        }
    };

    // Harita stilini değiştir
    const handleMapStyleChange = () => {
        const styles = [
            "mapbox://styles/mapbox/streets-v12",
            "mapbox://styles/mapbox/satellite-v9",
            "mapbox://styles/mapbox/outdoors-v12",
            "mapbox://styles/mapbox/light-v11",
            "mapbox://styles/mapbox/dark-v11"
        ];
        const currentIndex = styles.indexOf(mapStyle);
        const nextIndex = (currentIndex + 1) % styles.length;
        setMapStyle(styles[nextIndex]);
    };

    // Haritayı yeniden ortala
    const handleRecenter = () => {
        setViewState(INITIAL_VIEW_STATE);
    };
    
    // Yükleniyor durumu
    if (loading) {
        return (
            <div style={{ height: '100vh', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                <p>Yükleniyor...</p>
            </div>
        );
    }
    
    if (!user) {
        return null; 
    }

    // Kullanıcı bilgileri
    const displayName = user.displayName || user.email.split('@')[0];
    const userEmail = user.email;

    return (
        <Layout style={{ minHeight: '100vh' }}>
            {/* ÜST MENÜ (Header) */}
            <Header style={{ 
                display: 'flex', 
                alignItems: 'center', 
                justifyContent: 'space-between', 
                padding: '0 20px', 
                background: '#fff', 
                borderBottom: '1px solid #f0f0f0',
                position: 'fixed', 
                width: '100%',
                zIndex: 100 
            }}>
                
                <div style={{ display: 'flex', alignItems: 'center' }}>
                    <GlobalOutlined style={{ fontSize: '24px', color: '#1890ff', marginRight: '10px' }} />
                    <span style={{ fontSize: '20px', fontWeight: 'bold', color: '#333' }}>Vacanza Map</span>
                </div>

                <Button 
                    type="default" 
                    icon={<LogoutOutlined />} 
                    onClick={handleLogout}
                >
                    Çıkış Yap
                </Button>
            </Header>

            {/* İÇERİK (Content) */}
            <Content style={{ 
                marginTop: 64, 
                padding: '24px', 
                position: 'relative', 
                flexGrow: 1 
            }}>

                {/* 🗺️ HARİTA ALANI */}
                <div style={{ 
                    height: 'calc(100vh - 88px)', 
                    width: '100%', 
                    borderRadius: '12px',
                    overflow: 'hidden',
                    boxShadow: '0 4px 12px rgba(0,0,0,0.1)'
                }}>
                    <Map
                        {...viewState}
                        onMove={(e) => setViewState(e.viewState)}
                        style={{ width: "100%", height: "100%" }}
                        mapStyle={mapStyle}
                        mapboxAccessToken={MAPBOX_TOKEN}
                        onError={(e) => console.error("Map error:", e)}
                    >
                        <NavigationControl position="bottom-right" />
                        <GeolocateControl
                            position="bottom-right"
                            trackUserLocation
                            showUserHeading
                        />
                    </Map>
                </div>

                {/* 👤 SOL ÜST: PROFİL KARTI / BADGE */}
                <Card 
                    style={{ 
                        position: 'absolute', 
                        top: 40, 
                        left: 40, 
                        zIndex: 50, 
                        width: 250,
                        backgroundColor: 'rgba(255, 255, 255, 0.95)', 
                        backdropFilter: 'blur(10px)'
                    }}
                    bodyStyle={{ display: 'flex', alignItems: 'center', padding: '16px' }}
                >
                    <Avatar 
                        size={48} 
                        icon={<UserOutlined />} 
                        src={user.photoURL} 
                        style={{ marginRight: 15, backgroundColor: '#1890ff' }}
                    />
                    <div>
                        <div style={{ fontWeight: 'bold', fontSize: '16px' }}>
                            {displayName} 
                        </div>
                        <div style={{ fontSize: '12px', color: '#888' }}>
                            {userEmail} 
                        </div>
                    </div>
                </Card>


                {/* ⚙️ SAĞDA DİKEY ACTION BUTONLARI (FloatButton) */}
                <Space 
                    direction="vertical" 
                    style={{ 
                        position: 'absolute', 
                        bottom: 40, 
                        right: 40, 
                        zIndex: 50 
                    }}
                >
                    {/* Map style butonu */}
                    <FloatButton 
                        icon={<HeatMapOutlined />} 
                        tooltip={<div>Harita Stilini Değiştir</div>}
                        onClick={handleMapStyleChange}
                    />
                    {/* 2D-3D butonu */}
                    <FloatButton 
                        icon={<CompassOutlined />} 
                        tooltip={<div>2D / 3D Görünüm</div>}
                        onClick={() => console.log('2D/3D Değiştirildi')}
                    />
                    {/* recenter butonu */}
                    <FloatButton 
                        icon={<ReloadOutlined />} 
                        tooltip={<div>Haritayı Yeniden Ortala</div>}
                        onClick={handleRecenter}
                    />
                </Space>


            </Content>

            {/* ALT BİLGİ (Footer) */}
            <Footer style={{ textAlign: 'center', padding: '12px 50px', background: '#fff' }}>
                Vacanza App ©{new Date().getFullYear()}
            </Footer>
        </Layout>
    );
};

export default MapPage;