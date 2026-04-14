import React, { useState, useEffect, useCallback } from "react";
import {
    Card, Row, Col, Statistic, Table, Button, Space, Progress, DatePicker, Select, Typography, Badge, Tabs, Tag, message, Spin, Empty
} from "antd";
import {
    DownloadOutlined,
    ArrowUpOutlined,
    ArrowDownOutlined,
    TeamOutlined,
    EnvironmentOutlined,
    CalendarOutlined,
    FileSearchOutlined,
    LoadingOutlined,
    PieChartOutlined,
    BarChartOutlined,
    RiseOutlined
} from "@ant-design/icons";
import {
    BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend
} from 'recharts';
import { motion } from "framer-motion";
import dayjs from "dayjs";
import http from "../api/http";

const { Title, Text } = Typography;
const { RangePicker } = DatePicker;

const THEME = {
    primary: '#FF6B6B',
    success: '#2DD4A8',
    warning: '#FFB347',
    error: '#FF4D4F',
    info: '#00B4D8',
    purple: '#1A2332'
};

const CHART_COLORS = [THEME.primary, THEME.success, THEME.warning, THEME.info, THEME.purple, '#FF8042'];

export default function Analytics() {
    const [loading, setLoading] = useState(false);
    const [data, setData] = useState(null);
    const [dates, setDates] = useState([dayjs().subtract(30, 'day'), dayjs()]);

    const fetchAnalytics = useCallback(async (silent = false) => {
        if (!dates || !dates[0] || !dates[1]) {
            if (!silent) message.warning("Select calculation window.");
            return;
        }

        setLoading(true);
        try {
            const startDate = dates[0].format('YYYY-MM-DD');
            const endDate = dates[1].format('YYYY-MM-DD');
            const response = await http.get(`/admin/analytics?startDate=${startDate}&endDate=${endDate}`);
            const result = response.data?.data || response.data;
            setData(result);
            if (!silent) message.success("Matrix recalculated.");
        } catch (err) {
            console.error("Analytics fetch error:", err);
            if (!silent) message.error("Failed to sync analytics engine.");
        } finally {
            setLoading(false);
        }
    }, [dates]);

    useEffect(() => {
        fetchAnalytics(true);
    }, []);

    const columns = [
        {
            title: "Performance Asset",
            dataIndex: "name",
            key: "name",
            render: (text) => <Text strong style={{ fontSize: 14 }}>{text}</Text>
        },
        {
            title: "Category",
            dataIndex: "category",
            key: "category",
            render: (cat) => <Tag color="blue">{cat || 'GENERAL'}</Tag>
        },
        {
            title: "IQ Score",
            dataIndex: "score",
            key: "score",
            render: (score) => (
                <Space>
                    <Progress percent={(score || 0) * 10} size="small" showInfo={false} strokeColor={THEME.success} style={{ width: 50 }} />
                    <Text strong>{score || 0}</Text>
                </Space>
            )
        },
    ];

    if (loading && !data) return (
        <div style={{ height: '80vh', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
            <Spin size="large" indicator={<LoadingOutlined style={{ fontSize: 40, color: THEME.primary }} spin />} />
        </div>
    );

    return (
        <div className="dashboard-container">
            {/* Action Header */}
            <motion.div
                initial={{ opacity: 0, y: -20 }}
                animate={{ opacity: 1, y: 0 }}
                style={{ display: "flex", justifyContent: "space-between", marginBottom: "32px", alignItems: 'flex-start', flexWrap: 'wrap', gap: 16 }}
            >
                <div>
                    <Title level={2} style={{ margin: 0, letterSpacing: -0.8 }}>Administrative Insights</Title>
                    <Text type="secondary">Deep-dive performance analytics and user behavior patterns</Text>
                </div>
                <Space direction="vertical" align="end">
                    <div className="glass-card" style={{ padding: '8px', borderRadius: '14px', display: 'flex', gap: '8px' }}>
                        <RangePicker
                            value={dates}
                            onChange={(val) => setDates(val)}
                            allowClear={false}
                            bordered={false}
                            style={{ background: 'transparent' }}
                        />
                        <Button
                            type="primary"
                            icon={<RiseOutlined />}
                            onClick={() => fetchAnalytics()}
                            loading={loading}
                            style={{ borderRadius: '8px', background: THEME.primary, border: 'none' }}
                        >
                            Sync Report
                        </Button>
                    </div>
                    <Space size={4}>
                        <div className="status-pulse-up" style={{ width: 6, height: 6 }} />
                        <Text type="secondary" style={{ fontSize: 11 }}>Schedule: Bi-Weekly Reset Engine Active</Text>
                    </Space>
                </Space>
            </motion.div>

            {/* Metrics Grid with Fallback Mapping */}
            <Row gutter={[20, 20]}>
                {[
                    { label: "Matrix Users", val: data?.matrixUsers ?? data?.totalUsers, icon: <TeamOutlined />, color: THEME.success },
                    { label: "Global Revenue", val: (data?.globalRevenue > 0 ? data?.globalRevenue : (data?.activeSessions ?? 0)), icon: <RiseOutlined />, color: THEME.primary, prefix: (data?.globalRevenue > 0) ? "$" : "" },
                    { label: "Active Nodes", val: data?.activeNodes ?? data?.activePois ?? data?.totalCheckins, icon: <EnvironmentOutlined />, color: THEME.warning },
                    { label: "Avg. Duration", val: data?.avgDuration ?? 0, icon: <CalendarOutlined />, color: THEME.purple, suffix: "h" }
                ].map((stat, i) => (
                    <Col xs={24} sm={12} xl={6} key={i}>
                        <motion.div whileHover={{ y: -5 }} transition={{ type: 'spring', stiffness: 300 }}>
                            <Card className="glass-card" bordered={false} bodyStyle={{ padding: '24px' }}>
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
                                    <div style={{ padding: 10, borderRadius: 12, background: `${stat.color}15`, color: stat.color }}>
                                        {stat.icon}
                                    </div>
                                    {stat.growth !== undefined && (
                                        <Tag color={stat.growth >= 0 ? "success" : "error"} bordered={false} style={{ borderRadius: 20 }}>
                                            {stat.growth >= 0 ? "+" : ""}{stat.growth}%
                                        </Tag>
                                    )}
                                </div>
                                <Statistic
                                    title={<Text type="secondary" style={{ fontSize: 12, textTransform: 'uppercase', letterSpacing: 1 }}>{stat.label}</Text>}
                                    value={stat.val || 0}
                                    prefix={stat.prefix}
                                    suffix={stat.suffix}
                                    valueStyle={{ fontWeight: 800, fontSize: 28, color: '#1e293b' }}
                                />
                            </Card>
                        </motion.div>
                    </Col>
                ))}
            </Row>

            {/* Visual Intelligence Section */}
            <Row gutter={[20, 20]} style={{ marginTop: "24px" }}>
                <Col xs={24} lg={16}>
                    <Card
                        title={<Space><BarChartOutlined style={{ color: THEME.primary }} /> Growth Trajectory</Space>}
                        className="glass-card"
                        bordered={false}
                    >
                        <div style={{ height: 350, width: '100%', marginTop: 20, minHeight: 350 }}>
                            {(() => {
                                const chartData = data?.growthTrends || data?.growthTrajectory;
                                if (!chartData || chartData.length === 0) return <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} />;
                                return (
                                    <ResponsiveContainer width="100%" height={350}>
                                        <BarChart data={chartData}>
                                            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="rgba(241, 245, 249, 1)" />
                                            <XAxis dataKey="period" axisLine={false} tickLine={false} style={{ fontSize: 11 }} />
                                            <YAxis axisLine={false} tickLine={false} style={{ fontSize: 11 }} />
                                            <Tooltip cursor={{ fill: 'rgba(99, 102, 241, 0.05)' }} contentStyle={{ borderRadius: 12, border: 'none', boxShadow: '0 10px 15px -3px rgba(0,0,0,0.1)' }} />
                                            <Bar dataKey="newUsers" fill={THEME.primary} radius={[6, 6, 0, 0]} barSize={32} />
                                        </BarChart>
                                    </ResponsiveContainer>
                                );
                            })()}
                        </div>
                    </Card>
                </Col>
                <Col xs={24} lg={8}>
                    <Card
                        title={<Space><PieChartOutlined style={{ color: THEME.primary }} /> Category Breakdown</Space>}
                        className="glass-card"
                        bordered={false}
                    >
                        <div style={{ height: 350, width: '100%', marginTop: 20, minHeight: 350 }}>
                            {(() => {
                                const raw = data?.categoryDistribution || data?.categoryBreakdown;
                                const pieData = Array.isArray(raw) ? raw : (raw ? Object.entries(raw).map(([name, value]) => ({ name, value })) : []);
                                if (!pieData || pieData.length === 0) return <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="No Category Data Available" />;
                                return (
                                    <ResponsiveContainer width="100%" height={350}>
                                        <PieChart>
                                            <Pie
                                                data={pieData}
                                                cx="50%"
                                                cy="50%"
                                                innerRadius={70}
                                                outerRadius={100}
                                                paddingAngle={8}
                                                dataKey="value"
                                                nameKey="name"
                                                stroke="none"
                                            >
                                                {pieData.map((_, index) => (
                                                    <Cell key={index} fill={CHART_COLORS[index % CHART_COLORS.length]} />
                                                ))}
                                            </Pie>
                                            <Tooltip />
                                            <Legend verticalAlign="bottom" style={{ fontSize: 11 }} />
                                        </PieChart>
                                    </ResponsiveContainer>
                                );
                            })()}
                        </div>
                    </Card>
                </Col>
            </Row>

            {/* Performance Ranking Table */}
            <Row style={{ marginTop: "24px" }}>
                <Col span={24}>
                    <Card
                        title={<Space><FileSearchOutlined style={{ color: THEME.primary }} /> High Performance Asset Ranking</Space>}
                        className="glass-card"
                        bordered={false}
                        styles={{ body: { padding: 0 } }}
                    >
                        <Table
                            dataSource={data?.topPois || data?.highPerformanceAssets || []}
                            columns={columns}
                            rowKey={(record) => record.id || record.name || Math.random()}
                            pagination={{ pageSize: 6, position: ['bottomCenter'] }}
                            size="large"
                            className="premium-table"
                        />
                    </Card>
                </Col>
            </Row>
        </div>
    );
}
