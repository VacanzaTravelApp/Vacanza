import React from "react";
import { Card, Row, Col, Statistic, Alert, Typography, Timeline, Progress, Button, Space } from "antd";
import {
    SmileOutlined,
    ThunderboltOutlined,
    MessageOutlined,
    SyncOutlined,
    BellOutlined,
    ArrowRightOutlined,
    RocketOutlined,
    SecurityScanOutlined,
    LineChartOutlined
} from "@ant-design/icons";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { MdFlightTakeoff } from "react-icons/md";

const { Title, Paragraph, Text } = Typography;

export default function Home() {
    const navigate = useNavigate();

    return (
        <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.8 }}
            style={{ padding: "12px" }}
        >

            <div style={{ marginBottom: 32 }}>
                <Title level={2}><MdFlightTakeoff style={{ color: '#1677ff', marginRight: 8 }} /> Vacanza Admin Dashboard</Title>
                <Paragraph type="secondary">Real-time control center for user management, system diagnostics, and strategic analytics.</Paragraph>
            </div>

            <Row gutter={[24, 24]}>
                <Col xs={24} lg={16}>
                    <Row gutter={[24, 24]}>
                        <Col xs={24} md={12}>
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
                        </Col>
                        <Col xs={24} md={12}>
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
                        </Col>
                    </Row>

                    <Card title="Engagement Overview" style={{ marginTop: 24, borderRadius: 12 }} variant="borderless">
                        <Row gutter={[16, 16]}>
                            <Col xs={12} sm={12}>
                                <Statistic title="Session Retention" value={92} suffix="%" styles={{ content: { color: '#52c41a' } }} />
                                <div style={{ marginTop: 12 }}>
                                    <Progress percent={92} size="small" strokeColor="#52c41a" />
                                </div>
                            </Col>
                            <Col xs={12} sm={12}>
                                <Statistic title="Peak Concurrency" value={8420} styles={{ content: { color: '#1677ff' } }} />
                                <div style={{ marginTop: 12 }}>
                                    <Progress percent={64} size="small" status="active" />
                                </div>
                            </Col>
                        </Row>
                    </Card>
                </Col>

                <Col xs={24} lg={8}>
                    <Card title="System Timeline" style={{ borderRadius: 12, height: '100%' }} variant="borderless">
                        <Timeline
                            items={[
                                {
                                    color: 'green',
                                    content: (
                                        <>
                                            <Text strong>UC2.1 Monitoring Active</Text>
                                            <p style={{ fontSize: 12, color: 'gray' }}>Continuous health check enabled at 09:00 AM</p>
                                        </>
                                    ),
                                },
                                {
                                    color: 'blue',
                                    content: (
                                        <>
                                            <Text strong>UC2.2 Report Generated</Text>
                                            <p style={{ fontSize: 12, color: 'gray' }}>Weekly POI analysis exported to PDF</p>
                                        </>
                                    ),
                                },
                                {
                                    color: 'gold',
                                    content: (
                                        <>
                                            <Text strong>Maintenance Warning</Text>
                                            <p style={{ fontSize: 12, color: 'gray' }}>Database optimization scheduled for 02:00 AM</p>
                                        </>
                                    ),
                                },
                                {
                                    color: 'red',
                                    content: 'Critical: AI Service Outage Detected',
                                },
                            ]}
                        />
                    </Card>
                </Col>
            </Row>
        </motion.div>
    );
}
