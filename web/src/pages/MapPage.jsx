// src/pages/MapPage.jsx

import React, { useState, useEffect } from 'react'; // <-- GÜNCELLEME: useState ve useEffect import edildi
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

// Firebase importları
import { auth } from '../firebase'; 
import { onAuthStateChanged, signOut } from 'firebase/auth'; 

const { Header, Content, Footer } = Layout;

const MapPage = () => {
    // useNavigate() çağrısı burada yapılmalı
    const navigate = useNavigate(); 

    // 1. Kullanıcı durumunu saklamak için state tanımlayalım
    const [user, setUser] = useState(null); 
    const [loading, setLoading] = useState(true);

    // 2. Sayfa yüklendiğinde kullanıcı bilgilerini al ve oturumu kontrol et
    useEffect(() => {
        // Firebase Auth dinleyicisini başlat
        const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
            if (currentUser) {
                // Kullanıcı giriş yapmışsa bilgileri state'e kaydet
                setUser(currentUser);
            } else {
                // Kullanıcı çıkış yapmışsa veya oturumu yoksa Login'e yönlendir
                console.log("Oturum yok, Login'e yönlendiriliyor.");
                navigate('/login'); 
            }
            setLoading(false);
        });

        // Temizleme fonksiyonu: Bileşen kaldırıldığında dinleyiciyi durdur
        return () => unsubscribe();
    }, [navigate]); // navigate, useEffect bağımlılık dizisine eklendi

    
    // Çıkış (Logout) Fonksiyonu
    const handleLogout = async () => {
        try {
            await signOut(auth); // Firebase çıkış işlemi
            // signOut başarılı olduğunda onAuthStateChanged devreye girer ve Login'e yönlendirir
            console.log("Kullanıcı çıkış yaptı.");
        } catch (error) {
            console.error("Çıkış hatası:", error);
        }
    };
    
    // Yükleniyor durumu
    if (loading) {
        return (
            <div style={{ height: '100vh', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                <p>Yükleniyor...</p>
            </div>
        );
    }
    
    // Yükleme bittiğinde kullanıcı yoksa (navigate zaten çalışmış olmalı)
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
                    onClick={handleLogout} // <-- handleLogout fonksiyonu burada kullanılıyor
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

                {/* 🗺️ HARİTA ALANI (PLACEHOLDER CONTAINER) */}
                <div style={{ 
                    height: 'calc(100vh - 88px)', 
                    width: '100%', 
                    backgroundColor: '#e6e6e6', 
                    display: 'flex',
                    justifyContent: 'center',
                    alignItems: 'center',
                    borderRadius: '12px',
                    boxShadow: '0 4px 12px rgba(0,0,0,0.1)',
                    fontSize: '24px',
                    color: '#666',
                    fontWeight: '600'
                }}>
                    HARİTA BİLEŞENİ BURAYA EKLENECEK
                </div>

                {/* 👤 SOL ÜST: PROFİL KARTI / BADGE */}
                <Card 
                    style={{ 
                        position: 'absolute', 
                        top: 40, 
                        left: 40, 
                        zIndex: 50, 
                        width: 250,
                        backgroundColor: 'rgba(255, 255, 255, 0.9)', 
                        backdropFilter: 'blur(5px)'
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
                        onClick={() => console.log('Map Stili Değiştirildi')}
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
                        onClick={() => console.log('Harita Yeniden Ortalama')}
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