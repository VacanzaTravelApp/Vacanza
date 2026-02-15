import React from "react";
import { Spin, Alert, Typography, Row, Col, Button } from "antd";
import { ArrowLeftOutlined } from "@ant-design/icons";
import { useNavigate } from "react-router-dom";
import { useGamificationProfile } from "./useGamificationProfile";
import "./GamificationSummary.css";

const { Title, Text } = Typography;

const GamificationSummary = () => {
    const navigate = useNavigate();
    const { data, isLoading, isError, error, refetch } = useGamificationProfile();

    if (isLoading) {
        return (
            <div className="gamification-page">
                <div className="gamification-loading">
                    <Spin size="large" tip="Loading profile..." />
                </div>
            </div>
        );
    }

    if (isError) {
        return (
            <div className="gamification-page">
                <Alert
                    type="error"
                    message="Data Loading Error"
                    description={error?.message || "Something went wrong while fetching data."}
                    showIcon
                    action={
                        <Button size="small" onClick={() => refetch()}>
                            Retry
                        </Button>
                    }
                />
            </div>
        );
    }

    // Circular Progress Calculation (r=75 circumference ≈ 471)
    const strokeDasharray = 471;
    const progressPercent = data?.xpProgressPercent ?? 0;
    const offset = strokeDasharray - (strokeDasharray * progressPercent) / 100;

    return (
        <div className="gamification-page">
            <div className="gamification-container">
                {/* Back to Map Button */}
                <Button 
                    type="text" 
                    icon={<ArrowLeftOutlined />} 
                    onClick={() => navigate("/map")} 
                    style={{ marginBottom: 20, fontWeight: 600 }}
                >
                    Back to Map
                </Button>

                <Row gutter={[24, 24]}>
                    {/* LEFT COLUMN: Profile Summary */}
                    <Col xs={24} md={8} lg={7}>
                        <div className="gamification-card profile-card">
                            <div className="gamification-header">
                                <Text className="role-text">
                                    {data?.roleText ?? "TRAVELER"}
                                </Text>
                                <div className="level-text">
                                    {data?.levelText ?? "Level 1"}
                                </div>
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
                                            cx="85"
                                            cy="85"
                                            r="75"
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

                            {/* Stats Section */}
                            {Array.isArray(data?.stats) && (
                                <div className="gamification-stats">
                                    {data.stats.map((stat, index) => (
                                        <div key={index} className="stat-item">
                                            <div className="stat-value">{stat?.value ?? 0}</div>
                                            <div className="stat-label">{stat?.label ?? "—"}</div>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </div>
                    </Col>

                    {/* RIGHT COLUMN: Badges */}
                    <Col xs={24} md={16} lg={17}>
                        <div className="gamification-card badges-card">
                            <Title level={4} className="badges-title">
                                {data?.badgesSectionTitle ?? "Achievement Badges"}
                            </Title>
                            <div className="gamification-badges">
                                {data?.badges?.map((badge) => {
                                    const isLocked = badge.earned === false;

                                    return (
                                        <div
                                            key={badge.id}
                                            className={`badge-item ${isLocked ? "locked" : ""}`}
                                        >
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