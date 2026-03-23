import React from "react";
import { Card, Row, Col, Statistic, Alert, Typography, Timeline, Progress, Button, Spin, Space } from "antd";
import {
    SmileOutlined,
    ThunderboltOutlined,
    MessageOutlined,
    SyncOutlined,
    BellOutlined,
    ArrowRightOutlined,
    RocketOutlined,
    SecurityScanOutlined,
    LineChartOutlined,
    UserOutlined,
    TeamOutlined
} from "@ant-design/icons";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { MdFlightTakeoff } from "react-icons/md";
import { useQuery } from "@tanstack/react-query";
import { adminApi } from "../api/userApi";

const { Title, Paragraph, Text } = Typography;

export default function Home() {
    const navigate = useNavigate();

    const { data: monitoring, isLoading: isMonLoading } = useQuery({
        queryKey: ['admin-monitoring'],
        queryFn: async () => {
            const res = await adminApi.getSystemMonitoring();
            return res.data;
        },
        refetchInterval: 15000
    });

    const { data: analytics, isLoading: isAnaLoading } = useQuery({
        queryKey: ['admin-analytics'],
        queryFn: async () => {
            const res = await adminApi.getAnalytics({});
            return res.data;
        },
        refetchInterval: 30000
    });

    const getTimelineColor = (level) => {
        switch (level) {
            case 'ERROR': return 'red';
            case 'WARN': return 'gold';
            case 'INFO': return 'blue';
            default: return 'green';
        }
    };

    return (
        <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.8 }}
            style={{ padding: "12px" }}
        >
            <Alert
                title={<Text strong>{monitoring?.systemHealth === 1 ? "System Health Check: ALL SYSTEMS OPERATIONAL" : "System Health Check: SUB-OPTIMAL PERFOMANCE"}</Text>}
                description={`Last verified performance audit was completed recently. System Health Index: ${(monitoring?.systemHealth || 0) * 100}%`}
                type={monitoring?.systemHealth === 1.0 ? "success" : "warning"}
                showIcon
                closable
                style={{ marginBottom: "24px", borderRadius: 8 }}
            />

            <div style={{ marginBottom: 32 }}>
                <Title level={2}><MdFlightTakeoff style={{ color: '#1677ff', marginRight: 8 }} /> Vacanza Admin Dashboard</Title>
                <Paragraph type="secondary">Real-time control center for user management, system diagnostics, and strategic analytics.</Paragraph>
            </div>

            <Row gutter={[24, 24]}>
                <Col xs={24} lg={16}>
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: 24 }}>
                        <Card
                            hoverable
                            className="action-card"
                            onClick={() => navigate('/monitoring')}
                            style={{ borderLeft: '4px solid #faad14', borderRadius: 12 }}
                            cover={
                                <div style={{ padding: '24px 24px 0', fontSize: 32, color: '#faad14' }}>
                                    <SecurityScanOutlined />
                                </div>
                            }
                        >
                            <Title level={4}>UC2.1: Monitoring</Title>
                            <Text type="secondary">Live API latency, database status, and health metrics.</Text>
                            <div style={{ marginTop: 16 }}>
                                <Button type="link" style={{ padding: 0 }}>Launch Monitor <ArrowRightOutlined /></Button>
                            </div>
                        </Card>

                        <Card
                            hoverable
                            className="action-card"
                            onClick={() => navigate('/analytics')}
                            style={{ borderLeft: '4px solid #1677ff', borderRadius: 12 }}
                            cover={
                                <div style={{ padding: '24px 24px 0', fontSize: 32, color: '#1677ff' }}>
                                    <LineChartOutlined />
                                </div>
                            }
                        >
                            <Title level={4}>UC2.2: Analytics</Title>
                            <Text type="secondary">Generate comprehensive reports on user growth and POI engagement.</Text>
                            <div style={{ marginTop: 16 }}>
                                <Button type="link" style={{ padding: 0 }}>View Reports <ArrowRightOutlined /></Button>
                            </div>
                        </Card>
                    </div>

                    <Card title="Engagement Overview (Live)" style={{ marginTop: 24, borderRadius: 12 }} variant="borderless" loading={isAnaLoading}>
                        <Row gutter={16}>
                            <Col xs={24} sm={12}>
                                <Statistic title="Total Users" value={analytics?.totalUsers} prefix={<TeamOutlined />} styles={{ content: { color: '#52c41a' } }} />
                            </Col>
                            <Col xs={24} sm={12}>
                                <Statistic title="Active Sessions" value={analytics?.activeSessions} prefix={<UserOutlined />} styles={{ content: { color: '#1677ff' } }} />
                            </Col>
                        </Row>
                        <Row gutter={16} style={{ marginTop: 24 }}>
                            <Col xs={24} sm={12}>
                                <Statistic title="Total Check-ins" value={analytics?.totalCheckins} styles={{ content: { color: '#faad14' } }} />
                            </Col>
                        </Row>
                    </Card>
                </Col>

                <Col xs={24} lg={8}>
                    <Card title="System Timeline" style={{ borderRadius: 12, height: '100%' }} variant="borderless" loading={isMonLoading}>
                        {monitoring?.logs?.length > 0 ? (
                            <Timeline
                                items={monitoring.logs.slice(0, 5).map((log, idx) => ({
                                    color: getTimelineColor(log.level),
                                    content: (
                                        <>
                                            <Text strong>{log.source || 'SYSTEM'}</Text>
                                            <p style={{ fontSize: 13 }}>{log.message}</p>
                                            <p style={{ fontSize: 11, color: 'gray', margin: 0 }}>{new Date(log.timestamp).toLocaleString()}</p>
                                        </>
                                    )
                                }))}
                            />
                        ) : (
                            <Text type="secondary">No recent logs.</Text>
                        )}
                    </Card>
                </Col>
            </Row>
        </motion.div>
    );
}
