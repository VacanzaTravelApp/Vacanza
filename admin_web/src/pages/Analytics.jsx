import React from "react";
import { Row, Col, Card, Typography, Table, Tag, Space, Spin, Tooltip, Statistic, Progress, Grid } from "antd";
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, ResponsiveContainer, BarChart, Bar, Cell, PieChart, Pie } from "recharts";
import { UserOutlined, GlobalOutlined, RocketOutlined, DollarOutlined, LoadingOutlined, RiseOutlined } from "@ant-design/icons";
import useFetch from "../hooks/useFetch";
import { motion } from "framer-motion";

const { Title, Text } = Typography;
const { useBreakpoint } = Grid;

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

const CustomTooltip = ({ active, payload, label }) => {
    if (active && payload && payload.length) {
        return (
            <div style={{ background: 'white', padding: '16px', borderRadius: '16px', boxShadow: '0 20px 50px rgba(0,0,0,0.15)', zIndex: 9999, position: 'relative' }}>
                <p style={{ margin: 0, color: THEME.subtext, fontSize: 12, fontWeight: 600, marginBottom: 8, textTransform: 'uppercase', letterSpacing: 1 }}>{label}</p>
                <p style={{ margin: 0, color: THEME.navy, fontSize: 24, fontWeight: 900 }}>
                    <span style={{ color: THEME.coral }}>{payload[0].value}</span> <span style={{ fontSize: 13, color: THEME.subtext }}>Users Joined</span>
                </p>
            </div>
        );
    }
    return null;
};

const Analytics = () => {
    const screens = useBreakpoint();
    const isMobile = !screens.md;
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
        <div className="dashboard-container" style={{ padding: isMobile ? '0' : '0 24px 24px', overflowX: 'hidden' }}>
            <Row gutter={[24, 24]}>
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
                            Track new user registrations and monitor the total growth of the Vacanza platform over time.
                        </Text>
                    </motion.div>
                </Col>

                <Col span={24}>
                    <Card className="glass-card dashboard-section-card" variant="borderless" styles={{ body: { background: THEME.navy, borderRadius: '24px', padding: isMobile ? '20px' : '20px 32px' } }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 24 }}>
                            <div>
                                <Text style={{ color: 'rgba(255,255,255,0.5)', fontSize: 11, textTransform: 'uppercase', letterSpacing: 1.5, fontWeight: 700, display: 'block', marginBottom: 4 }}>Total Registered Users</Text>
                                <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                                    <UserOutlined style={{ color: THEME.coral, fontSize: 24 }} />
                                    <span style={{ color: 'white', fontWeight: 900, fontSize: 36, lineHeight: 1 }}>{data?.matrixUsers || 0}</span>
                                </div>
                            </div>
                            <Tag color={THEME.coral} variant="filled" style={{ borderRadius: 6, fontWeight: 800, padding: '4px 16px', fontSize: 11 }}>PLATFORM TOTAL</Tag>
                        </div>
                    </Card>
                </Col>

                <Col span={24}>
                    <Card className="glass-card dashboard-section-card" variant="borderless" title={<span style={{ fontSize: 20 }}>User Growth Trend</span>}>
                        <div className="responsive-chart" style={{ height: isMobile ? 240 : 320, width: '100%', marginTop: 16 }}>
                            <ResponsiveContainer>
                                <AreaChart data={data?.growthTrajectory || []} margin={{ top: 10, right: 30, left: 0, bottom: 0 }}>
                                    <defs>
                                        <linearGradient id="colorValue" x1="0" y1="0" x2="0" y2="1">
                                            <stop offset="5%" stopColor={THEME.coral} stopOpacity={0.2} />
                                            <stop offset="95%" stopColor={THEME.coral} stopOpacity={0} />
                                        </linearGradient>
                                    </defs>
                                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="rgba(26, 35, 50, 0.05)" />
                                    <XAxis dataKey="period" axisLine={false} tickLine={false} tick={{ fill: THEME.subtext, fontSize: 12, fontWeight: 600 }} />
                                    <YAxis axisLine={false} tickLine={false} tick={{ fill: THEME.subtext, fontSize: 12, fontWeight: 600 }} />
                                    <Tooltip content={(props) => <CustomTooltip {...props} />} cursor={{ stroke: 'rgba(26, 35, 50, 0.1)', strokeWidth: 2, strokeDasharray: '4 4' }} />
                                    <Area
                                        type="monotone"
                                        dataKey="newUsers"
                                        name="New Users"
                                        stroke={THEME.coral}
                                        strokeWidth={4}
                                        fillOpacity={1}
                                        fill="url(#colorValue)"
                                        activeDot={{ r: 8, fill: THEME.coral, stroke: '#fff', strokeWidth: 3, style: { filter: 'drop-shadow(0px 4px 6px rgba(255, 107, 107, 0.4))' } }}
                                    />
                                </AreaChart>
                            </ResponsiveContainer>
                        </div>
                    </Card>
                </Col>
            </Row>
        </div >
    );
};

export default Analytics;
