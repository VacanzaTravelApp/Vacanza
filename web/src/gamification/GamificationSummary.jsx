import React from "react";
import { Typography, Row, Col, Button, Spin, Alert } from "antd";
import { ArrowLeftOutlined } from "@ant-design/icons";
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
            <div className="gamification-page" style={{ padding: '20px' }}>
                <Alert
                    type="error"
                    message="Veri Yükleme Hatası"
                    description={error?.message || "Backend bağlantısı sağlanamadı."}
                    showIcon
                    action={
                        <Button size="small" type="primary" onClick={() => refetch()}>
                            Yeniden Dene
                        </Button>
                    }
                />
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