import React from "react";
import { Row, Col, Card, Typography, Tag, Space, Spin, Badge, Progress } from "antd";
import { LineChart, Line, XAxis, YAxis, CartesianGrid, ResponsiveContainer, Tooltip } from "recharts";
import { LoadingOutlined, CloudServerOutlined, BugFilled, CheckCircleFilled, WarningFilled } from "@ant-design/icons";
import useFetch from "../hooks/useFetch";
import { motion } from "framer-motion";
import dayjs from "dayjs";

const { Title, Text } = Typography;

const THEME = {
    navy: '#1A2332',
    coral: '#FF6B6B',
    teal: '#00B4D8',
    green: '#2DD4A8',
    amber: '#FFB347',
    subtext: '#5A6B7A'
};

const Monitoring = () => {
    const { data, loading } = useFetch('/admin/monitoring');

    if (loading && !data) return (
        <div style={{ height: '80vh', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
            <Spin indicator={<LoadingOutlined style={{ fontSize: 48, color: THEME.coral }} spin />} />
        </div>
    );

    return (
        <div className="dashboard-container">
            <Row gutter={[48, 48]}>
                <Col span={24}>
                    <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }}>
                        <Title level={4} style={{ color: THEME.coral, marginBottom: 8, letterSpacing: 2, textTransform: 'uppercase', fontSize: 13, fontWeight: 700 }}>
                            INFRASTRUCTURE OVERWATCH
                        </Title>
                        <Title className="gradient-text" style={{ fontSize: '56px', margin: '0 0 16px 0', lineHeight: 1.1, letterSpacing: '-1.5px' }}>
                            System Matrix
                        </Title>
                        <Text style={{ fontSize: '18px', color: THEME.subtext, fontWeight: 500 }}>Global telemetry, service node health, and live execution tracing.</Text>
                    </motion.div>
                </Col>

                <Col xs={24} lg={16}>
                    <Card className="glass-card" bordered={false} title={<span style={{ fontSize: 24 }}>API Performance Index</span>}>
                        <div style={{ height: 350, width: '100%', marginTop: 24 }}>
                            <ResponsiveContainer>
                                <LineChart data={data?.apiMetrics || []}>
                                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="rgba(26, 35, 50, 0.05)" />
                                    <XAxis dataKey="apiName" hide />
                                    <YAxis axisLine={false} tickLine={false} tick={{ fill: THEME.subtext, fontSize: 12, fontWeight: 600 }} />
                                    <Tooltip
                                        labelStyle={{ color: THEME.navy, fontWeight: 700 }}
                                        contentStyle={{ borderRadius: '16px', border: 'none', boxShadow: '0 20px 50px rgba(0,0,0,0.1)', padding: '16px' }}
                                    />
                                    <Line name="Avg Response (ms)" type="monotone" dataKey="avgResponseMs" stroke={THEME.coral} strokeWidth={4} dot={false} activeDot={{ r: 8, fill: THEME.coral, stroke: 'white', strokeWidth: 3 }} />
                                    <Line name="Total Calls" type="monotone" dataKey="totalCalls" stroke={THEME.teal} strokeWidth={2} dot={false} strokeDasharray="5 5" />
                                </LineChart>
                            </ResponsiveContainer>
                        </div>
                    </Card>

                    <Card className="glass-card" bordered={false} title={<span style={{ fontSize: 24 }}>Service Node Topography</span>} style={{ marginTop: 48 }}>
                        <Row gutter={[24, 24]}>
                            {(data?.services || []).map((service, idx) => (
                                <Col xs={24} sm={12} key={idx}>
                                    <div style={{
                                        padding: '28px',
                                        background: 'rgba(26, 35, 50, 0.03)',
                                        borderRadius: '24px',
                                        border: '1px solid rgba(26, 35, 50, 0.06)',
                                        display: 'flex',
                                        flexDirection: 'column',
                                        gap: 16
                                    }}>
                                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                            <Space size={12}>
                                                <CloudServerOutlined style={{ fontSize: 22, color: THEME.navy }} />
                                                <Text strong style={{ fontSize: 17, color: THEME.navy }}>{service.name}</Text>
                                            </Space>
                                            <Tag color={service.status === 'UP' ? 'success' : 'error'} bordered={false} style={{ borderRadius: 8, fontWeight: 800 }}>{service.status}</Tag>
                                        </div>

                                    </div>
                                </Col>
                            ))}
                        </Row>
                    </Card>
                </Col>

                <Col xs={24} lg={8}>
                    <Card className="glass-card" bordered={false} title={<span style={{ fontSize: 24 }}>System Telemetry</span>}>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: 32 }}>
                            <div style={{ padding: '32px', background: 'rgba(26, 35, 50, 0.04)', borderRadius: '24px' }}>
                                <Text style={{ fontSize: 12, color: THEME.subtext, textTransform: 'uppercase', letterSpacing: 1.5, fontWeight: 700, display: 'block', marginBottom: 12 }}>Infrastructure Health</Text>
                                <Title level={1} style={{ margin: '0 0 12px 0', color: THEME.navy, fontWeight: 800, fontSize: 48 }}>{Math.round((data?.systemHealth || 0) * 100)}%</Title>
                                <Progress percent={Math.round((data?.systemHealth || 0) * 100)} strokeColor={THEME.green} status="active" strokeWidth={12} />
                            </div>

                            <div style={{ padding: '32px', background: `${THEME.navy}`, borderRadius: '24px', color: 'white' }}>
                                <Text style={{ fontSize: 12, color: 'rgba(255,255,255,0.4)', textTransform: 'uppercase', letterSpacing: 1.5, fontWeight: 700, display: 'block', marginBottom: 12 }}>Metric Density</Text>
                                <div style={{ display: 'flex', alignItems: 'flex-end', gap: 12 }}>
                                    <Title level={1} style={{ margin: 0, color: 'white', fontWeight: 800, fontSize: 48 }}>{data?.apiMetrics?.length || 0}</Title>
                                    <Text style={{ color: THEME.green, fontWeight: 800, paddingBottom: 10 }}>ACTIVE STREAMS</Text>
                                </div>
                            </div>
                        </div>

                        <div style={{
                            marginTop: 48,
                            background: '#06080b',
                            borderRadius: '32px',
                            padding: '32px',
                            minHeight: 450,
                            boxShadow: '0 30px 60px rgba(0,0,0,0.4)',
                            border: '1px solid rgba(255,255,255,0.05)'
                        }}>
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
                                <div style={{ display: 'flex', gap: 8 }}>
                                    <div style={{ width: 12, height: 12, borderRadius: '50%', background: '#ff5f56' }} />
                                    <div style={{ width: 12, height: 12, borderRadius: '50%', background: '#ffbd2e' }} />
                                    <div style={{ width: 12, height: 12, borderRadius: '50%', background: '#27c93f' }} />
                                </div>
                                <Tag bordered={false} style={{ margin: 0, background: 'rgba(45, 212, 168, 0.1)', color: THEME.green, fontWeight: 800, fontSize: 10 }}>LIVE_TRACE</Tag>
                            </div>
                            <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
                                {(data?.logs || []).map((log, idx) => (
                                    <div key={idx} style={{ fontFamily: 'var(--font-mono)', fontSize: '11px', lineHeight: 1.6, display: 'flex' }}>
                                        <span style={{ color: THEME.green, opacity: 0.8, whiteSpace: 'nowrap' }}>[{dayjs(log.timestamp).format('HH:mm:ss')}]</span>
                                        <span style={{
                                            color: log.level === 'ERROR' ? THEME.coral : log.level === 'WARN' ? THEME.amber : '#5A6B7A',
                                            marginLeft: 12,
                                            fontWeight: 800,
                                            minWidth: 50
                                        }}>{log.level}</span>
                                        <span style={{ color: '#e2e8f0', marginLeft: 12 }}>{log.message}</span>
                                    </div>
                                ))}
                            </div>
                        </div>
                    </Card>
                </Col>
            </Row>
        </div>
    );
};

export default Monitoring;
