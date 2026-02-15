import React from "react";
import { Spin, Alert, Typography, Row, Col, Button } from "antd";
import { useGamificationProfile } from "./useGamificationProfile";
import "./GamificationSummary.css";

const { Title, Text } = Typography;

const GamificationSummary = () => {
    const { data, isLoading, isError, error, refetch } = useGamificationProfile();

    if (isLoading) {
        return (
            <div className="gamification-page">
                <div className="gamification-loading">
                    <Spin size="large" />
                </div>
            </div>
        );
    }

    if (isError) {
        return (
            <div className="gamification-page">
                <Alert
                    type="error"
                    message={error?.message ?? error?.code ?? "—"}
                    description={error?.code ?? "—"}
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

    return (
        <div className="gamification-page">
            <div className="gamification-container">
                <Row gutter={[24, 24]}>
                    {/* LEFT COLUMN: Profile & Stats */}
                    <Col xs={24} md={8} lg={7}>
                        <div className="gamification-card profile-card">
                            {/* Header */}
                            <div className="gamification-header">
                                <Text className="role-text">
                                    {data?.roleText ?? "—"}
                                </Text>
                                <div className="level-text">
                                    {data?.levelText ?? "—"}
                                </div>
                            </div>

                            {/* Circular Progress */}
                            <div className="gamification-ring-wrap">
                                <div className="gamification-ring">
                                    <svg>
                                        <defs>
                                            <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="0%">
                                                <stop offset="0%" style={{ stopColor: "#4caf50", stopOpacity: 1 }} />
                                                <stop offset="100%" style={{ stopColor: "#8bc34a", stopOpacity: 1 }} />
                                            </linearGradient>
                                        </defs>
                                        <circle className="ring-bg" cx="85" cy="85" r="75" />
                                        <circle
                                            className="ring-progress"
                                            cx="85"
                                            cy="85"
                                            r="75"
                                            strokeDasharray="471"
                                            strokeDashoffset={471 - (471 * (data?.progressPercent ?? 0)) / 100}
                                        />
                                    </svg>
                                    <div className="gamification-ring-center">
                                        <div className="percent">{data?.progressPercent ?? 0}%</div>
                                        <div className="to-level">{data?.nextLevelText ?? "to next level"}</div>
                                        <div className="xp">{data?.currentXp ?? "0 XP"}</div>
                                    </div>
                                </div>
                            </div>

                            {/* Stats */}
                            {Array.isArray(data?.stats) && data.stats.length > 0 && (
                                <div className="gamification-stats">
                                    {data.stats.map((stat, index) => (
                                        <div key={index} className="stat-item">
                                            <div className="stat-value">{stat?.value ?? "—"}</div>
                                            <div className="stat-label">{stat?.label ?? "—"}</div>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </div>
                    </Col>

                    {/* RIGHT COLUMN: Badges */}
                    <Col xs={24} md={16} lg={17}>
                        {data?.badgesSectionTitle &&
                            Array.isArray(data?.badges) &&
                            data.badges.length > 0 && (
                                <div className="gamification-card badges-card">
                                    <Title level={4} className="badges-title">
                                        {data.badgesSectionTitle}
                                    </Title>
                                    <div className="gamification-badges">
                                        {data.badges.map((badge) => {
                                            if (!badge?.title) return null;
                                            const isLocked = badge.unlocked === false;

                                            return (
                                                <div
                                                    key={badge.id}
                                                    className={`badge-item ${isLocked ? "locked" : ""}`}
                                                >
                                                    <div
                                                        className={`badge-icon ${badge.color || "blue"}`}
                                                    >
                                                        {/* Icon placeholder or real icon based on key */}
                                                        {/* For now using empty div as requested */}
                                                    </div>
                                                    <div className="badge-title">{badge.title}</div>
                                                    <div className="badge-check">✓</div>
                                                </div>
                                            );
                                        })}
                                    </div>
                                </div>
                            )}
                    </Col>
                </Row>
            </div>
        </div>
    );
};

export default GamificationSummary;
