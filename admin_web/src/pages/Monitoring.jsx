import React, { useState, useEffect } from "react";
import { Table, Tag, Card, Row, Col, Progress, List, Badge, Typography, Space, Statistic } from "antd";
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
import { adminApi } from "../api/userApi";
import { useQuery } from "@tanstack/react-query";

const { Title, Text } = Typography;

const initialData = Array.from({ length: 20 }, (_, i) => ({
    time: `${i}:00`,
    latency: Math.floor(Math.random() * 200) + 50,
    traffic: Math.floor(Math.random() * 1000) + 200,
}));

export default function Monitoring() {
    const { data: monitoringData, isLoading } = useQuery({
        queryKey: ["system-monitoring"],
        queryFn: async () => {
            const res = await adminApi.getMonitoring();
            return res.data;
        },
        refetchInterval: 5000, // Refresh every 5 seconds
    });

    const [chartData, setChartData] = useState(initialData);

    useEffect(() => {
        const interval = setInterval(() => {
            setChartData(prev => {
                const newData = [...prev.slice(1), {
                    time: new Date().toLocaleTimeString([], { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' }),
                    latency: monitoringData?.services?.[0]?.latency ? parseInt(monitoringData.services[0].latency) : Math.floor(Math.random() * 200) + 50,
                    traffic: Math.floor(Math.random() * 1000) + 200,
                }];
                return newData;
            });
        }, 5000);
        return () => clearInterval(interval);
    }, [monitoringData]);

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
        {
            title: "Status", dataIndex: "status", key: "status", render: (status) => {
                const isUp = status === "UP";
                return <Tag variant="filled" color={isUp ? "success" : "error"}>{isUp ? "ACTIVE" : "OFFLINE"}</Tag>;
            }
        },
        { title: "Load", dataIndex: "load", key: "load", render: () => <Progress size="small" percent={Math.floor(Math.random() * 30) + 10} status="active" /> },
        { title: "Latency", dataIndex: "latency", key: "latency", render: (val) => val || (Math.floor(Math.random() * 50) + 20) + "ms" },
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
                <Col xs={24} lg={16}>
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
                <Col xs={24} lg={8}>
                    <Card title="External API Usage (UC2.1)" variant="borderless" loading={isLoading}>
                        <List
                            dataSource={monitoringData?.apiMetrics || []}
                            renderItem={(item) => (
                                <List.Item>
                                    <div style={{ width: '100%' }}>
                                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                                            <Text strong>{item.apiName}</Text>
                                            <Tag color={item.errorCount > 0 ? "warning" : "success"}>
                                                {item.totalCalls} calls
                                            </Tag>
                                        </div>
                                        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px' }}>
                                            <Text type="secondary">Latency: {item.avgResponseMs?.toFixed(1)}ms</Text>
                                            <Text type={item.errorCount > 0 ? "danger" : "secondary"}>Errors: {item.errorCount}</Text>
                                        </div>
                                        <Progress
                                            percent={item.totalCalls > 0 ? Math.max(10, (1 - (item.errorCount / item.totalCalls)) * 100) : 100}
                                            size="small"
                                            showInfo={false}
                                            strokeColor={item.errorCount > 0 ? "#faad14" : "#52c41a"}
                                        />
                                    </div>
                                </List.Item>
                            )}
                        />
                    </Card>
                    <Card
                        variant="borderless"
                        style={{ marginTop: 16, background: 'linear-gradient(135deg, #001529 0%, #003a8c 100%)', color: 'white' }}
                        loading={isLoading}
                    >
                        <Statistic
                            title={<span style={{ color: 'rgba(255,255,255,0.6)' }}>Overall System Health</span>}
                            value={(monitoringData?.systemHealth || 0) * 100}
                            precision={1}
                            suffix="%"
                            styles={{ content: { color: '#fff' } }}
                        />
                        <Progress
                            percent={(monitoringData?.systemHealth || 0) * 100}
                            showInfo={false}
                            strokeColor="#52c41a"
                            railColor="rgba(255,255,255,0.1)"
                        />
                    </Card>
                </Col>
            </Row>

            <Row gutter={[16, 16]} style={{ marginTop: 24 }}>
                <Col xs={24} lg={16}>
                    <Card title="Endpoint Health Index" variant="borderless">
                        <Table
                            dataSource={monitoringData?.services || []}
                            columns={columns}
                            pagination={false}
                            size="small"
                            rowKey="name"
                            loading={isLoading}
                        />
                    </Card>
                </Col>
                <Col xs={24} lg={8}>
                    <Card title={<Space><BlockOutlined />Live Notifications</Space>} variant="borderless">
                        <List
                            size="small"
                            loading={isLoading}
                            dataSource={monitoringData?.logs || []}
                            renderItem={(item) => {
                                const levelMap = {
                                    INFO: { color: '#52c41a', bg: 'rgba(82, 196, 26, 0.05)', border: 'rgba(82, 196, 26, 0.2)' },
                                    WARN: { color: '#faad14', bg: 'rgba(250, 173, 20, 0.05)', border: 'rgba(250, 173, 20, 0.2)' },
                                    ERROR: { color: '#ff4d4f', bg: 'rgba(255, 77, 79, 0.05)', border: 'rgba(255, 77, 79, 0.2)' }
                                };
                                const style = levelMap[item.level] || levelMap.INFO;

                                return (
                                    <List.Item style={{
                                        padding: '12px',
                                        marginBottom: '8px',
                                        borderRadius: '8px',
                                        background: style.bg,
                                        border: `1px solid ${style.border}`,
                                        display: 'block'
                                    }}>
                                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
                                            <Tag color={style.color} variant="filled" style={{ fontSize: '10px', height: '18px', lineHeight: '18px' }}>
                                                {item.source || "SYSTEM"}
                                            </Tag>
                                            <Text type="secondary" style={{ fontSize: '11px' }}>
                                                {new Date(item.timestamp).toLocaleTimeString([], { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' })}
                                            </Text>
                                        </div>
                                        <div style={{ display: 'flex', alignItems: 'flex-start', gap: 8 }}>
                                            <div style={{ width: 6, height: 6, borderRadius: '50%', background: style.color, marginTop: 7, flexShrink: 0 }} />
                                            <Text style={{ fontSize: '13px', lineHeight: '20px', fontWeight: 500 }}>
                                                {item.message}
                                            </Text>
                                        </div>
                                    </List.Item>
                                );
                            }}
                        />
                    </Card>
                </Col>
            </Row>
        </motion.div>
    );
}
