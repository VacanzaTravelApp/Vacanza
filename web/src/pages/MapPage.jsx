
import React, { useEffect, useMemo, useRef, useState } from "react";
import { Layout, Button, Card, Avatar, Space, message } from "antd";
import {
  LogoutOutlined,
  UserOutlined,
  GlobalOutlined,
  CompassOutlined,
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
  bearing: 0,
  pitch: 0, // 2D default
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
  const mapRef = useRef(null);

  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  const [viewState, setViewState] = useState(INITIAL_VIEW_STATE);
  
  // 2D / 3 UI state
  const [styleIndex, setStyleIndex] = useState(1);
  const [is3D, setIs3D] = useState(false);

  // ✅ NEW: Profile dropdown open/close
  const [profileOpen, setProfileOpen] = useState(false);

  const MAPBOX_TOKEN = import.meta.env.VITE_MAPBOX_ACCESS_TOKEN;
  const mapStyle = useMemo(() => STYLES[styleIndex], [styleIndex]);

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, (currentUser) => {
      if (!currentUser) {
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

  const handleMapStyleChange = () =>
    setStyleIndex((prev) => (prev + 1) % STYLES.length);

  const handleToggle2D3D = () => {
    const nextIs3D = !is3D;
    setIs3D(nextIs3D);

    const nextPitch = nextIs3D ? 60 : 0;

    // Smooth camera transition
    try {
      const map = mapRef.current?.getMap?.();
      if (map) {
        map.easeTo({
          pitch: nextPitch,
          bearing: 0,
          duration: 650,
        });
      }
    } catch (e) {
      console.error("2D/3D easeTo error:", e);
    }

    // Keep React state in sync (important for controlled Map)
    setViewState((prev) => ({
      ...prev,
      pitch: nextPitch,
      bearing: 0,
    }));
  };

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

  // ✅ Mock data (Sprint requirement)
  const MOCK_PREFERRED_NAME = "alcaydamla";
  const MOCK_TRAVEL_STYLE = "Explorer / Budget";

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
          <GlobalOutlined
            style={{ fontSize: 24, color: "#1890ff", marginRight: 10 }}
          />
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
            position: "relative",
          }}
        >
          {!MAPBOX_TOKEN ? (
            <div style={{ height: "100%", display: "grid", placeItems: "center" }}>
            </div>
          ) : (
            <Map
              ref={mapRef}
              {...viewState}
              onMove={(e) => setViewState(e.viewState)}
              style={{ width: "100%", height: "100%" }}
              mapStyle={mapStyle}
              mapboxAccessToken={MAPBOX_TOKEN}
              attributionControl={false}
              onError={(e) => console.error("Map error:", e)}
            >

              <NavigationControl position="bottom-right" showCompass={false} />
              <GeolocateControl position="bottom-right" trackUserLocation />
            </Map>
          )}

          <div
            style={{
              position: "absolute",
              top: 18,
              right: 18,
              zIndex: 60,
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              gap: 10,
            }}
          >
            <button
              type="button"
              onClick={handleToggle2D3D}
              style={{
                width: 48,
                height: 48,
                borderRadius: "999px",
                border: is3D ? "2px solid #1890ff" : "1px solid #e5e7eb",
                background: "#fff",
                boxShadow: "0 8px 20px rgba(0,0,0,0.08)",
                display: "grid",
                placeItems: "center",
                cursor: "pointer",
              }}
              aria-label="2D / 3D Toggle"
              title="2D / 3D"
            >
              <CompassOutlined
                style={{ fontSize: 20, color: is3D ? "#1890ff" : "#555" }}
              />
            </button>

            <div
              style={{
                fontSize: 12,
                fontWeight: 700,
                padding: "4px 10px",
                borderRadius: 999,
                background: "#fff",
                border: is3D ? "1px solid #1890ff" : "1px solid #e5e7eb",
                color: is3D ? "#1890ff" : "#444",
                boxShadow: "0 8px 20px rgba(0,0,0,0.06)",
                lineHeight: "12px",
              }}
            >
              {is3D ? "3D" : "2D"}
            </div>
            <Button
              shape="circle"
              icon={<HeatMapOutlined />}
              onClick={handleMapStyleChange}
              style={{
                width: 48,
                height: 48,
                background: "#fff",
                boxShadow: "0 8px 20px rgba(0,0,0,0.08)",
                border: "1px solid #e5e7eb",
              }}
              title="Harita Stilini Değiştir"
            />
          </div>

          <Card
            style={{
              position: "absolute",
              top: 40,
              left: 40,
              zIndex: 50,
              width: 280,
              backgroundColor: "rgba(255,255,255,0.95)",
              backdropFilter: "blur(10px)",
              borderRadius: 16,
            }}
            bodyStyle={{ padding: 16 }}
          >
            <div
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                gap: 12,
              }}
            >
              <div style={{ display: "flex", alignItems: "center" }}>
                <Avatar
                  size={48}
                  icon={<UserOutlined />}
                  src={user.photoURL}
                  style={{ marginRight: 12, backgroundColor: "#1890ff" }}
                />
                <div>
                  <div style={{ fontWeight: 700, fontSize: 16 }}>{displayName}</div>
                  <div style={{ fontSize: 12, color: "#888" }}>{userEmail}</div>
                </div>
              </div>

              {/* only arrow clickable */}
           <button
  type="button"
  onClick={() => setProfileOpen((p) => !p)}
  style={{
    background: "transparent",
    border: "none",
    cursor: "pointer",
    padding: 4,
    display: "flex",
    alignItems: "center",
  }}
  aria-label="Open profile info"
>

                <span
                  style={{
                    display: "inline-block",
                    transform: profileOpen ? "rotate(180deg)" : "rotate(0deg)",
                    transition: "0.2s",
                    fontSize: 18,
                    lineHeight: "18px",
              color: "#1890ff", // 👈 MAVİ (Ant Design blue)
                  }}
                >
                  ⌄
                </span>
              </button>
            </div>

            {profileOpen && (
              <div
                style={{
                  marginTop: 12,
                  paddingTop: 12,
                  borderTop: "1px solid #f0f0f0",
                  fontSize: 13,
                  color: "#555",
                }}
              >
                <div style={{ marginBottom: 6 }}>
                  <b>Preferred name:</b> {MOCK_PREFERRED_NAME}
                </div>
                <div style={{ marginBottom: 10 }}>
                  <b>Travel style:</b> {MOCK_TRAVEL_STYLE}
                </div>

                <Button
                  type="link"
                  style={{ padding: 0, height: "auto" }}
                  onClick={() => navigate("/profile-details")}
                >
                  View details →
                </Button>
              </div>
            )}
          </Card>
        </div>
      </Content>

      <Footer style={{ textAlign: "center", padding: "12px 50px", background: "#fff" }}>
        Vacanza App ©{new Date().getFullYear()}
      </Footer>
    </Layout>
  );
}
