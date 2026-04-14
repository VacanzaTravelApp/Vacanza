import React, { useState, useEffect } from "react";
import { Card, Row, Col, Statistic, Alert, Typography, Timeline, Progress, Button, Space, Tag, Spin } from "antd";
import {
    ThunderboltOutlined,
    SyncOutlined,
    ArrowRightOutlined,
    GlobalOutlined,
    SecurityScanOutlined,
    LineChartOutlined,
    CheckCircleFilled,
    HistoryOutlined,
    RocketOutlined,
    CloudServerOutlined,
    DatabaseOutlined,
    LoadingOutlined,
    NotificationOutlined,
    WarningFilled,
    BugFilled
} from "@ant-design/icons";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import VacanzaLogo from "../components/VacanzaLogo";
import http from "../api/http";
import dayjs from "dayjs";

const { Title, Paragraph, Text } = Typography;

const THEME = {
    primary: '#FF6B6B',
    success: '#2DD4A8',
    warning: '#FFB347',
    error: '#FF4D4F',
    info: '#00B4D8',
};

export default function Home() {
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
            style={{ padding: "12px" }}
        >
            {/* Status Alert */}
            <motion.div variants={item}>
                <Alert
                    title={
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
            <motion.div variants={item} style={{ marginBottom: 40 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 24, flexWrap: 'wrap' }}>
                    <div
                        onClick={() => window.location.reload()}
                        style={{
                            width: 56,
                            height: 56,
                            display: 'flex',
                            justifyContent: 'center',
                            alignItems: 'center',
                            cursor: 'pointer'
                        }}>
                        <VacanzaLogo size={56} showText={false} />
                    </div>
                    <div>
                        <Title level={1} style={{ margin: 0, letterSpacing: -1.2, fontWeight: 800 }}>Command Center</Title>
                        <Text type="secondary" style={{ fontSize: 16 }}>Real-time orchestration of user growth, system telemetry, and strategic assets.</Text>
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
                                    style={{ borderRadius: 20, height: '100%' }}
                                    bodyStyle={{ padding: '32px' }}
                                >
                                    <div style={{
                                        width: 48,
                                        height: 48,
                                        borderRadius: 12,
                                        background: `${THEME.warning}15`,
                                        color: THEME.warning,
                                        display: 'flex',
                                        justifyContent: 'center',
                                        alignItems: 'center',
                                        marginBottom: 24,
                                        fontSize: 24
                                    }}>
                                        <ThunderboltOutlined />
                                    </div>
                                    <Title level={3} style={{ margin: '0 0 12px' }}>System Matrix</Title>
                                    <Paragraph type="secondary" style={{ height: 48, fontSize: 14 }}>
                                        Real-time telemetry, provider node health, and granular performance metrics.
                                    </Paragraph>
                                    <div style={{ marginTop: 24, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                        <Button type="primary" style={{ background: THEME.warning, border: 'none', borderRadius: 8 }}>
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
                                    style={{ borderRadius: 20, height: '100%' }}
                                    bodyStyle={{ padding: '32px' }}
                                >
                                    <div style={{
                                        width: 48,
                                        height: 48,
                                        borderRadius: 12,
                                        background: `${THEME.primary}15`,
                                        color: THEME.primary,
                                        display: 'flex',
                                        justifyContent: 'center',
                                        alignItems: 'center',
                                        marginBottom: 24,
                                        fontSize: 24
                                    }}>
                                        <GlobalOutlined />
                                    </div>
                                    <Title level={3} style={{ margin: '0 0 12px' }}>Analytics Core</Title>
                                    <Paragraph type="secondary" style={{ height: 48, fontSize: 14 }}>
                                        Deep-dive behavioral patterns, revenue trajectory, and asset engagement ranking.
                                    </Paragraph>
                                    <div style={{ marginTop: 24, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                        <Button type="primary" style={{ background: THEME.primary, border: 'none', borderRadius: 8 }}>
                                            Open Insights
                                        </Button>
                                        <ArrowRightOutlined style={{ color: THEME.primary }} />
                                    </div>
                                </Card>
                            </motion.div>
                        </Col>
                    </Row>

                    <motion.div variants={item} style={{ marginTop: 24 }}>
                        <Card
                            title={<Space><RocketOutlined style={{ color: THEME.primary }} /> Operational Overview</Space>}
                            className="glass-card"
                            bordered={false}
                            bodyStyle={{ padding: '32px' }}
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
                                    <Text type="secondary" size="small">Computed reliability across all {data?.services?.length || 0} active provider nodes.</Text>
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
                                    <Text type="secondary" size="small">Global average inter-service communication stable.</Text>
                                </Col>
                            </Row>
                        </Card>
                    </motion.div>
                </Col>

                <Col xs={24} lg={8}>
                    <motion.div variants={item} style={{ height: '100%' }}>
                        <Card
                            title={<Space><NotificationOutlined style={{ color: THEME.primary }} /> Recent System Events</Space>}
                            className="glass-card"
                            bordered={false}
                            style={{ height: '100%' }}
                            bodyStyle={{ padding: '24px 24px 32px' }}
                        >
                            <Timeline
                                mode="start"
                                style={{ marginTop: 12 }}
                                items={data?.logs?.slice(0, 5).map((log, idx) => ({
                                    color: log.level === 'ERROR' ? THEME.error : log.level === 'WARN' ? THEME.warning : THEME.success,
                                    icon: log.level === 'ERROR' ? <BugFilled style={{ fontSize: 14 }} /> :
                                        log.level === 'WARN' ? <WarningFilled style={{ fontSize: 14 }} /> :
                                            <CheckCircleFilled style={{ fontSize: 14 }} />,
                                    content: (
                                        <div style={{ marginBottom: 16 }}>
                                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                                                <Text strong style={{ fontSize: 13, display: 'block' }}>{log.message}</Text>
                                            </div>
                                            <Tag bordered={false} style={{ marginTop: 6, fontSize: 10, background: 'rgba(0,0,0,0.03)' }}>
                                                {dayjs(log.timestamp).format('HH:mm:ss')}
                                            </Tag>
                                        </div>
                                    )
                                })) || [
                                        { color: 'gray', content: <Text type="secondary">Waiting for events...</Text> }
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
            </Row>
        </motion.div>
    );
}
