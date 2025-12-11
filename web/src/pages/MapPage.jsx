// src/pages/MapPage.jsx (Tüm hatalardan ve uyarıdan arındırılmış, son versiyon)

import React, { useState, useEffect } from "react";
import {
  Layout,
  Button,
  Card,
  Avatar,
  FloatButton,
  Space,
  message,
} from "antd";
import {
  LogoutOutlined,
  UserOutlined,
  GlobalOutlined,
  CompassOutlined,
  ReloadOutlined,
  HeatMapOutlined,
} from "@ant-design/icons";
import { useNavigate } from "react-router-dom";

// Firebase importları
import { auth } from "../firebase";
import { onAuthStateChanged, signOut } from "firebase/auth";

// 🗺️ MAPBOX / REACT-MAP-GL İMPORTLARI (v7.0.1 ile uyumlu)
import Map, { 
  NavigationControl,
  GeolocateControl,
} from "react-map-gl";
// import "mapbox-gl/dist/mapbox-gl.css"; // CSS yükleme hatasını atlamak için yorum satırı bırakıldı

const { Header, Content, Footer } = Layout;

// HARİTA AYARLARI
const MAPBOX_ACCESS_TOKEN = import.meta.env.VITE_MAPBOX_ACCESS_TOKEN;

// Varsayılan kamera pozisyonu (Ankara)
const INITIAL_VIEWPORT = {
  longitude: 32.8597,
  latitude: 39.9334,
  zoom: 8,
  bearing: 0,
  pitch: 0,
};

const MapPage = () => {
  const navigate = useNavigate();
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  // 🔥 UYARI GİDERME: viewport state'i yerine güncel v7 state mekanizması kullanıldı
  const [viewState, setViewState] = useState(INITIAL_VIEWPORT);

  // Kullanıcı oturumu kontrolü
  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
      if (currentUser) {
        setUser(currentUser);
        setLoading(false);
      } else {
        setLoading(false);
        message.error("Oturum sonlandı, lütfen giriş yapın.");
        navigate("/login");
      }
    });

    return () => unsubscribe();
  }, [navigate]);

  // Çıkış (Logout) fonksiyonu
  const handleLogout = async () => {
    try {
      await signOut(auth);
      message.success("Başarıyla çıkış yapıldı.");
    } catch (error) {
      console.error("Çıkış hatası:", error);
      message.error(`Çıkış yapılamadı: ${error.message}`);
    }
  };

  // Yükleniyor durumu
  if (loading) {
    return (
      <div
        style={{
          height: "100vh",
          display: "flex",
          justifyContent: "center",
          alignItems: "center",
        }}
      >
        <p>Yükleniyor...</p>
      </div>
    );
  }

  if (!user) {
    return null;
  }

  const displayName = user.displayName || user.email.split("@")[0];
  const userEmail = user.email;

  return (
    <Layout style={{ minHeight: "100vh" }}>
      {/* ÜST MENÜ (Header) */}
      <Header
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          padding: "0 20px",
          background: "#fff",
          borderBottom: "1px solid #f0f0f0",
          position: "fixed",
          width: "100%",
          zIndex: 100,
        }}
      >
        <div style={{ display: "flex", alignItems: "center" }}>
          <GlobalOutlined
            style={{ fontSize: "24px", color: "#1890ff", marginRight: 10 }}
          />
          <span style={{ fontSize: 20, fontWeight: "bold", color: "#333" }}>
            Vacanza Map
          </span>
        </div>

        <Button type="default" icon={<LogoutOutlined />} onClick={handleLogout}>
          Çıkış Yap
        </Button>
      </Header>

      {/* İÇERİK (Content) */}
      <Content
        style={{
          marginTop: 64,
          padding: "24px",
          position: "relative",
          flexGrow: 1,
        }}
      >
        {/* 🗺️ HARİTA ALANI */}
        <div
          style={{
            height: "calc(100vh - 88px)",
            width: "100%",
            borderRadius: "12px",
            overflow: "hidden",
            boxShadow: "0 4px 12px rgba(0,0,0,0.1)",
          }}
        >
          {MAPBOX_ACCESS_TOKEN ? (
            <Map
              initialViewState={viewState} // Harita konumunu başlatır
              style={{ width: "100%", height: "100%" }}
              mapStyle="mapbox://styles/mapbox/streets-v11"
              mapboxAccessToken={MAPBOX_ACCESS_TOKEN}
              onMove={(evt) => setViewState(evt.viewState)} // Hareket algılanınca state'i günceller
            >
              {/* Navigation & Geolocate Kontrolleri */}
              <NavigationControl 
                position="bottom-right" 
              />
              <GeolocateControl
                position="bottom-right" 
                positionOptions={{ enableHighAccuracy: true }}
                trackUserLocation={true}
                showUserHeading={true}
              />
            </Map>
          ) : (
            <div
              style={{
                height: "100%",
                display: "flex",
                justifyContent: "center",
                alignItems: "center",
                backgroundColor: "#f0f0f0",
              }}
            >
              Mapbox Access Token yüklenemedi. Lütfen .env dosyasında
              VITE_MAPBOX_ACCESS_TOKEN değerini kontrol edin.
            </div>
          )}
        </div>

        {/* 👤 SOL ÜST: PROFİL KARTI / BADGE */}
        <Card
          style={{
            position: "absolute",
            top: 40,
            left: 40,
            zIndex: 50,
            width: 250,
            backgroundColor: "rgba(255, 255, 255, 0.9)",
            backdropFilter: "blur(5px)",
          }}
          bodyStyle={{ display: "flex", alignItems: "center", padding: 16 }}
        >
          <Avatar
            size={48}
            icon={<UserOutlined />}
            src={user.photoURL}
            style={{ marginRight: 15, backgroundColor: "#1890ff" }}
          />
          <div>
            <div style={{ fontWeight: "bold", fontSize: 16 }}>{displayName}</div>
            <div style={{ fontSize: 12, color: "#888" }}>{userEmail}</div>
          </div>
        </Card>

        {/* ⚙️ SAĞDA DİKEY ACTION BUTONLARI */}
        <Space
          direction="vertical"
          style={{
            position: "absolute",
            bottom: 40,
            right: 40,
            zIndex: 50,
          }}
        >
          {/* Map style butonu – henüz sadece log basıyor */}
          <FloatButton
            icon={<HeatMapOutlined />}
            tooltip={<div>Harita stilini değiştir</div>}
            onClick={() => console.log("Map stili değiştirildi")}
          />
          {/* 2D / 3D (ileride pitch/bearing ile oynayabilirsin) */}
          <FloatButton
            icon={<CompassOutlined />}
            tooltip={<div>2D / 3D görünüm</div>}
            onClick={() =>
              setViewState((prev) => ({
                ...prev,
                pitch: prev.pitch === 0 ? 60 : 0,
                bearing: prev.bearing === 0 ? 30 : 0,
              }))
            }
          />
          {/* Recenter butonu */}
          <FloatButton
            icon={<ReloadOutlined />}
            tooltip={<div>Haritayı yeniden ortala</div>}
            onClick={() =>
              setViewState((prev) => ({
                ...prev,
                ...INITIAL_VIEWPORT,
              }))
            }
          />
        </Space>
      </Content>

      {/* ALT BİLGİ (Footer) */}
      <Footer
        style={{
          textAlign: "center",
          padding: "12px 50px",
          background: "#fff",
        }}
      >
        Vacanza App ©{new Date().getFullYear()}
      </Footer>
    </Layout>
  );
};

export default MapPage;