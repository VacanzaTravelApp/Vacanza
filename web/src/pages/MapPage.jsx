// src/pages/MapPage.jsx
import React, { useEffect, useMemo, useState } from "react";
import { Layout, Button, Card, Avatar, FloatButton, Space, message } from "antd";
import {
  LogoutOutlined,
  UserOutlined,
  GlobalOutlined,
  CompassOutlined,
  ReloadOutlined,
  HeatMapOutlined,
} from "@ant-design/icons";
import { useNavigate } from "react-router-dom";

import Map, { NavigationControl, GeolocateControl } from "react-map-gl";

import { auth } from "../firebase";
import { onAuthStateChanged, signOut } from "firebase/auth";

const { Header, Content, Footer } = Layout;

const INITIAL_VIEW_STATE = {
  longitude: 32.8597,
  latitude: 39.9334,
  zoom: 8,
};

const STYLES = [
  "mapbox://styles/mapbox/streets-v12",
  "mapbox://styles/mapbox/outdoors-v12",
  "mapbox://styles/mapbox/light-v11",
  "mapbox://styles/mapbox/dark-v11",
  "mapbox://styles/mapbox/satellite-v9",
];

export default function MapPage() {
  const navigate = useNavigate();

  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  const [viewState, setViewState] = useState(INITIAL_VIEW_STATE);
  const [styleIndex, setStyleIndex] = useState(0);

  const MAPBOX_TOKEN = import.meta.env.VITE_MAPBOX_ACCESS_TOKEN;

  const mapStyle = useMemo(() => STYLES[styleIndex], [styleIndex]);

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, (currentUser) => {
      if (!currentUser) {
        message.error("Oturum yok, giriş ekranına yönlendirildin.");
        navigate("/login");
        return;
      }
      setUser(currentUser);
      setLoading(false);
    });

    return () => unsub();
  }, [navigate]);

  const handleLogout = async () => {
    try {
      await signOut(auth);
      message.success("Çıkış yapıldı.");
      navigate("/login");
    } catch (e) {
      message.error("Çıkış yapılamadı.");
      console.error(e);
    }
  };

  const handleRecenter = () => setViewState(INITIAL_VIEW_STATE);

  const handleMapStyleChange = () =>
    setStyleIndex((prev) => (prev + 1) % STYLES.length);

  if (loading) {
    return (
      <div style={{ height: "100vh", display: "grid", placeItems: "center" }}>
        Yükleniyor...
      </div>
    );
  }

  if (!user) return null;

  const displayName = user.displayName || user.email?.split("@")?.[0] || "User";
  const userEmail = user.email || "";

  return (
    <Layout style={{ minHeight: "100vh" }}>
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
          <GlobalOutlined style={{ fontSize: 24, color: "#1890ff", marginRight: 10 }} />
          <span style={{ fontSize: 20, fontWeight: 700, color: "#333" }}>
            Vacanza Map
          </span>
        </div>

        <Button type="default" icon={<LogoutOutlined />} onClick={handleLogout}>
          Çıkış Yap
        </Button>
      </Header>

      <Content
        style={{
          marginTop: 64,
          padding: 24,
          position: "relative",
          flexGrow: 1,
        }}
      >
        <div
          style={{
            height: "calc(100vh - 88px)",
            width: "100%",
            borderRadius: 12,
            overflow: "hidden",
            boxShadow: "0 4px 12px rgba(0,0,0,0.1)",
            background: "#f5f5f5",
          }}
        >
          {!MAPBOX_TOKEN ? (
            <div style={{ height: "100%", display: "grid", placeItems: "center" }}>
              Mapbox token bulunamadı. <br />
              `.env` içine <b>VITE_MAPBOX_ACCESS_TOKEN=...</b> ekle ve dev’i restartla.
            </div>
          ) : (
            <Map
              {...viewState}
              onMove={(e) => setViewState(e.viewState)}
              style={{ width: "100%", height: "100%" }}
              mapStyle={mapStyle}
              mapboxAccessToken={MAPBOX_TOKEN}
              attributionControl={false}
              onError={(e) => console.error("Map error:", e)}
            >
              <NavigationControl position="bottom-right" />
              <GeolocateControl position="bottom-right" trackUserLocation />
            </Map>
          )}
        </div>

        <Card
          style={{
            position: "absolute",
            top: 40,
            left: 40,
            zIndex: 50,
            width: 260,
            backgroundColor: "rgba(255,255,255,0.95)",
            backdropFilter: "blur(10px)",
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
            <div style={{ fontWeight: 700, fontSize: 16 }}>{displayName}</div>
            <div style={{ fontSize: 12, color: "#888" }}>{userEmail}</div>
          </div>
        </Card>

        <Space
          direction="vertical"
          style={{ position: "absolute", bottom: 40, right: 40, zIndex: 50 }}
        >
          <FloatButton
            icon={<HeatMapOutlined />}
            tooltip={<div>Harita Stilini Değiştir</div>}
            onClick={handleMapStyleChange}
          />
          <FloatButton
            icon={<CompassOutlined />}
            tooltip={<div>2D / 3D (şimdilik dummy)</div>}
            onClick={() => message.info("2D/3D sonra ekleyeceğiz")}
          />
          <FloatButton
            icon={<ReloadOutlined />}
            tooltip={<div>Haritayı Yeniden Ortala</div>}
            onClick={handleRecenter}
          />
        </Space>
      </Content>

      <Footer style={{ textAlign: "center", padding: "12px 50px", background: "#fff" }}>
        Vacanza App ©{new Date().getFullYear()}
      </Footer>
    </Layout>
  );
}
