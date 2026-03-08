import React from "react";
import { Typography, Row, Col, Button, Spin, Alert } from "antd";
import { ArrowLeftOutlined, ExclamationCircleFilled } from "@ant-design/icons";
import { useNavigate } from "react-router-dom";
import { useGamificationProfile } from "./useGamificationProfile";
import "./GamificationSummary.css";

const { Title, Text } = Typography;

const GamificationSummary = () => {
    const navigate = useNavigate();
    const { data, isLoading, isError, error, refetch } = useGamificationProfile();

    // 1. Loading State (İstersen burayı daha sonra Skeleton ile değiştirebiliriz)
    if (isLoading) {
        return (
            <div className="gamification-page">
                <div className="gamification-loading">
                    <Spin size="large" tip="Yükleniyor..." />
                </div>
            </div>
        );
    }

    // 2. Error State & Retry (AC: Kullanıcıya anlaşılır hata ve yeniden dene butonu)
    if (isError) {
        return (
            <div className="gamification-page" style={{ minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center", padding: "20px" }}>
                <div className="gamification-card" style={{ maxWidth: 480, width: "100%", padding: "40px 24px", textAlign: "center", background: "#ffffff", border: "1px solid #e5e7eb", borderRadius: 12, boxShadow: "0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1)" }}>
                    <div style={{ marginBottom: 20 }}>
                        <div style={{ width: 64, height: 64, borderRadius: "50%", background: "#fee2e2", display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto" }}>
                            <ExclamationCircleFilled style={{ fontSize: 32, color: "#dc2626" }} />
                        </div>
                    </div>
                    <Title level={4} style={{ marginBottom: 8, color: "#111827", fontWeight: 600 }}>Connection Error</Title>
                    <Text style={{ color: "#4b5563", display: "block", marginBottom: 24, fontSize: 14, lineHeight: "1.5" }}>
                        We encountered an issue while retrieving your profile information. Please verify your connection and try again.
                        <br />
                        <span style={{ fontSize: 12, color: "#9ca3af", marginTop: 8, display: "inline-block" }}>Error Code: {error?.message || "ERR_CONNECTION_FAILED"}</span>
                    </Text>

                    <div style={{ display: "flex", gap: 12, justifyContent: "center" }}>
                        <Button
                            size="large"
                            onClick={() => navigate("/map")}
                            style={{ borderRadius: 6, fontWeight: 500 }}
                        >
                            Return to Map
                        </Button>
                        <Button
                            size="large"
                            type="primary"
                            onClick={() => refetch()}
                            style={{
                                borderRadius: 6,
                                fontWeight: 500,
                                background: "#4f46e5",
                                border: "none"
                            }}
                        >
                            Retry Connection
                        </Button>
                    </div>
                </div>
            </div>
        );
    }

    // Circular Progress Hesabı
    const strokeDasharray = 471;
    const progressPercent = data?.xpProgressPercent ?? 0;
    const offset = strokeDasharray - (strokeDasharray * progressPercent) / 100;

    return (
        <div className="gamification-page">
            <div className="gamification-container">
                <Button
                    type="text"
                    icon={<ArrowLeftOutlined />}
                    onClick={() => navigate("/map")}
                    style={{ marginBottom: 20, fontWeight: 600 }}
                >
                    Back to Map
                </Button>

                <Row gutter={[24, 24]}>
                    <Col xs={24} md={8} lg={7}>
                        <div className="gamification-card profile-card">
                            <div className="gamification-header">
                                <Text className="role-text">{data?.roleText ?? "TRAVELER"}</Text>
                                <div className="level-text">{data?.levelText ?? "Level 1"}</div>
                            </div>

                            <div className="gamification-ring-wrap">
                                <div className="gamification-ring">
                                    <svg>
                                        <defs>
                                            <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="0%">
                                                <stop offset="0%" style={{ stopColor: "#1890ff", stopOpacity: 1 }} />
                                                <stop offset="100%" style={{ stopColor: "#69c0ff", stopOpacity: 1 }} />
                                            </linearGradient>
                                        </defs>
                                        <circle className="ring-bg" cx="85" cy="85" r="75" />
                                        <circle
                                            className="ring-progress"
                                            cx="85" cy="85" r="75"
                                            strokeDasharray={strokeDasharray}
                                            strokeDashoffset={offset}
                                        />
                                    </svg>
                                    <div className="gamification-ring-center">
                                        <div className="percent">{progressPercent}%</div>
                                        <div className="to-level">next level</div>
                                        <div className="xp">{data?.totalXp ?? 0} XP</div>
                                    </div>
                                </div>
                            </div>

                            {/* --- STATS SECTION (Burası AC kriterlerini karşılıyor) --- */}
                            {Array.isArray(data?.stats) && data.stats.length > 0 && (
                                <div className="gamification-stats">
                                    {data.stats.map((stat, index) => (
                                        <div key={index} className="stat-item">
                                            {/* valueText veya value backend'den gelir, yoksa "—" */}
                                            <div className="stat-value">{stat?.valueText ?? stat?.value ?? "—"}</div>
                                            {/* label backend'den gelir */}
                                            <div className="stat-label">{stat?.label ?? "—"}</div>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </div>
                    </Col>

                    <Col xs={24} md={16} lg={17}>
                        <div className="gamification-card badges-card">
                            <Title level={4} className="badges-title">
                                {data?.badgesSectionTitle ?? "Achievement Badges"}
                            </Title>
                            <div className="gamification-badges">
                                {data?.badges?.map((badge) => {
                                    const isLocked = badge.earned === false;
                                    return (
                                        <div key={badge.id} className={`badge-item ${isLocked ? "locked" : ""}`}>
                                            <div className={`badge-icon ${badge.color || "blue"}`}>
                                                <span style={{ fontSize: '28px' }}>
                                                    {badge.key === 'speed' ? '⚡' :
                                                        badge.key === 'foodie' ? '🍴' :
                                                            badge.key === 'culture' ? '🏛️' :
                                                                badge.key === 'nature' ? '🌲' :
                                                                    badge.key === 'explorer' ? '🧭' : '📍'}
                                                </span>
                                            </div>
                                            <div className="badge-title">{badge.title}</div>
                                            {!isLocked && <div className="badge-check">✓ Earned</div>}
                                        </div>
                                    );
                                })}
                            </div>
                        </div>
                    </Col>
                </Row>
            </div>
        </div>
    );
};

export default GamificationSummary;