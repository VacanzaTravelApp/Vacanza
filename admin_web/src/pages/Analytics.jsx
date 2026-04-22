import React from "react";
import { Row, Col, Card, Typography, Table, Tag, Space, Spin, Tooltip, Statistic, Progress } from "antd";
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, ResponsiveContainer, BarChart, Bar, Cell, PieChart, Pie } from "recharts";
import { UserOutlined, GlobalOutlined, RocketOutlined, DollarOutlined, LoadingOutlined, RiseOutlined } from "@ant-design/icons";
import useFetch from "../hooks/useFetch";
import { motion } from "framer-motion";

const { Title, Text } = Typography;

const THEME = {
    primary: '#FF6B6B',
    coral: '#FF6B6B',
    success: '#2DD4A8',
    warning: '#FFB347',
    error: '#FF4D4F',
    info: '#00B4D8',
    purple: '#1A2332',
    navy: '#1A2332',
    teal: '#00B4D8',
    subtext: '#5A6B7A'
};

const Analytics = () => {
    const { data, loading } = useFetch('/admin/analytics');

    if (loading && !data) return (
        <div style={{ height: '80vh', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
            <Spin indicator={<LoadingOutlined style={{ fontSize: 48, color: THEME.coral }} spin />} description="Collecting Market Intelligence" />
        </div>
    );

    const assetColumns = [
        {
            title: 'RANK',
            key: 'rank',
            width: 80,
            render: (_, __, index) => <Text style={{ fontWeight: 800, color: THEME.navy }}>#{index + 1}</Text>
        },
        {
            title: 'ASSET NAME',
            dataIndex: 'name',
            key: 'name',
            render: (n) => <Text strong style={{ color: THEME.navy, fontSize: 16 }}>{n}</Text>
        },
        {
            title: 'CATEGORY',
            dataIndex: 'category',
            key: 'category',
            render: (c) => <Tag color={THEME.navy} variant="filled" style={{ textTransform: 'uppercase', fontWeight: 800, fontSize: 10, borderRadius: 6 }}>{c}</Tag>
        },
        {
            title: 'PERFORMANCE SCORE',
            dataIndex: 'score',
            key: 'score',
            render: (s) => (
                <Space size={12}>
                    <Text strong style={{ color: THEME.coral, fontSize: 16 }}>{s || 0}</Text>
                    <RiseOutlined style={{ color: THEME.green }} />
                </Space>
            )
        }
    ];

    return (
        <div className="dashboard-container">
            <Row gutter={[48, 48]}>
                <Col span={24}>
                    <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }}>
                        <Title
                            className="gradient-text"
                            style={{
                                fontSize: '32px',
                                marginBottom: 8,
                                marginTop: 0,
                                letterSpacing: '-1.2px',
                                fontFamily: "'Fraunces', serif",
                                fontWeight: 900
                            }}
                        >
                            Analytics Core
                        </Title>
                        <Text
                            style={{
                                fontSize: '16px',
                                color: THEME.subtext,
                                fontWeight: 500,
                                fontFamily: "'DM Sans', sans-serif",
                                display: 'block',
                                maxWidth: '700px',
                                lineHeight: '1.5'
                            }}
                        >
                            Real-time data synchronization and growth trajectory monitoring across the global Vacanza infrastructure.
                        </Text>
                    </motion.div>
                </Col>

                <Col xs={24} lg={16}>
                    <Card className="glass-card" bordered={false} title={<span style={{ fontSize: 20 }}>User Growth Trend</span>}>
                        <div style={{ height: 400, width: '100%', marginTop: 24 }}>
                            <ResponsiveContainer>
                                <AreaChart data={data?.growthTrajectory || []}>
                                    <defs>
                                        <linearGradient id="colorValue" x1="0" y1="0" x2="0" y2="1">
                                            <stop offset="5%" stopColor={THEME.coral} stopOpacity={0.2} />
                                            <stop offset="95%" stopColor={THEME.coral} stopOpacity={0} />
                                        </linearGradient>
                                    </defs>
                                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="rgba(26, 35, 50, 0.05)" />
                                    <XAxis dataKey="period" axisLine={false} tickLine={false} tick={{ fill: THEME.subtext, fontSize: 12, fontWeight: 600 }} />
                                    <YAxis axisLine={false} tickLine={false} tick={{ fill: THEME.subtext, fontSize: 12, fontWeight: 600 }} />
                                    <Tooltip
                                        labelStyle={{ color: THEME.navy, fontWeight: 700 }}
                                        contentStyle={{ borderRadius: '16px', border: 'none', boxShadow: '0 20px 50px rgba(0,0,0,0.1)', padding: '16px' }}
                                    />
                                    <Area type="monotone" dataKey="newUsers" name="New Users" stroke={THEME.coral} strokeWidth={4} fillOpacity={1} fill="url(#colorValue)" />
                                </AreaChart>
                            </ResponsiveContainer>
                        </div>
                    </Card>
                </Col>

                <Col xs={24} lg={8}>
                    <Row gutter={[0, 48]}>
                        <Col span={24}>
                            <Card className="glass-card" variant="borderless" style={{ background: THEME.navy }}>
                                <Statistic
                                    title={<Text style={{ color: 'rgba(255,255,255,0.4)', fontSize: 12, textTransform: 'uppercase', letterSpacing: 1.5, fontWeight: 700 }}>Total Registered Users</Text>}
                                    value={data?.matrixUsers || 0}
                                    prefix={<UserOutlined style={{ color: THEME.coral }} />}
                                    valueStyle={{ color: 'white', fontWeight: 800, fontSize: 48 }}
                                />
                                <div style={{ marginTop: 16 }}>
                                    <Tag color={THEME.coral} variant="filled" style={{ borderRadius: 8, fontWeight: 800 }}>PLATFORM TOTAL</Tag>
                                </div>
                            </Card>
                        </Col>
                        <Col span={24}>
                            <Card className="glass-card" variant="borderless">
                                <Statistic
                                    title={<Text style={{ color: THEME.subtext, fontSize: 12, textTransform: 'uppercase', letterSpacing: 1.5, fontWeight: 700 }}>Global Traffic Volume</Text>}
                                    value={data?.activeNodes || 0}
                                    prefix={<GlobalOutlined style={{ color: THEME.teal }} />}
                                    valueStyle={{ color: THEME.navy, fontWeight: 800, fontSize: 48 }}
                                />
                                <div style={{ marginTop: 24, padding: '16px', background: 'rgba(26, 35, 50, 0.03)', borderRadius: '12px' }}>
                                    <Text style={{ fontSize: 11, color: THEME.subtext, fontWeight: 700, display: 'block', marginBottom: 4, textTransform: 'uppercase', letterSpacing: 1 }}>Avg. Planning Session</Text>
                                    <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
                                        <Title level={3} style={{ margin: 0, fontWeight: 900, color: THEME.navy }}>{data?.avgDuration || 0}h</Title>
                                        <Text style={{ fontSize: 12, color: THEME.subtext, fontWeight: 500 }}>per researcher</Text>
                                    </div>
                                    <Text type="secondary" style={{ fontSize: 10, display: 'block', marginTop: 8 }}>Time spent by users building travel itineraries.</Text>
                                </div>
                            </Card>
                        </Col>
                    </Row>
                </Col>
            </Row>
        </div>
    );
};

export default Analytics;
