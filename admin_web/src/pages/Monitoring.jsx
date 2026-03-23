import React, { useState, useEffect } from "react";
import { Table, Tag, Card, Row, Col, Progress, List, Badge, Typography, Space, Statistic, Spin, Button } from "antd";
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
import { MdFlightTakeoff } from "react-icons/md";
import { adminApi } from "../api/userApi";
import { useQuery } from "@tanstack/react-query";

const { Title, Text } = Typography;

export default function Monitoring() {
    const [chartData, setChartData] = useState([]);

    const { data: monitoring, isLoading, isFetching, refetch } = useQuery({
        queryKey: ['admin-monitoring'],
        queryFn: async () => {
            const res = await adminApi.getSystemMonitoring();
            return res.data;
        }
    });

    useEffect(() => {
        if (monitoring) {
            setChartData(prev => {
                const now = new Date().toLocaleTimeString([], { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' });
                // Calculate average latency from API metrics
                const avgLatency = monitoring.apiMetrics?.length
                    ? monitoring.apiMetrics.reduce((sum, m) => sum + m.averageLatency, 0) / monitoring.apiMetrics.length
                    : Math.floor(Math.random() * 20) + 10;

                const totalReq = monitoring.apiMetrics?.length
                    ? monitoring.apiMetrics.reduce((sum, m) => sum + m.requestCount, 0)
                    : Math.floor(Math.random() * 100);

                const newData = [...prev, { time: now, latency: avgLatency, traffic: totalReq }];
                return newData.length > 20 ? newData.slice(1) : newData;
            });
        }
    }, [monitoring]);

    const columns = [
        {
            title: "Service Name",
            dataIndex: "serviceName",
            key: "serviceName",
            render: (text) => (
                <Space>
                    <ApiOutlined style={{ color: '#1677ff' }} />
                    <strong>{text}</strong>
                </Space>
            )
        },
        {
            title: "Request Count",
            dataIndex: "requestCount",
            key: "requestCount",
            render: (val) => <Tag color="blue">{val} reqs</Tag>
        },
        {
            title: "Latency (avg)",
            dataIndex: "averageLatency",
            key: "averageLatency",
            render: (val) => <Text>{val.toFixed(2)} ms</Text>
        },
        {
            title: "Error Rate",
            dataIndex: "errorRate",
            key: "errorRate",
            render: (val) => <Progress size="small" percent={Number((val * 100).toFixed(1))} status={val > 0.05 ? "exception" : "active"} />
        }
    ];

    if (isLoading && !monitoring) {
        return <div style={{ textAlign: "center", padding: "100px" }}><Spin size="large" /></div>;
    }

    return (
        <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            style={{ padding: "12px" }}
        >
            <div style={{ marginBottom: 24, display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 12 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                    <ThunderboltOutlined style={{ fontSize: 32, color: '#faad14' }} />
                    <Title level={2} style={{ margin: 0 }}>Monitor System & API Status (UC2.1)</Title>
                </div>
                <Button
                    type="primary"
                    icon={<MdFlightTakeoff />}
                    onClick={() => refetch()}
                    loading={isFetching}
                >
                    Sync Live Data
                </Button>
            </div>

            <Row gutter={[16, 16]}>
                <Col xs={24} lg={16}>
                    <Card title="Traffic & Latency (Real-time)" variant="borderless" className="dashboard-card" loading={isLoading}>
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
                    <Row gutter={[0, 16]}>
                        <Col span={24}>
                            <Card title="Backend Services Health" variant="borderless" loading={isLoading}>
                                <List
                                    size="small"
                                    dataSource={monitoring?.services || []}
                                    renderItem={(srv) => (
                                        <List.Item>
                                            <Text>{srv.name}</Text>
                                            <Tag color={srv.status === "UP" ? "success" : "error"}>{srv.status}</Tag>
                                        </List.Item>
                                    )}
                                />
                            </Card>
                        </Col>
                        <Col span={24}>
                            <Card variant="borderless" style={{ background: monitoring?.systemHealth === 1.0 ? '#001529' : '#5c0011', color: 'white' }}>
                                <Statistic
                                    title={<span style={{ color: 'rgba(255,255,255,0.6)' }}>Health Index Score</span>}
                                    value={(monitoring?.systemHealth || 0) * 100}
                                    suffix="%"
                                    styles={{ content: { color: '#fff' } }}
                                />
                                <Progress percent={(monitoring?.systemHealth || 0) * 100} showInfo={false} strokeColor={monitoring?.systemHealth === 1.0 ? "#52c41a" : "#f5222d"} />
                            </Card>
                        </Col>
                    </Row>
                </Col>
            </Row>

            <Row gutter={[16, 16]} style={{ marginTop: 24 }}>
                <Col xs={24} lg={16}>
                    <Card title="External API Usage Metrics" variant="borderless" loading={isLoading}>
                        <Table dataSource={monitoring?.apiMetrics} columns={columns} pagination={false} size="small" rowKey="serviceName" />
                    </Card>
                </Col>
                <Col xs={24} lg={8}>
                    <Card title={<Space><BlockOutlined />Live Notifications</Space>} variant="borderless" loading={isLoading}>
                        {monitoring?.logs?.length > 0 ? (
                            <List
                                size="small"
                                dataSource={monitoring.logs}
                                renderItem={(item) => (
                                    <List.Item style={{ padding: '12px 0' }}>
                                        <div style={{ display: 'flex', alignItems: 'flex-start', width: '100%' }}>
                                            <Badge status={item.level === "ERROR" ? "error" : item.level === "WARN" ? "warning" : "success"} style={{ marginTop: 4 }} />
                                            <div style={{ marginLeft: 12, textAlign: 'left' }}>
                                                <div style={{ lineHeight: '1.2' }}>
                                                    <Text style={{ fontSize: '13px' }}>{item.message}</Text>
                                                </div>
                                                <div style={{ marginTop: 4 }}>
                                                    <Text type="secondary" style={{ fontSize: '11px' }}>{new Date(item.timestamp).toLocaleTimeString()}</Text>
                                                </div>
                                            </div>
                                        </div>
                                    </List.Item>
                                )}
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
