import React, { useState, useEffect } from "react";
import { Table, Tag, Card, Row, Col, Progress, List, Badge, Typography, Space } from "antd";
import {
    CheckCircleFilled,
    CloseCircleFilled,
    LoadingOutlined,
    ThunderboltOutlined,
    BlockOutlined,
    CloudServerOutlined,
    ApiOutlined
} from "@ant-design/icons";
import {
    LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, AreaChart, Area
} from 'recharts';
import { motion } from "framer-motion";

const { Title, Text } = Typography;

const initialData = Array.from({ length: 20 }, (_, i) => ({
    time: `${i}:00`,
    latency: Math.floor(Math.random() * 200) + 50,
    traffic: Math.floor(Math.random() * 1000) + 200,
}));

const apiEndpoints = [
    { name: "Auth Service", path: "/auth/me", status: "Active", latency: "45ms", load: 24 },
    { name: "Gamification Engine", path: "/gamification/stats", status: "Active", latency: "120ms", load: 56 },
    { name: "POI / Maps API", path: "/pois/nearby", status: "Active", latency: "85ms", load: 12 },
    { name: "User Service", path: "/users/me/profile", status: "Active", latency: "30ms", load: 5 },
    { name: "Booking System", path: "/bookings/search", status: "Warning", latency: "450ms", load: 89 },
    { name: "AI Recommendation API", path: "/chat/ai", status: "Offline", latency: "-", load: 0 },
];

export default function Monitoring() {
    const [chartData, setChartData] = useState(initialData);

    useEffect(() => {
        const interval = setInterval(() => {
            setChartData(prev => {
                const newData = [...prev.slice(1), {
                    time: new Date().toLocaleTimeString([], { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' }),
                    latency: Math.floor(Math.random() * 200) + 50,
                    traffic: Math.floor(Math.random() * 1000) + 200,
                }];
                return newData;
            });
        }, 3000);
        return () => clearInterval(interval);
    }, []);

    const columns = [
        {
            title: "Service Name",
            dataIndex: "name",
            key: "name",
            render: (text) => (
                <Space>
                    <ApiOutlined style={{ color: '#1677ff' }} />
                    <strong>{text}</strong>
                </Space>
            )
        },
        { title: "Endpoint", dataIndex: "path", key: "path", render: (text) => <code style={{ fontSize: '12px' }}>{text}</code> },
        {
            title: "Status",
            dataIndex: "status",
            key: "status",
            render: (status) => {
                let color = status === "Active" ? "success" : status === "Warning" ? "warning" : "error";
                return <Tag bordered={false} color={color}>{status.toUpperCase()}</Tag>;
            },
        },
        {
            title: "Current Load",
            dataIndex: "load",
            key: "load",
            render: (load) => <Progress size="small" percent={load} status={load > 80 ? "exception" : "active"} />
        },
        { title: "Latency", dataIndex: "latency", key: "latency" },
    ];

    return (
        <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            style={{ padding: "12px" }}
        >
            <div style={{ marginBottom: 24, display: 'flex', alignItems: 'center', gap: 12 }}>
                <ThunderboltOutlined style={{ fontSize: 32, color: '#faad14' }} />
                <Title level={2} style={{ margin: 0 }}>Monitor System & API Status (UC2.1)</Title>
            </div>

            <Row gutter={[16, 16]}>
                <Col span={16}>
                    <Card title="Traffic & Latency (Real-time)" variant="borderless" className="dashboard-card">
                        <div style={{ height: 350 }}>
                            <ResponsiveContainer width="100%" height="100%">
                                <AreaChart data={chartData}>
                                    <defs>
                                        <linearGradient id="colorLatency" x1="0" y1="0" x2="0" y2="1">
                                            <stop offset="5%" stopColor="#1677ff" stopOpacity={0.1} />
                                            <stop offset="95%" stopColor="#1677ff" stopOpacity={0} />
                                        </linearGradient>
                                    </defs>
                                    <CartesianGrid strokeDasharray="3 3" vertical={false} />
                                    <XAxis dataKey="time" hide />
                                    <YAxis axisLine={false} tickLine={false} />
                                    <Tooltip />
                                    <Area type="monotone" dataKey="latency" stroke="#1677ff" fillOpacity={1} fill="url(#colorLatency)" strokeWidth={2} />
                                    <Area type="monotone" dataKey="traffic" stroke="#52c41a" fillOpacity={0} />
                                </AreaChart>
                            </ResponsiveContainer>
                        </div>
                    </Card>
                </Col>
                <Col span={8}>
                    <Row gutter={[0, 16]}>
                        <Col span={24}>
                            <Card title="Database Performance" variant="borderless">
                                <Space direction="vertical" style={{ width: '100%' }}>
                                    <Text>Read/Write Ratio</Text>
                                    <Progress percent={72} strokeColor="#52c41a" />
                                    <Text>Connection Pool Usage</Text>
                                    <Progress percent={45} status="active" />
                                    <Text>Cache Hit Rate</Text>
                                    <Progress percent={94} strokeColor="#13c2c2" />
                                </Space>
                            </Card>
                        </Col>
                        <Col span={24}>
                            <Card variant="borderless" style={{ background: '#001529', color: 'white' }}>
                                <Statistic
                                    title={<span style={{ color: 'rgba(255,255,255,0.6)' }}>Storage Used</span>}
                                    value={4.2}
                                    suffix="TB"
                                    styles={{ content: { color: '#fff' } }}
                                />
                                <Progress percent={64} showInfo={false} strokeColor="#3da8c8" />
                            </Card>
                        </Col>
                    </Row>
                </Col>
            </Row>

            <Row gutter={[16, 16]} style={{ marginTop: 24 }}>
                <Col span={16}>
                    <Card title="Endpoint Health Index" variant="borderless">
                        <Table dataSource={apiEndpoints} columns={columns} pagination={false} size="small" rowKey="name" />
                    </Card>
                </Col>
                <Col span={8}>
                    <Card title={<Space><BlockOutlined />Live Notifications</Space>} variant="borderless">
                        <List
                            size="small"
                            dataSource={[
                                { msg: "Auth session verified successfully", time: "Just now", type: "success" },
                                { msg: "Token refresh for user ID 552", time: "2 min ago", type: "info" },
                                { msg: "AI response latency spike", time: "5 min ago", type: "warning" },
                                { msg: "Database replication lagged (8s)", time: "15 min ago", type: "error" },
                            ]}
                            renderItem={(item) => (
                                <List.Item>
                                    <Badge status={item.type} />
                                    <div style={{ marginLeft: 12 }}>
                                        <Text style={{ fontSize: '13px' }}>{item.msg}</Text>
                                        <br />
                                        <Text type="secondary" style={{ fontSize: '11px' }}>{item.time}</Text>
                                    </div>
                                </List.Item>
                            )}
                        />
                    </Card>
                </Col>
            </Row>
        </motion.div>
    );
}
