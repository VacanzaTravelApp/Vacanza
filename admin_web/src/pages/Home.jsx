import React, { useState, useEffect } from "react";
import { Card, Row, Col, Typography, Timeline, Progress, Button, Space, Tag, Spin, Badge } from "antd";
import {
    ThunderboltOutlined,
    CheckCircleFilled,
    RocketOutlined,
    LoadingOutlined,
    NotificationOutlined,
    BugFilled,
    WarningFilled,
    ArrowRightOutlined
} from "@ant-design/icons";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import http from "../api/http";
import dayjs from "dayjs";
import { useAuth } from "../context/useAuth";

const { Title, Text } = Typography;

// Brand Tokens from Web UI
const THEME = {
    navy: '#1A2332',
    coral: '#FF6B6B',
    teal: '#00B4D8',
    green: '#2DD4A8',
    amber: '#FFB347',
    subtext: '#5A6B7A'
};

export default function Home() {
    const navigate = useNavigate();
    const { user } = useAuth();
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

    if (loading && !data) return (
        <div style={{ height: '80vh', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
            <Spin indicator={<LoadingOutlined style={{ fontSize: 48, color: THEME.coral }} spin />} />
        </div>
    );

    const healthPercent = Math.round((data?.systemHealth || 0) * 100);
    const activeServices = data?.services?.filter(s => s.status === 'UP').length || 0;

    const stats = [
        { title: "System Health", value: `${healthPercent}%`, icon: <CheckCircleFilled />, color: THEME.green, desc: "Global Cluster Integrity" },
        { title: "Active Services", value: activeServices, icon: <RocketOutlined />, color: THEME.coral, desc: "Operational Nodes" },
        { title: "Live Traffic", value: data?.apiMetrics?.reduce((acc, curr) => acc + curr.totalCalls, 0) || 0, icon: <ThunderboltOutlined />, color: THEME.teal, desc: "Total API Ingress" }
    ];

    return (
        <div className="dashboard-container">
            <Row gutter={[48, 48]}>
                <Col span={24}>
                    <motion.div initial={{ opacity: 0, y: -20 }} animate={{ opacity: 1, y: 0 }}>
                        <Title level={4} style={{ color: THEME.coral, marginBottom: 8, letterSpacing: 2, textTransform: 'uppercase', fontSize: 13, fontWeight: 700 }}>
                            CONTROL CONSOLE ACTIVATED
                        </Title>
                        <Title className="gradient-text" style={{ fontSize: '64px', margin: '0 0 16px 0', lineHeight: 1.1, letterSpacing: '-1.5px' }}>
                            Welcome back, {user?.displayName || "Operator"}
                        </Title>
                        <Text style={{ fontSize: '20px', color: THEME.subtext, fontWeight: 500, maxWidth: 650, display: 'block' }}>
                            Your Vacanza administrative platform is synced and monitoring all global travel vectors.
                        </Text>
                    </motion.div>
                </Col>

                {stats.map((stat, i) => (
                    <Col xs={24} md={8} key={i}>
                        <motion.div
                            initial={{ opacity: 0, y: 30 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ delay: i * 0.1 }}
                        >
                            <Card className="glass-card" bordered={false} bodyStyle={{ padding: '40px' }}>
                                <div style={{ display: 'flex', alignItems: 'center', gap: '28px' }}>
                                    <div style={{
                                        width: 72,
                                        height: 72,
                                        background: `${stat.color}15`,
                                        borderRadius: '24px',
                                        color: stat.color,
                                        fontSize: '36px',
                                        display: 'flex',
                                        alignItems: 'center',
                                        justifyContent: 'center'
                                    }}>
                                        {stat.icon}
                                    </div>
                                    <div>
                                        <Text style={{ color: THEME.subtext, fontSize: 13, fontWeight: 700, textTransform: 'uppercase', letterSpacing: 1.5 }}>{stat.title}</Text>
                                        <div style={{ fontSize: '42px', fontWeight: 800, color: THEME.navy, lineHeight: 1.1 }}>{stat.value}</div>
                                        <Text style={{ fontSize: 12, color: THEME.green, fontWeight: 700 }}>Peak Optimization Active</Text>
                                    </div>
                                </div>
                            </Card>
                        </motion.div>
                    </Col>
                ))}

                <Col xs={24} lg={16}>
                    <Card
                        className="glass-card"
                        bordered={false}
                        title={<span style={{ fontSize: 22 }}>Infrastructure Radar</span>}
                        extra={<Button type="link" onClick={() => navigate('/monitoring')} style={{ color: THEME.coral, fontWeight: 700 }}>VIEW MATRIX</Button>}
                    >
                        <Row gutter={[20, 20]} style={{ marginTop: 12 }}>
                            {(data?.services || []).slice(0, 10).map((service, idx) => (
                                <Col xs={12} key={idx}>
                                    <div style={{
                                        padding: '24px',
                                        background: 'rgba(26, 35, 50, 0.03)',
                                        borderRadius: '20px',
                                        display: 'flex',
                                        justifyContent: 'space-between',
                                        alignItems: 'center',
                                        border: '1px solid rgba(26, 35, 50, 0.05)'
                                    }}>
                                        <Text strong style={{ color: THEME.navy, fontSize: 15 }}>{service.name}</Text>
                                        <Badge status={service.status === 'UP' ? 'success' : 'error'} text={<span style={{ fontWeight: 800 }}>{service.status}</span>} />
                                    </div>
                                </Col>
                            ))}
                        </Row>
                    </Card>
                </Col>

                <Col xs={24} lg={8}>
                    <Card className="glass-card" bordered={false} title={<span style={{ fontSize: 22 }}>Activity Stream</span>}>
                        <Timeline
                            mode="left"
                            items={(data?.logs || []).slice(0, 7).map((log, idx) => ({
                                color: log.level === 'ERROR' ? THEME.coral : log.level === 'WARN' ? THEME.amber : THEME.green,
                                icon: log.level === 'ERROR' ? <BugFilled /> : log.level === 'WARN' ? <WarningFilled /> : <CheckCircleFilled />,
                                children: (
                                    <div key={idx} style={{ marginBottom: 16 }}>
                                        <Text strong style={{ fontSize: 15, color: THEME.navy, display: 'block', lineHeight: 1.3 }}>{log.message}</Text>
                                        <Text style={{ fontSize: 12, color: THEME.subtext }}>
                                            {dayjs(log.timestamp).format('HH:mm:ss')} • <Tag style={{ fontSize: 10, margin: 0, padding: '0 6px', background: 'rgba(26, 35, 50, 0.06)', border: 'none' }}>{log.source}</Tag>
                                        </Text>
                                    </div>
                                )
                            }))}
                        />
                        {data?.logs?.length > 7 && (
                            <Button type="link" block onClick={() => navigate('/monitoring')} style={{ marginTop: 16, color: THEME.coral, fontWeight: 700 }}>
                                VIEW ALL EVENTS <ArrowRightOutlined />
                            </Button>
                        )}
                    </Card>
                </Col>
            </Row>
        </div>
    );
}
