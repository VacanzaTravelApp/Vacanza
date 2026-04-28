import React, { useState, useEffect } from "react";
import { Card, Row, Col, Statistic, Alert, Typography, Timeline, Progress, Button, Space, Tag, Spin, Grid } from "antd";
import {
    ThunderboltOutlined, SyncOutlined, ArrowRightOutlined, GlobalOutlined, SecurityScanOutlined,
    LineChartOutlined, CheckCircleFilled, HistoryOutlined, RocketOutlined, CloudServerOutlined,
    DatabaseOutlined, LoadingOutlined, NotificationOutlined, WarningFilled, BugFilled
} from "@ant-design/icons";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import http from "../api/http";
import dayjs from "dayjs";

const { Title, Paragraph, Text } = Typography;
const { useBreakpoint } = Grid;

const THEME = {
    primary: '#FF6B6B',
    success: '#2DD4A8',
    warning: '#FFB347',
    error: '#FF4D4F',
    info: '#00B4D8',
};

export default function Home() {
    const screens = useBreakpoint();
    const isMobile = !screens.md;
    const navigate = useNavigate();
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchData = async () => {
            try {
                const response = await http.get("/admin/monitoring");
                setData(response.data);
            } catch (err) {
                console.error("Home fetch error:", err);
            } finally {
                setLoading(false);
            }
        };
        fetchData();
        const interval = setInterval(fetchData, 60000);
        return () => clearInterval(interval);
    }, []);

    const container = {
        hidden: { opacity: 0 },
        show: {
            opacity: 1,
            transition: {
                staggerChildren: 0.1
            }
        }
    };

    const item = {
        hidden: { y: 20, opacity: 0 },
        show: { y: 0, opacity: 1 }
    };

    if (loading && !data) return (
        <div style={{ height: '80vh', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
            <Spin indicator={<LoadingOutlined style={{ fontSize: 40, color: THEME.primary }} spin />} />
        </div>
    );

    const healthPercent = Math.round((data?.systemHealth || 0) * 100);
    const avgLatency = data?.apiMetrics?.length > 0
        ? Math.round(data.apiMetrics.reduce((acc, curr) => acc + curr.avgResponseMs, 0) / data.apiMetrics.length)
        : 0;

    return (
        <motion.div
            variants={container}
            initial="hidden"
            animate="show"
            className="dashboard-container"
            style={{ padding: isMobile ? "12px 0 0" : "12px 0" }}
        >
            {/* Status Alert */}
            <motion.div variants={item}>
                <Alert
                    message={
                        <Space>
                            {healthPercent > 90 ? <CheckCircleFilled style={{ color: THEME.success }} /> : <WarningFilled style={{ color: THEME.warning }} />}
                            <Text strong style={{ color: healthPercent > 90 ? '#065f46' : '#92400e' }}>
                                {healthPercent > 90 ? 'ADMINISTRATIVE OVERRIDE: ALL SYSTEMS OPERATIONAL' : 'SYSTEM ALERT: PERFORMANCE DEGRADATION DETECTED'}
                            </Text>
                        </Space>
                    }
                    description={
                        <Text style={{ color: healthPercent > 90 ? '#065f46' : '#92400e', opacity: 0.8 }}>
                            {healthPercent > 90
                                ? `System integrity validated at ${healthPercent}%. Global performance audit completed successfully.`
                                : `Health index dropped to ${healthPercent}%. Some nodes are reporting latency spikes.`
                            }
                        </Text>
                    }
                    type={healthPercent > 90 ? "success" : "warning"}
                    showIcon={false}
                    closable
                    style={{
                        marginBottom: "32px",
                        borderRadius: '16px',
                        background: healthPercent > 90 ? 'hsla(142, 70%, 45%, 0.1)' : 'hsla(38, 92%, 50%, 0.1)',
                        border: `1px solid ${healthPercent > 90 ? 'hsla(142, 70%, 45%, 0.2)' : 'hsla(38, 92%, 50%, 0.2)'}`
                    }}
                />
            </motion.div>

            {/* Welcome Header */}
            <motion.div variants={item} style={{ marginBottom: isMobile ? 28 : 40, marginTop: isMobile ? 8 : 20 }}>
                <div style={{ display: 'flex', alignItems: isMobile ? 'flex-start' : 'center', gap: isMobile ? 16 : 24, flexWrap: 'wrap' }}>
                    <div
                        onClick={() => window.location.reload()}
                        style={{
                            width: isMobile ? 88 : 120,
                            height: isMobile ? 88 : 120,
                            display: 'flex',
                            justifyContent: 'center',
                            alignItems: 'center',
                            cursor: 'pointer'
                        }}>
                        <img src="/logo.svg" alt="Logo" style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
                    </div>
                    <div style={{ minWidth: 0, flex: 1 }}>
                        <Title
                            className="gradient-text"
                            style={{
                                margin: 0,
                                letterSpacing: -1.5,
                                fontWeight: 900,
                                fontSize: isMobile ? '30px' : '36px',
                                fontFamily: "'Fraunces', serif"
                            }}
                        >
                            Command Center
                        </Title>
                        <Text
                            style={{
                                fontSize: isMobile ? '15px' : '18px',
                                color: '#5A6B7A',
                                fontWeight: 500,
                                fontFamily: "'DM Sans', sans-serif",
                                display: 'block'
                            }}
                        >
                            Overview of system health, active users, and application performance.
                        </Text>
                    </div>
                </div>
            </motion.div>

            <Row gutter={[24, 24]}>
                <Col xs={24} lg={16}>
                    <Row gutter={[24, 24]}>
                        <Col xs={24} sm={12}>
                            <motion.div variants={item} whileHover={{ y: -8 }} transition={{ type: 'spring', stiffness: 300 }}>
                                <Card
                                    hoverable
                                    className="glass-card"
                                    onClick={() => navigate('/monitoring')}
                                    style={{ borderRadius: 24, height: '100%', border: '1px solid rgba(26, 35, 50, 0.08)' }}
                                    styles={{ body: { padding: isMobile ? '24px' : '36px' } }}
                                >
                                    <div style={{
                                        width: 52,
                                        height: 52,
                                        borderRadius: 14,
                                        background: `${THEME.warning}15`,
                                        color: THEME.warning,
                                        display: 'flex',
                                        justifyContent: 'center',
                                        alignItems: 'center',
                                        marginBottom: 28,
                                        fontSize: 26
                                    }}>
                                        <ThunderboltOutlined />
                                    </div>
                                    <Title
                                        level={3}
                                        style={{
                                            margin: '0 0 14px',
                                            fontFamily: "'Fraunces', serif",
                                            fontWeight: 800,
                                            fontSize: '24px'
                                        }}
                                    >
                                        System Matrix
                                    </Title>
                                    <Paragraph
                                        style={{
                                            minHeight: isMobile ? 'auto' : 52,
                                            fontSize: '15px',
                                            color: '#5A6B7A',
                                            fontFamily: "'DM Sans', sans-serif"
                                        }}
                                    >
                                        Monitor the performance and health of the required APIs and external services.
                                    </Paragraph>
                                    <div style={{ marginTop: 28, display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12, flexWrap: 'wrap' }}>
                                        <Button type="primary" style={{ background: THEME.warning, border: 'none', borderRadius: 10, fontWeight: 700, height: '40px', minWidth: isMobile ? '100%' : 'auto' }}>
                                            Launch Console
                                        </Button>
                                        <ArrowRightOutlined style={{ color: THEME.warning }} />
                                    </div>
                                </Card>
                            </motion.div>
                        </Col>

                        <Col xs={24} sm={12}>
                            <motion.div variants={item} whileHover={{ y: -8 }} transition={{ type: 'spring', stiffness: 300 }}>
                                <Card
                                    hoverable
                                    className="glass-card"
                                    onClick={() => navigate('/analytics')}
                                    style={{ borderRadius: 24, height: '100%', border: '1px solid rgba(26, 35, 50, 0.08)' }}
                                    bodyStyle={{ padding: isMobile ? '24px' : '36px' }}
                                >
                                    <div style={{
                                        width: 52,
                                        height: 52,
                                        borderRadius: 14,
                                        background: `${THEME.primary}15`,
                                        color: THEME.primary,
                                        display: 'flex',
                                        justifyContent: 'center',
                                        alignItems: 'center',
                                        marginBottom: 28,
                                        fontSize: 26
                                    }}>
                                        <GlobalOutlined />
                                    </div>
                                    <Title
                                        level={3}
                                        style={{
                                            margin: '0 0 14px',
                                            fontFamily: "'Fraunces', serif",
                                            fontWeight: 800,
                                            fontSize: '24px'
                                        }}
                                    >
                                        Analytics Core
                                    </Title>
                                    <Paragraph
                                        style={{
                                            minHeight: isMobile ? 'auto' : 52,
                                            fontSize: '15px',
                                            color: '#5A6B7A',
                                            fontFamily: "'DM Sans', sans-serif"
                                        }}
                                    >
                                        Review new user registrations and track the overall growth of the platform.
                                    </Paragraph>
                                    <div style={{ marginTop: 28, display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12, flexWrap: 'wrap' }}>
                                        <Button type="primary" style={{ background: THEME.primary, border: 'none', borderRadius: 10, fontWeight: 700, height: '40px', minWidth: isMobile ? '100%' : 'auto' }}>
                                            Open Insights
                                        </Button>
                                        <ArrowRightOutlined style={{ color: THEME.primary }} />
                                    </div>
                                </Card>
                            </motion.div>
                        </Col>
                    </Row >

                    <motion.div variants={item} style={{ marginTop: 24 }}>
                        <Card
                            title={
                                <Space>
                                    <RocketOutlined style={{ color: THEME.primary }} />
                                    <span style={{ fontFamily: "'Fraunces', serif", fontWeight: 800 }}>Operational Overview</span>
                                </Space>
                            }
                            className="glass-card dashboard-section-card"
                            variant="borderless"
                            styles={{ body: { padding: isMobile ? '24px' : '36px' } }}
                        >
                            <Row gutter={[32, 24]}>
                                <Col xs={24} sm={12}>
                                    <div style={{ marginBottom: 20 }}>
                                        <Statistic
                                            title={<Text type="secondary" style={{ fontSize: 13, textTransform: 'uppercase', letterSpacing: 1 }}>Global Service Health</Text>}
                                            value={healthPercent}
                                            suffix="%"
                                            valueStyle={{ fontWeight: 800, color: healthPercent > 90 ? THEME.success : THEME.warning }}
                                        />
                                        <Progress percent={healthPercent} size="small" strokeColor={healthPercent > 90 ? THEME.success : THEME.warning} showInfo={false} style={{ marginTop: 8 }} />
                                    </div>
                                    <Text type="secondary" style={{ fontSize: 12 }}>Computed reliability across all {data?.services?.length || 0} active provider nodes.</Text>
                                </Col>
                                <Col xs={24} sm={12}>
                                    <div style={{ marginBottom: 20 }}>
                                        <Statistic
                                            title={<Text type="secondary" style={{ fontSize: 13, textTransform: 'uppercase', letterSpacing: 1 }}>Average Latency</Text>}
                                            value={avgLatency}
                                            suffix="ms"
                                            valueStyle={{ fontWeight: 800, color: avgLatency < 200 ? THEME.success : THEME.primary }}
                                        />
                                        <Progress percent={Math.min(100, (avgLatency / 1000) * 100)} strokeColor={avgLatency < 200 ? THEME.success : THEME.primary} size="small" showInfo={false} style={{ marginTop: 8 }} />
                                    </div>
                                    <Text type="secondary" style={{ fontSize: 12 }}>Global average inter-service communication stable.</Text>
                                </Col>
                            </Row>
                        </Card>
                    </motion.div>
                </Col >

                <Col xs={24} lg={8}>
                    <motion.div variants={item} style={{ height: '100%' }}>
                        <Card
                            title={<Space><NotificationOutlined style={{ color: THEME.primary }} /> Recent System Events</Space>}
                            className="glass-card dashboard-section-card"
                            variant="borderless"
                            style={{ height: '100%' }}
                            bodyStyle={{ padding: isMobile ? '20px 16px 24px' : '24px 24px 32px' }}
                        >
                            <Timeline
                                style={{ marginTop: 12 }}
                                items={data?.logs?.slice(0, 5).map((log, idx) => ({
                                    color: log.level === 'ERROR' ? THEME.error : log.level === 'WARN' ? THEME.warning : THEME.success,
                                    dot: log.level === 'ERROR' ? <BugFilled style={{ fontSize: 14 }} /> :
                                        log.level === 'WARN' ? <WarningFilled style={{ fontSize: 14 }} /> :
                                            <CheckCircleFilled style={{ fontSize: 14 }} />,
                                    children: (
                                        <div style={{ marginBottom: 16 }}>
                                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 12 }}>
                                                <Text strong style={{ fontSize: 13, display: 'block' }}>{log.message}</Text>
                                            </div>
                                            <Tag bordered={false} style={{ marginTop: 6, fontSize: 10, background: 'rgba(0,0,0,0.03)' }}>
                                                {dayjs(log.timestamp).format('HH:mm:ss')} • {log.source}
                                            </Tag>
                                        </div>
                                    )
                                })) || [
                                        { color: 'gray', children: <Text type="secondary">Waiting for events...</Text> }
                                    ]}
                            />
                            {data?.logs?.length > 5 && (
                                <Button
                                    type="link"
                                    onClick={() => navigate('/monitoring')}
                                    style={{ padding: 0, marginTop: 8, fontSize: 12 }}
                                >
                                    View all activity <ArrowRightOutlined style={{ fontSize: 10 }} />
                                </Button>
                            )}
                        </Card>
                    </motion.div>
                </Col>
            </Row >
        </motion.div >
    );
}
